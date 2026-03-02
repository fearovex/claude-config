---
name: java-21
description: >
  Java 21 patterns: records, sealed types, pattern matching, virtual threads.
  Trigger: When writing Java 21 code, using records, sealed interfaces, or virtual threads for I/O.
license: Apache-2.0
metadata:
  author: diegnghrmr
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When writing Java 21 code, using records, sealed interfaces, or virtual threads for I/O.

Load when: writing Java 21 code, designing immutable value objects, modeling class hierarchies, or implementing concurrent I/O with virtual threads.

## Critical Patterns

### Pattern 1: Records for immutable data

```java
// ✅ Record with validation in compact constructor
public record UserDto(
    String id,
    String name,
    String email
) {
    // Compact constructor — automatic validation
    public UserDto {
        Objects.requireNonNull(id, "id must not be null");
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("name must not be blank");
        }
        if (!email.contains("@")) {
            throw new IllegalArgumentException("invalid email: " + email);
        }
        // Fields are assigned automatically
    }
}

// ❌ Avoid: mutable class as data carrier
public class UserDto {
    private String id;
    private String name;
    // getters/setters/equals/hashCode — verbose and unnecessary
}
```

### Pattern 2: Sealed types with pattern matching

```java
// ✅ Sealed interface — closed and exhaustive hierarchy
public sealed interface Shape
    permits Circle, Rectangle, Triangle {}

public record Circle(double radius) implements Shape {}
public record Rectangle(double width, double height) implements Shape {}
public record Triangle(double base, double height) implements Shape {}

// Pattern matching in switch — exhaustive
public double area(Shape shape) {
    return switch (shape) {
        case Circle c -> Math.PI * c.radius() * c.radius();
        case Rectangle r -> r.width() * r.height();
        case Triangle t -> 0.5 * t.base() * t.height();
        // No default needed — the compiler verifies exhaustiveness
    };
}

// ❌ Avoid: chained instanceof
if (shape instanceof Circle) { ... }
else if (shape instanceof Rectangle) { ... }
```

### Pattern 3: Virtual Threads for I/O

```java
// ✅ Virtual threads — scales without large thread pools
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    List<Future<String>> futures = urls.stream()
        .map(url -> executor.submit(() -> fetchUrl(url))) // Blocking OK
        .toList();

    for (Future<String> f : futures) {
        System.out.println(f.get());
    }
}

// ✅ Thread.ofVirtual() directly
Thread.ofVirtual()
    .name("task-", 0)
    .start(() -> processData(data));

// ❌ Avoid: platform thread per request — does not scale
new Thread(() -> handleRequest(req)).start(); // Platform thread, expensive
```

## Code Examples

### Record with wither (copy with changes)

```java
public record User(String id, String name, String email, boolean active) {

    // Manual wither — immutability with convenient changes
    public User withName(String newName) {
        return new User(id, newName, email, active);
    }

    public User withActive(boolean newActive) {
        return new User(id, name, email, newActive);
    }

    // Factory method
    public static User create(String name, String email) {
        return new User(UUID.randomUUID().toString(), name, email, true);
    }
}

// Usage
User user = User.create("Juan", "juan@example.com");
User updated = user.withName("Juan Pablo").withActive(false);
```

### Advanced pattern matching

```java
// Deconstruction patterns
public String describe(Object obj) {
    return switch (obj) {
        case Integer i when i < 0 -> "Negative: " + i;
        case Integer i when i == 0 -> "Zero";
        case Integer i -> "Positive: " + i;
        case String s when s.isEmpty() -> "Empty string";
        case String s -> "String: " + s;
        case null -> "null";
        default -> "Unknown: " + obj.getClass().getSimpleName();
    };
}

// With records
public double process(Shape shape) {
    return switch (shape) {
        case Circle c when c.radius() > 100 -> handleLargeCircle(c);
        case Circle c -> c.radius() * Math.PI * 2;
        case Rectangle r -> r.width() * r.height();
        default -> throw new UnsupportedOperationException();
    };
}
```

### Structured Concurrency (Preview in Java 21)

```java
import java.util.concurrent.StructuredTaskScope;

public record UserData(User user, List<Order> orders) {}

public UserData fetchUserData(String userId) throws Exception {
    try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
        Supplier<User> userTask = scope.fork(() -> fetchUser(userId));
        Supplier<List<Order>> ordersTask = scope.fork(() -> fetchOrders(userId));

        scope.join().throwIfFailed();

        return new UserData(userTask.get(), ordersTask.get());
    }
}
```

### Text Blocks and String Templates

```java
// ✅ Text blocks for JSON, SQL, HTML
String json = """
    {
        "name": "%s",
        "email": "%s"
    }
    """.formatted(name, email);

String sql = """
    SELECT u.id, u.name, u.email
    FROM users u
    WHERE u.active = true
      AND u.created_at > ?
    ORDER BY u.name
    """;
```

## Anti-Patterns

### ❌ Mutable data carrier

```java
// ❌ Unnecessarily mutable
public class UserDto {
    private String name;
    public void setName(String name) { this.name = name; }
    public String getName() { return name; }
    // + equals, hashCode, toString...
}

// ✅ Record — immutable, compact, auto-generates everything
public record UserDto(String name, String email) {}
```

### ❌ Platform thread per request

```java
// ❌ Does not scale — each thread consumes ~1MB of stack
for (String url : urls) {
    new Thread(() -> process(url)).start();
}

// ✅ Virtual threads — lightweight, scales to millions
try (var exec = Executors.newVirtualThreadPerTaskExecutor()) {
    urls.forEach(url -> exec.submit(() -> process(url)));
}
```

## Quick Reference

| Task | Java 21 |
|------|---------|
| Immutable DTO | `record Dto(String a, int b) {}` |
| Record validation | Compact constructor |
| Closed hierarchy | `sealed interface` + `permits` |
| Exhaustive switch | `switch` with pattern matching |
| Concurrent I/O | `Executors.newVirtualThreadPerTaskExecutor()` |
| Virtual thread | `Thread.ofVirtual().start(() -> ...)` |
| Null check | `Objects.requireNonNull(x, "msg")` |
| Multi-line string | Text block `""" ... """` |

## Rules

- Use `record` for all immutable data carriers (DTOs, value objects); mutable data classes with getters/setters are unnecessary in Java 21+
- Compact constructors in records are the required location for validation — never validate after construction
- Virtual threads are for I/O-bound concurrency only; CPU-bound tasks should still use platform thread pools
- `sealed interface` + `permits` is required for closed class hierarchies; open inheritance hierarchies with `instanceof` chains are an anti-pattern
- Pattern matching `switch` expressions must be exhaustive — rely on compiler enforcement rather than adding a catch-all `default`

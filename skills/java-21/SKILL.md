---
name: java-21
description: >
  Java 21 patterns: records, sealed types, pattern matching, virtual threads.
  Trigger: When writing Java 21 code, using records, sealed interfaces, or virtual threads for I/O.
license: Apache-2.0
metadata:
  author: diegnghrmr
  version: "1.0"
---

## When to Use

Load when: writing Java 21 code, designing immutable value objects, modeling class hierarchies, or implementing concurrent I/O with virtual threads.

## Critical Patterns

### Pattern 1: Records para datos inmutables

```java
// ✅ Record con validación en compact constructor
public record UserDto(
    String id,
    String name,
    String email
) {
    // Compact constructor — validación automática
    public UserDto {
        Objects.requireNonNull(id, "id must not be null");
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("name must not be blank");
        }
        if (!email.contains("@")) {
            throw new IllegalArgumentException("invalid email: " + email);
        }
        // Los campos se asignan automáticamente
    }
}

// ❌ Evitar: clase mutable como data carrier
public class UserDto {
    private String id;
    private String name;
    // getters/setters/equals/hashCode — verboso e innecesario
}
```

### Pattern 2: Sealed types con pattern matching

```java
// ✅ Sealed interface — jerarquía cerrada y exhaustiva
public sealed interface Shape
    permits Circle, Rectangle, Triangle {}

public record Circle(double radius) implements Shape {}
public record Rectangle(double width, double height) implements Shape {}
public record Triangle(double base, double height) implements Shape {}

// Pattern matching en switch — exhaustivo
public double area(Shape shape) {
    return switch (shape) {
        case Circle c -> Math.PI * c.radius() * c.radius();
        case Rectangle r -> r.width() * r.height();
        case Triangle t -> 0.5 * t.base() * t.height();
        // No necesita default — el compilador verifica exhaustividad
    };
}

// ❌ Evitar: instanceof encadenado
if (shape instanceof Circle) { ... }
else if (shape instanceof Rectangle) { ... }
```

### Pattern 3: Virtual Threads para I/O

```java
// ✅ Virtual threads — escala sin thread pools grandes
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    List<Future<String>> futures = urls.stream()
        .map(url -> executor.submit(() -> fetchUrl(url))) // Blocking OK
        .toList();

    for (Future<String> f : futures) {
        System.out.println(f.get());
    }
}

// ✅ Thread.ofVirtual() directo
Thread.ofVirtual()
    .name("task-", 0)
    .start(() -> processData(data));

// ❌ Evitar: plataforma thread por request — no escala
new Thread(() -> handleRequest(req)).start(); // Platform thread, costoso
```

## Code Examples

### Record con wither (copia con cambios)

```java
public record User(String id, String name, String email, boolean active) {

    // Wither manual — inmutabilidad con cambios convenientes
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

// Uso
User user = User.create("Juan", "juan@example.com");
User updated = user.withName("Juan Pablo").withActive(false);
```

### Pattern matching avanzado

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

// Con records
public double process(Shape shape) {
    return switch (shape) {
        case Circle c when c.radius() > 100 -> handleLargeCircle(c);
        case Circle c -> c.radius() * Math.PI * 2;
        case Rectangle r -> r.width() * r.height();
        default -> throw new UnsupportedOperationException();
    };
}
```

### Structured Concurrency (Preview en Java 21)

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

### Text Blocks y String Templates

```java
// ✅ Text blocks para JSON, SQL, HTML
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
// ❌ Innecesariamente mutable
public class UserDto {
    private String name;
    public void setName(String name) { this.name = name; }
    public String getName() { return name; }
    // + equals, hashCode, toString...
}

// ✅ Record — inmutable, compacto, auto-genera todo
public record UserDto(String name, String email) {}
```

### ❌ Platform thread por request

```java
// ❌ No escala — cada thread consume ~1MB de stack
for (String url : urls) {
    new Thread(() -> process(url)).start();
}

// ✅ Virtual threads — ligeros, escalan a millones
try (var exec = Executors.newVirtualThreadPerTaskExecutor()) {
    urls.forEach(url -> exec.submit(() -> process(url)));
}
```

## Quick Reference

| Task | Java 21 |
|------|---------|
| DTO inmutable | `record Dto(String a, int b) {}` |
| Validación en record | Compact constructor |
| Jerarquía cerrada | `sealed interface` + `permits` |
| Switch exhaustivo | `switch` con pattern matching |
| I/O concurrente | `Executors.newVirtualThreadPerTaskExecutor()` |
| Thread virtual | `Thread.ofVirtual().start(() -> ...)` |
| Null check | `Objects.requireNonNull(x, "msg")` |
| Multi-línea string | Text block `""" ... """` |

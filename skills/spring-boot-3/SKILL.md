---
name: spring-boot-3
description: >
  Spring Boot 3.3+ patterns: constructor injection, typed config properties, service-layer transactions.
  Trigger: When building Spring Boot applications, configuring beans, or implementing REST services.
license: Apache-2.0
metadata:
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When building Spring Boot applications, configuring beans, or implementing REST services.

Load when: building Spring Boot 3.3+ apps, configuring properties, implementing services, or creating REST controllers.

## Critical Patterns

### Pattern 1: ALWAYS use Constructor Injection

```java
// ✅ Constructor injection — testable, explicit, immutable
@Service
public class UserService {

    private final UserRepository userRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    // No @Autowired on constructor — Spring detects it automatically
    public UserService(
        UserRepository userRepository,
        EmailService emailService,
        PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
    }
}

// ❌ Field injection — not testable, hides dependencies
@Service
public class UserService {
    @Autowired private UserRepository userRepository; // Avoid
    @Autowired private EmailService emailService;     // Avoid
}
```

### Pattern 2: @ConfigurationProperties (not scattered @Value)

```java
// ✅ Typed configuration with validation
@ConfigurationProperties(prefix = "app")
@Validated
public record AppProperties(
    @NotBlank String name,
    @NotNull ApiProperties api,
    @NotNull SecurityProperties security
) {
    public record ApiProperties(
        @NotBlank String baseUrl,
        @Positive int timeout,
        @Positive int maxRetries
    ) {}

    public record SecurityProperties(
        @NotBlank String jwtSecret,
        @Positive long jwtExpirationMs
    ) {}
}

// application.yml
// app:
//   name: "My App"
//   api:
//     base-url: "https://api.example.com"
//     timeout: 5000
//     max-retries: 3
//   security:
//     jwt-secret: "${JWT_SECRET}"
//     jwt-expiration-ms: 86400000

// Register in @SpringBootApplication or config class
@EnableConfigurationProperties(AppProperties.class)

// ❌ Scattered @Value — hard to maintain and test
@Value("${app.api.base-url}") private String apiBaseUrl;
@Value("${app.api.timeout}") private int timeout;
```

### Pattern 3: @Transactional on services, NOT on controllers

```java
// ✅ Transaction on the service layer
@Service
public class OrderService {

    @Transactional
    public Order createOrder(CreateOrderRequest request) {
        var order = Order.from(request);
        orderRepository.save(order);
        inventoryService.reserve(order.items()); // In the same transaction
        return order;
    }

    @Transactional(readOnly = true) // Optimization for reads
    public List<Order> findByCustomer(Long customerId) {
        return orderRepository.findByCustomerId(customerId);
    }
}

// ❌ Transaction on controller — incorrect boundary
@RestController
public class OrderController {
    @Transactional // Avoid — belongs in the service
    @PostMapping("/orders")
    public ResponseEntity<Order> create(...) { ... }
}
```

## Code Examples

### REST Controller with DTOs as records

```java
@RestController
@RequestMapping("/api/v1/users")
@Validated
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getById(@PathVariable Long id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse create(@Valid @RequestBody CreateUserRequest request) {
        return userService.create(request);
    }

    @PutMapping("/{id}")
    public UserResponse update(
        @PathVariable Long id,
        @Valid @RequestBody UpdateUserRequest request
    ) {
        return userService.update(id, request);
    }
}

// DTOs as records (Java 21+)
public record CreateUserRequest(
    @NotBlank String name,
    @Email @NotBlank String email,
    @NotBlank @Size(min = 8) String password
) {}

public record UserResponse(
    Long id,
    String name,
    String email,
    LocalDateTime createdAt
) {}
```

### Complete service

```java
@Service
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AppProperties appProperties;

    public UserService(
        UserRepository userRepository,
        PasswordEncoder passwordEncoder,
        AppProperties appProperties
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.appProperties = appProperties;
    }

    public UserResponse create(CreateUserRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new EmailAlreadyExistsException(request.email());
        }
        var user = User.builder()
            .name(request.name())
            .email(request.email())
            .password(passwordEncoder.encode(request.password()))
            .build();
        var saved = userRepository.save(user);
        return UserResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public Optional<UserResponse> findById(Long id) {
        return userRepository.findById(id).map(UserResponse::from);
    }
}
```

### Global exception handling

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(EmailAlreadyExistsException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public ErrorResponse handleEmailExists(EmailAlreadyExistsException ex) {
        return new ErrorResponse("EMAIL_EXISTS", ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleValidation(MethodArgumentNotValidException ex) {
        var errors = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .toList();
        return new ErrorResponse("VALIDATION_ERROR", errors.toString());
    }

    public record ErrorResponse(String code, String message) {}
}
```

### Repository with Spring Data JPA

```java
public interface UserRepository extends JpaRepository<User, Long> {

    boolean existsByEmail(String email);

    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.active = true AND u.role = :role")
    List<User> findActiveByRole(@Param("role") UserRole role);

    // Pagination
    Page<User> findByNameContainingIgnoreCase(String name, Pageable pageable);
}
```

## Anti-Patterns

### ❌ Field injection

```java
// ❌ Not testable without Spring context
@Autowired private UserRepository userRepository;

// ✅ Constructor injection
public UserService(UserRepository userRepository) {
    this.userRepository = userRepository;
}
```

### ❌ Scattered @Value across the app

```java
// ❌ Hard to maintain, no validation
@Value("${app.timeout}") private int timeout;
@Value("${app.url}") private String url;

// ✅ Centralized and validated configuration
private final AppProperties appProperties;
// appProperties.api().timeout()
// appProperties.api().baseUrl()
```

## Quick Reference

| Task | Pattern |
|------|---------|
| Injection | Constructor (without @Autowired) |
| Typed config | `@ConfigurationProperties(prefix="app")` + record |
| Config validation | `@Validated` + Jakarta annotations |
| Transactions | `@Transactional` on service, `readOnly=true` for reads |
| Request DTO | Record with `@Valid` annotations |
| Error handling | `@RestControllerAdvice` |
| Repository | Extends `JpaRepository<Entity, Id>` |
| Unit test | `@ExtendWith(MockitoExtension.class)` + mocks in constructor |

## Rules

- Constructor injection is mandatory — `@Autowired` field injection is forbidden; it hides dependencies and prevents unit testing without a Spring context
- Configuration must use `@ConfigurationProperties` with typed records; scattered `@Value` annotations are a maintainability anti-pattern
- `@Transactional` belongs on service methods only — never on controller methods or repository methods that already inherit transactions
- `@Transactional(readOnly = true)` must be used for all query-only service methods; it signals intent and enables database-level optimizations
- Exception handling must be centralized in a `@RestControllerAdvice` class; `try/catch` in controllers for business exceptions is a duplication anti-pattern

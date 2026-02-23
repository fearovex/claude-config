---
name: spring-boot-3
description: >
  Spring Boot 3.3+ patterns: constructor injection, typed config properties, service-layer transactions.
  Trigger: When building Spring Boot applications, configuring beans, or implementing REST services.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: building Spring Boot 3.3+ apps, configuring properties, implementing services, or creating REST controllers.

## Critical Patterns

### Pattern 1: Constructor Injection SIEMPRE

```java
// ✅ Constructor injection — testeable, explícito, inmutable
@Service
public class UserService {

    private final UserRepository userRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    // Sin @Autowired en constructor — Spring lo detecta automáticamente
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

// ❌ Field injection — no testeable, oculta dependencias
@Service
public class UserService {
    @Autowired private UserRepository userRepository; // Evitar
    @Autowired private EmailService emailService;     // Evitar
}
```

### Pattern 2: @ConfigurationProperties (no @Value disperso)

```java
// ✅ Configuración tipada con validación
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

// Registro en @SpringBootApplication o config class
@EnableConfigurationProperties(AppProperties.class)

// ❌ @Value disperso — difícil de mantener y testear
@Value("${app.api.base-url}") private String apiBaseUrl;
@Value("${app.api.timeout}") private int timeout;
```

### Pattern 3: @Transactional en servicios, NO en controllers

```java
// ✅ Transaction en service layer
@Service
public class OrderService {

    @Transactional
    public Order createOrder(CreateOrderRequest request) {
        var order = Order.from(request);
        orderRepository.save(order);
        inventoryService.reserve(order.items()); // En misma transacción
        return order;
    }

    @Transactional(readOnly = true) // Optimización para lecturas
    public List<Order> findByCustomer(Long customerId) {
        return orderRepository.findByCustomerId(customerId);
    }
}

// ❌ Transaction en controller — boundary incorrecto
@RestController
public class OrderController {
    @Transactional // Evitar — pertenece al service
    @PostMapping("/orders")
    public ResponseEntity<Order> create(...) { ... }
}
```

## Code Examples

### REST Controller con DTOs como records

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

// DTOs como records (Java 21+)
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

### Service completo

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

### Exception Handling global

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

### Repository con Spring Data JPA

```java
public interface UserRepository extends JpaRepository<User, Long> {

    boolean existsByEmail(String email);

    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.active = true AND u.role = :role")
    List<User> findActiveByRole(@Param("role") UserRole role);

    // Paginación
    Page<User> findByNameContainingIgnoreCase(String name, Pageable pageable);
}
```

## Anti-Patterns

### ❌ Field injection

```java
// ❌ No testeable sin Spring context
@Autowired private UserRepository userRepository;

// ✅ Constructor injection
public UserService(UserRepository userRepository) {
    this.userRepository = userRepository;
}
```

### ❌ @Value disperso por toda la app

```java
// ❌ Difícil de mantener, sin validación
@Value("${app.timeout}") private int timeout;
@Value("${app.url}") private String url;

// ✅ Configuración centralizada y validada
private final AppProperties appProperties;
// appProperties.api().timeout()
// appProperties.api().baseUrl()
```

## Quick Reference

| Task | Patrón |
|------|--------|
| Inyección | Constructor (sin @Autowired) |
| Config tipada | `@ConfigurationProperties(prefix="app")` + record |
| Validación config | `@Validated` + anotaciones Jakarta |
| Transacciones | `@Transactional` en service, `readOnly=true` para lecturas |
| DTO request | Record con `@Valid` anotaciones |
| Error handling | `@RestControllerAdvice` |
| Repository | Extends `JpaRepository<Entity, Id>` |
| Test unitario | `@ExtendWith(MockitoExtension.class)` + mocks en constructor |

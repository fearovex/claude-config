---
name: hexagonal-architecture-java
description: >
  Hexagonal Architecture (Ports and Adapters) patterns for Java services.
  Trigger: When designing Java services with hexagonal architecture, clean architecture, or ports-and-adapters pattern.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: designing Java applications with hexagonal architecture, implementing ports and adapters, or maintaining clean separation between domain and infrastructure.

## Critical Patterns

### Regla fundamental: El dominio no tiene dependencias externas

```
Domain → no imports de Spring, JPA, HTTP, ni ningún framework
Application → define puertos (interfaces), orquesta el dominio
Infrastructure → implementa los puertos (JPA, REST, Kafka, etc.)

Flujo de dependencias (siempre hacia adentro):
Infrastructure → Application → Domain
```

### Pattern 1: Domain puro (sin frameworks)

```java
// ✅ Domain entity — sin anotaciones de framework
public class Order {
    private final OrderId id;
    private final CustomerId customerId;
    private final List<OrderItem> items;
    private OrderStatus status;

    // Constructor, métodos de negocio
    public void confirm() {
        if (this.status != OrderStatus.PENDING) {
            throw new IllegalStateException("Only pending orders can be confirmed");
        }
        this.status = OrderStatus.CONFIRMED;
    }

    public Money total() {
        return items.stream()
            .map(OrderItem::subtotal)
            .reduce(Money.ZERO, Money::add);
    }
}

// ❌ Domain con anotaciones de JPA — viola la pureza
@Entity
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue
    private Long id;          // Tipo de DB, no de negocio

    @Column
    private String status;    // String en vez de enum del dominio
}
```

### Pattern 2: Application Layer — define puertos

```java
// Puerto de entrada (Use Case)
public interface CreateOrderUseCase {
    OrderId execute(CreateOrderCommand command);
}

// Puerto de salida (Repository — definido en application, implementado en infra)
public interface OrderRepository {
    void save(Order order);
    Optional<Order> findById(OrderId id);
    List<Order> findByCustomer(CustomerId customerId);
}

// Puerto de salida (notificaciones)
public interface NotificationPort {
    void notifyOrderConfirmed(Order order);
}

// Servicio de aplicación — implementa el use case, usa los puertos
@Service // ✅ Spring aquí está bien — es la capa de aplicación
public class CreateOrderService implements CreateOrderUseCase {

    private final OrderRepository orderRepository;
    private final NotificationPort notificationPort;

    public CreateOrderService(
        OrderRepository orderRepository,
        NotificationPort notificationPort
    ) {
        this.orderRepository = orderRepository;
        this.notificationPort = notificationPort;
    }

    @Override
    @Transactional
    public OrderId execute(CreateOrderCommand command) {
        var order = Order.create(command.customerId(), command.items());
        orderRepository.save(order);
        notificationPort.notifyOrderConfirmed(order);
        return order.id();
    }
}
```

### Pattern 3: Infrastructure — implementa los puertos

```java
// Adaptador de persistencia (implementa el puerto de dominio)
@Repository
public class JpaOrderRepository implements OrderRepository {

    private final JpaOrderEntityRepository jpa;
    private final OrderMapper mapper;

    @Override
    public void save(Order order) {
        jpa.save(mapper.toEntity(order));
    }

    @Override
    public Optional<Order> findById(OrderId id) {
        return jpa.findById(id.value())
            .map(mapper::toDomain);
    }
}

// Adaptador REST de entrada
@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final CreateOrderUseCase createOrder;

    @PostMapping
    public ResponseEntity<OrderIdResponse> create(@RequestBody CreateOrderRequest request) {
        var command = new CreateOrderCommand(
            new CustomerId(request.customerId()),
            request.items().stream().map(this::toItem).toList()
        );
        var orderId = createOrder.execute(command);
        return ResponseEntity.ok(new OrderIdResponse(orderId.value()));
    }
}
```

## Code Examples

### Estructura de paquetes

```
com.myapp/
├── domain/
│   ├── model/                  # Entities, Value Objects
│   │   ├── Order.java
│   │   ├── OrderId.java        # Value Object
│   │   └── Money.java          # Value Object
│   └── service/                # Domain services (lógica que no cabe en entity)
│       └── PricingService.java
├── application/
│   ├── port/
│   │   ├── in/                 # Use cases (puertos de entrada)
│   │   │   └── CreateOrderUseCase.java
│   │   └── out/                # Puertos de salida
│   │       ├── OrderRepository.java
│   │       └── NotificationPort.java
│   ├── service/                # Implementaciones de use cases
│   │   └── CreateOrderService.java
│   └── dto/                    # Commands y Queries
│       └── CreateOrderCommand.java
└── infrastructure/
    ├── persistence/
    │   ├── JpaOrderRepository.java   # Implementa OrderRepository
    │   ├── OrderEntity.java          # Entidad JPA
    │   └── OrderMapper.java          # Domain ↔ Entity
    ├── web/
    │   ├── OrderController.java      # REST adapter
    │   └── OrderRequest.java         # DTOs HTTP
    └── notification/
        └── EmailNotificationAdapter.java # Implementa NotificationPort
```

### Value Objects

```java
// ✅ Value Object — inmutable, validado, sin @Entity
public record OrderId(UUID value) {
    public OrderId {
        Objects.requireNonNull(value, "OrderId cannot be null");
    }

    public static OrderId generate() {
        return new OrderId(UUID.randomUUID());
    }

    public static OrderId of(String value) {
        return new OrderId(UUID.fromString(value));
    }
}

public record Money(BigDecimal amount, Currency currency) {
    public static final Money ZERO = new Money(BigDecimal.ZERO, Currency.EUR);

    public Money add(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException("Cannot add different currencies");
        }
        return new Money(this.amount.add(other.amount), this.currency);
    }
}
```

## Anti-Patterns

### ❌ JPA en el dominio

```java
// ❌ Acoplamiento con JPA en el dominio
@Entity
public class Order {
    @OneToMany(cascade = CascadeType.ALL)
    private List<OrderItemEntity> items;  // Tipo de infraestructura en dominio
}

// ✅ Dominio usa sus propios tipos
public class Order {
    private final List<OrderItem> items;  // Tipo del dominio
}
```

### ❌ Repositorio de Spring en application layer

```java
// ❌ Application depende de infraestructura
import org.springframework.data.repository.CrudRepository; // Spring en application

public interface OrderRepository extends CrudRepository<OrderEntity, Long> {}

// ✅ Puerto definido en application, sin imports de framework
public interface OrderRepository {
    void save(Order order);
    Optional<Order> findById(OrderId id);
}
```

## Quick Reference

| Capa | Contiene | No contiene |
|------|----------|-------------|
| Domain | Entities, VOs, Domain Services | Spring, JPA, HTTP |
| Application | Use Cases, Ports (interfaces), Commands | JPA entities, HTTP |
| Infrastructure | Controllers, JPA Adapters, External APIs | Domain logic |

| Task | Patrón |
|------|--------|
| Puerto de entrada | Interface en `application/port/in/` |
| Puerto de salida | Interface en `application/port/out/` |
| Implementar puerto | En `infrastructure/` |
| Use case | Service en `application/service/` |
| Inyección | Constructor injection en todos los servicios |

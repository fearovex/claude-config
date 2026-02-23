# sdd-tasks

> Desglosa el diseño en un plan de tareas atómicas, ordenadas y verificables.

**Triggers**: sdd:tasks, plan de tareas, desglosar implementación, task breakdown, sdd tasks

---

## Propósito

El plan de tareas convierte el diseño en una **lista de trabajo ejecutable**. Cada tarea es atómica (una sola cosa), concreta (tiene ruta de archivo), y verificable (se puede marcar como hecha).

Es la entrada para `sdd-apply`. Sin tasks aprobado, no se implementa.

---

## Proceso

### Paso 1 — Leer artefactos previos

Leo obligatoriamente:
- `openspec/changes/<nombre-cambio>/design.md` (la matriz de archivos y el enfoque)
- `openspec/changes/<nombre-cambio>/specs/` (los criterios de éxito)
- `openspec/config.yaml` si existe (reglas del proyecto)

### Paso 2 — Analizar dependencias entre tareas

Identifico el orden natural de implementación:
- Tipos/interfaces antes que su uso
- Providers/services antes que sus consumidores
- Schema/migration antes que el código que los usa
- Tests de unidad junto con el código (no al final)

### Paso 3 — Organizar en fases

Agrupo las tareas en fases lógicas:

```
Fase 1 — Fundación: tipos, interfaces, schemas, configuración
Fase 2 — Core: lógica de negocio principal
Fase 3 — Integración: conectar con el resto del sistema
Fase 4 — Testing: tests de las fases anteriores
Fase 5 — Limpieza: eliminar código temporal, actualizar docs
```

(Adapto los nombres de fase al contexto del cambio)

### Paso 4 — Crear tasks.md

Creo `openspec/changes/<nombre-cambio>/tasks.md`:

```markdown
# Plan de Tareas: [nombre-cambio]

Fecha: [YYYY-MM-DD]
Design: openspec/changes/[nombre]/design.md

## Progreso: 0/[total] tareas

## Fase 1: [Nombre de Fase]

- [ ] 1.1 Crear `src/types/auth.types.ts` con interfaces `LoginRequest`, `LoginResponse`, `JwtPayload`
- [ ] 1.2 Crear `src/schemas/auth.schema.ts` con schemas Zod para validación de login
- [ ] 1.3 Modificar `src/config/jwt.config.ts` — añadir `refreshSecret` y `refreshExpiresIn`

## Fase 2: [Nombre de Fase]

- [ ] 2.1 Crear `src/services/auth.service.ts` con métodos `login()`, `logout()`, `refreshToken()`
- [ ] 2.2 Modificar `src/repositories/user.repository.ts` — añadir método `findByEmail()`
- [ ] 2.3 Crear `src/middleware/auth.middleware.ts` para validación de JWT en rutas protegidas

## Fase 3: [Nombre de Fase]

- [ ] 3.1 Crear `src/controllers/auth.controller.ts` con endpoints POST /login, POST /logout, POST /refresh
- [ ] 3.2 Modificar `src/routes/index.ts` — registrar rutas de auth
- [ ] 3.3 Modificar `src/app.ts` — integrar auth middleware en rutas protegidas

## Fase 4: Testing

- [ ] 4.1 Crear `tests/unit/auth.service.spec.ts` — tests unitarios de AuthService
- [ ] 4.2 Crear `tests/integration/auth.controller.spec.ts` — tests de endpoints
- [ ] 4.3 Verificar cobertura de escenarios del spec (revisar openspec/changes/[nombre]/specs/)

## Fase 5: Limpieza

- [ ] 5.1 Actualizar `README.md` — documentar nuevos endpoints
- [ ] 5.2 Actualizar `docs/ai-context/architecture.md` si hubo cambios estructurales

---

## Notas de Implementación

[Decisiones del design que el implementador debe tener en cuenta:]
- [nota importante 1]
- [nota importante 2]

## Bloqueantes

[Tareas que no pueden empezar hasta que algo externo esté listo:]
- [bloqueante]: [qué lo resuelve]

[Si no hay: "Ninguno."]
```

---

## Formato de tarea bien escrita

### ✅ Bien escrita
```
- [ ] 2.1 Crear `src/services/payment.service.ts` con método `processPayment(dto: PaymentDto): Promise<PaymentResult>`
```

### ❌ Mal escrita
```
- [ ] Agregar lógica de pagos
```

**Regla**: Cada tarea debe responder "¿qué archivo y qué cambio concreto?"

---

## Output al Orquestador

```json
{
  "status": "ok|warning|blocked",
  "resumen": "Plan para [nombre-cambio]: [N] fases, [M] tareas totales. Estimación: [Bajo/Medio/Alto].",
  "artefactos": ["openspec/changes/<nombre>/tasks.md"],
  "siguiente_recomendado": ["sdd-apply"],
  "riesgos": ["[bloqueante si existe]"]
}
```

---

## Reglas

- Cada tarea DEBE tener ruta de archivo concreta
- Cada tarea DEBE ser atómica (una sola responsabilidad)
- Cada tarea DEBE ser verificable (se puede marcar done con certeza)
- Los tests van con su código, no todos al final
- El orden de fases respeta las dependencias técnicas
- Tareas de documentación y memoria (ai-context) van en la última fase
- NO incluyo tareas que van más allá del alcance de la propuesta
- Si detecto que el diseño está incompleto para generar tareas, reporto como bloqueante

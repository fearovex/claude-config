# sdd-design

> Produce el diseño técnico con decisiones de arquitectura, flujo de datos y plan de cambios en archivos.

**Triggers**: sdd:design, diseño técnico, arquitectura cambio, technical design, sdd design

---

## Propósito

El diseño define el **CÓMO se implementará** lo que las specs dicen que DEBE hacer. Es el puente entre los requisitos y el código. Documenta las decisiones técnicas y su justificación.

---

## Proceso

### Paso 1 — Leer artefactos previos

Leo obligatoriamente:
- `openspec/changes/<nombre-cambio>/proposal.md`
- `openspec/changes/<nombre-cambio>/specs/` (todos los spec.md)
- `docs/ai-context/architecture.md` si existe
- `docs/ai-context/conventions.md` si existe

Luego leo código real:
- Entry points relevantes
- Archivos que serán afectados según la propuesta
- Patrones existentes para seguirlos (no reinventar)
- Tests existentes (revelan contratos actuales)

### Paso 2 — Diseñar la solución técnica

Evalúo la solución considerando:
- Patrones ya usados en el proyecto (preferir consistencia)
- Impacto mínimo en código existente
- Testabilidad
- Reversibilidad (rollback plan de la propuesta)

### Paso 3 — Crear design.md

Creo `openspec/changes/<nombre-cambio>/design.md`:

```markdown
# Diseño Técnico: [nombre-cambio]

Fecha: [YYYY-MM-DD]
Propuesta: openspec/changes/[nombre]/proposal.md

## Enfoque General
[Descripción de alto nivel de la solución técnica en 3-5 líneas]

## Decisiones Técnicas
| Decisión | Elección | Alternativas Descartadas | Justificación |
|----------|----------|--------------------------|---------------|
| [decisión] | [qué se elige] | [alternativa A, alternativa B] | [por qué esta elección] |

## Flujo de Datos
[Diagrama ASCII o descripción del flujo]

Ejemplo:
```
Request → Middleware → Controller → Service → Repository → DB
                           ↓
                       Validator (Zod)
                           ↓
                       Response DTO
```

## Matriz de Cambios en Archivos
| Archivo | Acción | Qué se agrega/modifica |
|---------|--------|------------------------|
| `src/modules/auth/auth.service.ts` | Modificar | Agregar método `refreshToken()` |
| `src/modules/auth/auth.controller.ts` | Modificar | Nuevo endpoint POST /auth/refresh |
| `src/modules/auth/dto/refresh.dto.ts` | Crear | DTO para request de refresh |
| `src/modules/auth/auth.module.ts` | Modificar | Registrar nuevo provider |
| `tests/auth/refresh-token.spec.ts` | Crear | Tests del nuevo endpoint |

## Interfaces y Contratos
[Definiciones de tipos, interfaces, DTOs, schemas que se crearán]

```typescript
// Ejemplo
interface RefreshTokenRequest {
  refreshToken: string;
}

interface RefreshTokenResponse {
  accessToken: string;
  expiresIn: number;
}
```

## Estrategia de Testing
| Capa | Qué testear | Herramienta |
|------|-------------|-------------|
| Unit | [servicio/función] | [jest/vitest/pytest] |
| Integration | [endpoint/módulo] | [supertest/httpx] |
| E2E | [flujo completo si aplica] | [playwright/cypress] |

## Plan de Migración
[Si hay cambios en DB, schema, o datos existentes:]
- Paso 1: [migration script]
- Paso 2: [rollout gradual si aplica]
- Paso 3: [limpieza posterior]

[Si no hay migración: "No requiere migración de datos."]

## Preguntas Abiertas
[Aspectos que necesitan clarificación antes de implementar]
- [pregunta]: [impacto si no se resuelve]

[Si no hay: "Ninguna."]
```

---

## Ejemplos de decisiones bien documentadas

### ✅ Bien documentado
```markdown
| Validación de entrada | Zod en capa de controller | Class-validator, manual |
El proyecto ya usa Zod para schemas de DB (Drizzle).
Mantener consistencia evita dos sistemas de validación. |
```

### ❌ Mal documentado
```markdown
| Validación | Zod | otros | Es mejor |
```

---

## Diagramas ASCII útiles

```
# Flujo de autenticación
Client → POST /auth/login
            ↓
        AuthController
            ↓
        AuthService.validateCredentials()
            ↓
        UserRepository.findByEmail()
            ↓
        bcrypt.compare(password, hash)
            ↓ (success)
        JwtService.sign(payload)
            ↓
        Response { token, refreshToken }

# Estructura de módulo
auth/
├── auth.module.ts
├── auth.controller.ts
├── auth.service.ts
├── strategies/
│   ├── jwt.strategy.ts
│   └── local.strategy.ts
└── dto/
    ├── login.dto.ts
    └── refresh.dto.ts
```

---

## Output al Orquestador

```json
{
  "status": "ok|warning|blocked",
  "resumen": "Diseño para [nombre-cambio]: [N] archivos afectados, enfoque [descripción breve], riesgo [nivel].",
  "artefactos": ["openspec/changes/<nombre>/design.md"],
  "siguiente_recomendado": ["sdd-tasks (requiere spec + design completados)"],
  "riesgos": ["[riesgo técnico si encontrado]"]
}
```

---

## Reglas

- SIEMPRE leer código real antes de diseñar — nunca asumo la estructura
- Cada decisión DEBE tener justificación (el "por qué", no solo el "qué")
- Seguir patrones existentes del proyecto a menos que el cambio los corrija explícitamente
- La matriz de archivos debe ser concreta (rutas reales, no "algún archivo de auth")
- Los diagramas ASCII son preferibles a descripciones largas
- Si detecto que la propuesta es incompatible con la arquitectura actual, lo reporto como bloqueante
- NO escribo código de implementación — eso es `sdd-apply`

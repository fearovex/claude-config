---
name: jira-task
description: >
  Create standardized Jira tasks with proper structure, component splitting, and Jira Wiki markup.
  Trigger: When creating Jira tickets, tasks, or issues for features, bugs, or enhancements.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: creating Jira tickets, structuring work items, splitting tasks by component, or using the Jira MCP.

## Critical Patterns

### Regla 1: Split por componente

Si el cambio toca API, UI o SDK → **crear tareas separadas** por componente:
- Permite desarrollo paralelo
- Asignación por equipo
- Tracking de dependencias

```
✅ Feature en API + UI:
  Tarea 1: [FEATURE] Add user endpoint (API)
  Tarea 2: [FEATURE] Add user form (UI)

❌ No:
  Tarea 1: [FEATURE] Add user (API + UI)
```

### Regla 2: Estructura diferente para Bug vs Feature

- **Bug**: Tareas hermanas (independientes, urgentes)
- **Feature**: Jerarquía padre-hijo (contexto de negocio arriba, técnico abajo)

### Regla 3: Jira Wiki Markup (no Markdown)

```
Jira Wiki:          Markdown equivalente:
h2. Título          ## Título
*texto*             **texto**
* item              - item
|| col1 || col2 ||  | col1 | col2 |
| val1 | val2 |
{code:java}         ```java
...                 ...
{code}              ```
```

## Formato de Títulos

```
[TYPE] Description (components)

Tipos:
  [BUG]         Error en producción o desarrollo
  [FEATURE]     Nueva funcionalidad
  [ENHANCEMENT] Mejora de existente
  [REFACTOR]    Refactoring sin cambio de comportamiento
  [DOCS]        Documentación
  [CHORE]       Mantenimiento, deps, CI

Componentes: (API) (UI) (SDK) (API + UI)

Ejemplos:
  [FEATURE] Add user authentication (API)
  [FEATURE] Add login form (UI)
  [BUG] Fix session timeout (API)
  [ENHANCEMENT] Improve search performance (API)
```

## Plantillas

### Tarea Padre (Feature — contexto de negocio)

```
h2. Overview
Como [rol], quiero [funcionalidad] para [beneficio].

h2. Acceptance Criteria
* El usuario puede [acción 1]
* El sistema [comportamiento 1]
* Cuando [condición], entonces [resultado]

h2. Design
[Link a Figma si aplica]

h2. Notes
[Contexto adicional, decisiones, restricciones]
```

### Tarea Hijo / Técnica (API)

```
h2. Description
*Context:* [Link a tarea padre]

h2. Technical Requirements
* Crear endpoint POST /api/v1/[recurso]
* Validar input con [schema/validator]
* Retornar [formato de respuesta]

h2. Affected Files
* {{src/routes/[archivo].ts}} — [qué cambia]
* {{src/services/[archivo].ts}} — [qué cambia]
* {{tests/[archivo].spec.ts}} — [qué se agrega]

h2. Acceptance Criteria
* [ ] Endpoint responde 201 con datos válidos
* [ ] Retorna 400 con input inválido
* [ ] Tests unitarios pasan
* [ ] Tests de integración pasan

h2. Testing
*Happy path:*
# Enviar request válido → recibir 201
# Verificar datos en DB

*Edge cases:*
# Input inválido → 400 con mensaje descriptivo
# Usuario no autorizado → 401
```

### Tarea de Bug

```
h2. Current Behavior
[Qué está pasando actualmente — ser específico]

h2. Expected Behavior
[Qué debería pasar]

h2. Steps to Reproduce
# Paso 1
# Paso 2
# Paso 3

h2. Environment
* Version: [versión afectada]
* Browser/OS: [si aplica]

h2. Logs / Evidence
{code}
[stacktrace o logs relevantes]
{code}

h2. Affected Files
* {{ruta/al/archivo.ts}} — línea aprox. [N]

h2. Fix Approach
[Descripción de cómo se va a resolver]

h2. Testing
* [ ] Bug no reproducible después del fix
* [ ] Tests de regresión añadidos
```

## Campos Jira MCP

```javascript
// Campos requeridos para crear tarea via MCP
{
  project_key: "PROYECTO",      // Key del proyecto Jira
  issue_type: "Task",
  summary: "[FEATURE] Título (API)",
  description: "...",           // Jira Wiki markup
  priority: "Medium",           // Blocker|Critical|High|Medium|Low

  // Campos custom (verificar con tu instancia):
  // customfield_10359: "UI"    // Team field
}
```

## Prioridades

| Prioridad | Criterio |
|-----------|----------|
| Blocker | Sistema caído, datos en riesgo, bloquea a todo el equipo |
| Critical | Feature principal rota, afecta a mayoría de usuarios |
| High | Feature importante, workaround disponible |
| Medium | Mejora importante, no bloquea trabajo actual |
| Low | Nice-to-have, deuda técnica menor |

## Anti-Patterns

### ❌ Tarea gigante multi-componente

```
[FEATURE] Implement user auth (API + UI + docs + tests)
→ Demasiado grande, difícil de estimar y asignar
```

### ❌ Criterios de aceptación vagos

```
* El login funciona ← No testeable
* El usuario puede autenticarse exitosamente ← También vago

✅ Criterios testables:
* POST /api/auth/login con credenciales válidas retorna 200 + JWT
* POST /api/auth/login con password incorrecto retorna 401
* JWT tiene expiración de 24h
```

### ❌ Sin rutas de archivos

```
* Modificar el servicio de auth ← ¿Cuál?

✅ Con rutas:
* Modificar {{src/services/auth.service.ts}} — añadir método refreshToken()
```

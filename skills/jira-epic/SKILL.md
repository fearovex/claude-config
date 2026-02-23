---
name: jira-epic
description: >
  Create Jira epics for large features with overview, requirements, technical diagram, and task decomposition.
  Trigger: When creating Jira epics, planning large features, or structuring work spanning multiple components.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: creating Jira epics for large features, planning work that spans multiple sprints or components, or decomposing epics into tasks.

## Cuándo crear un Epic vs una Task

| Crear Epic | Crear Task directa |
|------------|-------------------|
| Feature que span múltiples sprints | Feature de 1-2 días |
| Requiere trabajo en API + UI + SDK | Trabajo en un solo componente |
| Nueva página completa de la app | Mejora pequeña existente |
| Refactor arquitectónico mayor | Bug fix o tweak |

## Formato de Título de Epic

```
[EPIC] Feature Name

Ejemplos:
  [EPIC] User Authentication System
  [EPIC] Analytics Dashboard
  [EPIC] Multi-tenant Support
  [EPIC] Payment Integration
```

## Plantilla de Epic

```
h2. Overview

*What:* [Qué hace esta feature en una oración]
*Who:* [Para qué usuarios/roles]
*Why:* [Qué problema resuelve o qué valor aporta]

h2. Goals
* [Objetivo medible 1]
* [Objetivo medible 2]
* [Objetivo medible 3]

h2. Out of Scope
* [Qué explícitamente NO incluye esta epic]
* [Qué se deja para una epic futura]

h2. Requirements

h3. Functional Requirements
* [RF-01] [Requisito funcional 1]
* [RF-02] [Requisito funcional 2]
* [RF-03] [Requisito funcional 3]

h3. Non-Functional Requirements
* Performance: [ej: API < 200ms p95]
* Security: [ej: autenticación requerida en todos los endpoints]
* Scalability: [ej: soportar N usuarios concurrentes]

h2. Technical Considerations

h3. Architecture
[Descripción del enfoque arquitectónico]

h3. Data Model Changes
[Nuevas tablas, campos, relaciones si aplica]

h3. API Changes
[Nuevos endpoints, cambios en existentes]

h3. UI Components
[Nuevas páginas, componentes principales]

h2. Diagram

{code}
[Diagrama ASCII del flujo principal o arquitectura]

Ejemplo:
User → Login Page → POST /api/auth/login
                         ↓
                    Validate credentials
                         ↓
                    Generate JWT + Refresh Token
                         ↓
                    Redirect → Dashboard
{code}

h2. Implementation Plan

h3. Phase 1: Foundation
* [ ] [Tarea técnica 1] — (API)
* [ ] [Tarea técnica 2] — (API)

h3. Phase 2: Core Features
* [ ] [Tarea técnica 3] — (UI)
* [ ] [Tarea técnica 4] — (UI)

h3. Phase 3: Integration & Polish
* [ ] [Tarea técnica 5] — (API + UI)
* [ ] [Tarea técnica 6]

h2. Acceptance Criteria
* [ ] [Criterio de éxito medible 1]
* [ ] [Criterio de éxito medible 2]
* [ ] [Criterio de éxito medible 3]

h2. Dependencies
* [Dependencia externa o interna que bloquea el inicio]

h2. Links
* Figma: [link si existe]
* Design doc: [link si existe]
* Related epics: [links]
```

## Descomposición en Tasks

Una vez creada la epic, la descompongo en tasks usando `jira-task` skill:

```
Epic: [EPIC] User Authentication System
  ↓
Tasks:
  [FEATURE] Add User model and repository (API)
  [FEATURE] Add login endpoint (API)
  [FEATURE] Add JWT middleware (API)
  [FEATURE] Add refresh token endpoint (API)
  [FEATURE] Add login page (UI)
  [FEATURE] Add protected route wrapper (UI)
  [FEATURE] Add auth state management (UI)
  [FEATURE] Add E2E auth tests (UI)
```

Reglas de descomposición:
- Cada task ≤ 2 días de trabajo
- Split por componente (API/UI/SDK)
- Orden respeta dependencias técnicas
- Tasks de la misma fase pueden ser paralelas

## Campos Jira MCP para Epic

```javascript
{
  project_key: "PROYECTO",
  issue_type: "Epic",
  summary: "[EPIC] Feature Name",
  description: "...",           // Jira Wiki markup
  priority: "High",
  // epic_name: "Feature Name"  // Campo específico de Epic en Jira
}
```

## Diagramas con Mermaid (si el proyecto los soporta)

```
// Flujo de datos
sequenceDiagram
    User->>+Browser: Enter credentials
    Browser->>+API: POST /auth/login
    API->>+DB: Validate user
    DB-->>-API: User found
    API-->>-Browser: JWT token
    Browser-->>-User: Redirect to dashboard

// Arquitectura
graph TD
    A[React App] --> B[Auth Context]
    B --> C[API Client]
    C --> D[/api/auth/login]
    C --> E[/api/auth/refresh]
    D --> F[(Database)]
    E --> F
```

## Anti-Patterns

### ❌ Epic sin out of scope

```
Sin "Out of Scope" → scope creep inevitable
→ Siempre definir explícitamente qué NO entra
```

### ❌ Tasks demasiado grandes en el epic

```
❌ [FEATURE] Implement entire auth system (API + UI) ← Una sola tarea
✅ Split en 6-8 tasks específicas por componente
```

### ❌ Criterios vagos

```
❌ "El sistema de auth funciona"
✅ "Usuario puede hacer login con email/password y recibe JWT con expiración 24h"
```

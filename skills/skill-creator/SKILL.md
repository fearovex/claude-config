# skill-creator

> Crea skills nuevas, ya sea genéricas para el catálogo global o específicas para el proyecto actual.

**Triggers**: skill:create, skill:add, crear skill, nueva skill, generar skill, add skill to project

---

## Dos modos de operación

### Modo `/skill:create <nombre>`
Crea una skill **nueva** que no existe en ningún lado. Me pregunta si es:
- **Genérica** → va a `~/.claude/skills/<nombre>/SKILL.md` (disponible en todos los proyectos)
- **De proyecto** → va a `.claude/skills/<nombre>/SKILL.md` (solo en este proyecto)

### Modo `/skill:add <nombre>`
Agrega al proyecto actual una skill **existente del catálogo global**. Copia o crea referencia.

---

## Proceso: /skill:create

### Paso 1 — Recopilar información

Hago las preguntas necesarias para crear una skill útil:

```
¿Esta skill es para este proyecto específico o para todos tus proyectos?
  1. Solo este proyecto → .claude/skills/
  2. Catálogo global → ~/.claude/skills/

¿Qué hace esta skill? (descripción en una oración)

¿Cuándo debe activarse? (¿qué situaciones disparan su uso?)

¿Hay patrones de código, comandos o procesos específicos que debe conocer?
```

Si el usuario ya dio suficiente contexto en el comando, omito preguntas obvias.

### Paso 2 — Si es skill de proyecto: analizar el código

Leo el código existente del proyecto para:
- Detectar patrones reales que documentar
- Encontrar ejemplos reales para incluir en la skill
- Identificar anti-patrones que ya existen y deben evitarse

### Paso 3 — Generar la skill

**Formato estándar de SKILL.md:**

```markdown
# [nombre-skill]

> [Descripción de una línea. Qué hace y para qué sirve.]

**Triggers**: [palabra1, palabra2, situación1, situación2]

---

## Cuándo usar esta skill

[Explicación de los contextos donde aplica]
[Condiciones específicas que la activan]

## Patrones Principales

### [Patrón 1]: [Nombre descriptivo]
[Explicación del patrón]

```[lenguaje]
[código de ejemplo real]
```

### [Patrón 2]: [Nombre descriptivo]
[Explicación]

```[lenguaje]
[código de ejemplo]
```

### [Patrón 3]: [Nombre descriptivo]
[Explicación]

```[lenguaje]
[código de ejemplo]
```

## Ejemplos Completos

### [Escenario 1]
[Código completo y ejecutable]

### [Escenario 2]
[Código completo y ejecutable]

## Anti-Patrones — Qué Evitar

### ❌ [Cosa a evitar]
[Por qué es problemático]

```[lenguaje]
// ❌ Mal
[código malo]
```

```[lenguaje]
// ✅ Bien
[código correcto]
```

## Referencia Rápida

| Tarea | Patrón/Comando |
|-------|---------------|
| [tarea común] | [solución] |
| [tarea común] | [solución] |
```

### Paso 4 — Previsualizar y confirmar

Muestro el contenido que voy a crear y confirmo con el usuario antes de escribir.

### Paso 5 — Crear y registrar

1. Creo el archivo en la ruta correspondiente
2. Si es skill de proyecto, sugiero añadirla al `CLAUDE.md` del proyecto en la sección de skills
3. Si es skill genérica, la añado al registry en `~/.claude/CLAUDE.md`

---

## Proceso: /skill:add

Cuando el usuario ejecuta `/skill:add <nombre>`:

### Verifico que existe en el catálogo global
```
~/.claude/skills/<nombre>/SKILL.md
```

Si no existe:
```
La skill "<nombre>" no está en el catálogo global.
Skills disponibles similares: [lista de skills parecidas]

¿Quieres crear una nueva con /skill:create <nombre>?
```

### Verifico que el proyecto tiene `.claude/skills/`
Si no existe, lo creo.

### Estrategia de adición

**Opción A — Referencia simbólica conceptual:**
Añado la skill al `CLAUDE.md` del proyecto en la sección de skills activas, indicando que está en el catálogo global.

```markdown
## Skills Activas
- `~/.claude/skills/typescript/SKILL.md` — TypeScript patterns
- `~/.claude/skills/nextjs-15/SKILL.md` — Next.js 15 patterns
```

**Opción B — Copia local** (si el usuario quiere personalizar):
Copia el archivo a `.claude/skills/<nombre>/SKILL.md` y añade nota de origen.

### Actualizo CLAUDE.md del proyecto

Añado la skill al registry del proyecto para que sea visible.

---

## Skills del Catálogo Global

Catálogo actual disponible en `~/.claude/skills/`:

### Meta-tools y SDD

| Skill | Para qué |
|-------|----------|
| `project-setup` | Setup de proyectos con SDD |
| `project-audit` | Auditoría de configuración |
| `project-update` | Actualización de configuración |
| `skill-creator` | Creación de skills |
| `memory-manager` | Gestión de memoria de proyecto |
| `sdd-explore` | Fase exploración SDD |
| `sdd-propose` | Fase propuesta SDD |
| `sdd-spec` | Fase especificaciones SDD |
| `sdd-design` | Fase diseño técnico SDD |
| `sdd-tasks` | Fase plan de tareas SDD |
| `sdd-apply` | Fase implementación SDD |
| `sdd-verify` | Fase verificación SDD |
| `sdd-archive` | Fase archivo SDD |

### Frontend / Full-stack

| Skill | Para qué |
|-------|----------|
| `react-19` | React 19 con React Compiler, Server Components, use() hook |
| `nextjs-15` | Next.js 15 App Router, Server Actions, data fetching |
| `typescript` | TypeScript strict mode, utility types, patrones avanzados |
| `zustand-5` | State management con Zustand 5, slices, persistencia |
| `zod-4` | Validación de schemas con Zod 4, breaking changes desde v3 |
| `tailwind-4` | Tailwind CSS 4, cn() utility, estilos dinámicos |
| `ai-sdk-5` | Vercel AI SDK 5, useChat, streaming, tool integration |
| `react-native` | React Native con Expo, navegación, NativeWind |
| `electron` | Electron apps de escritorio, IPC, auto-updater |

### Backend

| Skill | Para qué |
|-------|----------|
| `django-drf` | Django REST Framework, ViewSets, Serializers |
| `spring-boot-3` | Spring Boot 3.3+, constructor injection, @ConfigurationProperties |
| `hexagonal-architecture-java` | Arquitectura hexagonal en Java, Ports & Adapters |
| `java-21` | Java 21, records, sealed types, virtual threads |

### Testing

| Skill | Para qué |
|-------|----------|
| `playwright` | E2E testing con Playwright, Page Object Model |
| `pytest` | Testing Python con pytest, fixtures, mocking, async |

### Tooling / Proceso

| Skill | Para qué |
|-------|----------|
| `github-pr` | Pull Requests con conventional commits y gh CLI |
| `jira-task` | Crear Jira tasks con estructura estándar y Wiki markup |
| `jira-epic` | Crear Jira epics con overview, requisitos y desglose |

### Lenguajes / Frameworks

| Skill | Para qué |
|-------|----------|
| `elixir-antipatterns` | Anti-patrones Elixir/Phoenix: error handling, Ecto, testing |

> **Nota**: `angular` no está disponible (404 en el repo origen). Se puede crear con `/skill:create angular`.

---

## Reglas

- Siempre uso código real del proyecto como ejemplos cuando es skill de proyecto
- Nunca invento patrones — los extraigo del código existente
- Mínimo 3 ejemplos de código por skill
- Siempre incluyo anti-patrones
- Previualizo y confirmo antes de escribir
- Registro la skill nueva en el CLAUDE.md correspondiente

# Memoria de Usuario — Juan Pablo

## Arquitectura SDD implementada (2026-02-23)

Implementada arquitectura Spec-Driven Development a nivel de usuario en `~/.claude/`.

### Estructura creada
- `~/.claude/CLAUDE.md` — Orquestador global con comandos meta-tool y SDD
- `~/.claude/memory/MEMORY.md` — Este archivo
- `~/.claude/skills/project-setup/` — Inicializa SDD + memoria en proyectos
- `~/.claude/skills/project-audit/` — Audita configuración Claude de proyectos
- `~/.claude/skills/project-update/` — Actualiza/migra configuración de proyectos
- `~/.claude/skills/skill-creator/` — Crea skills genéricas o de proyecto
- `~/.claude/skills/memory-manager/` — Gestiona docs/ai-context/ en proyectos
- `~/.claude/skills/sdd-explore/` — Fase exploración del ciclo SDD
- `~/.claude/skills/sdd-propose/` — Fase propuesta del ciclo SDD
- `~/.claude/skills/sdd-spec/` — Fase especificaciones del ciclo SDD
- `~/.claude/skills/sdd-design/` — Fase diseño técnico del ciclo SDD
- `~/.claude/skills/sdd-tasks/` — Fase plan de tareas del ciclo SDD
- `~/.claude/skills/sdd-apply/` — Fase implementación del ciclo SDD
- `~/.claude/skills/sdd-verify/` — Fase verificación del ciclo SDD
- `~/.claude/skills/sdd-archive/` — Fase archivo del ciclo SDD

### Filosofía de la arquitectura
- User-level = meta-tool (crea/audita/actualiza proyectos)
- Proyectos reciben CLAUDE.md + docs/ai-context/ (memoria híbrida)
- SDD corre desde user-level via sub-agentes (Task tool)
- Memoria: markdown versionado en repo (sin dependencias externas)
- Engram (MCP) queda como mejora opcional futura

### Comandos clave
- `/project:setup` — nuevo proyecto
- `/project:audit` — health check
- `/sdd:ff <nombre>` — ciclo rápido
- `/memory:update` — actualizar memoria del proyecto

## Preferencias del usuario
- Español en comunicación
- Código limpio, sin over-engineering
- Confirmar antes de acciones irreversibles

# memory-manager

> Inicializa y actualiza la capa de memoria híbrida del proyecto (docs/ai-context/).

**Triggers**: memory:init, memory:update, actualizar memoria, inicializar memoria, ai-context, contexto proyecto, memoria proyecto

---

## Dos modos de operación

### `/memory:init`
Genera los 5 archivos de memoria desde cero leyendo el proyecto actual.
Usar cuando: el proyecto no tiene `docs/ai-context/` todavía.

### `/memory:update`
Actualiza los archivos existentes con lo trabajado en la sesión actual.
Usar cuando: se terminó trabajo significativo y quiero que la memoria refleje el estado actual.

---

## Proceso: /memory:init

### Paso 1 — Inventario del proyecto

Leo en profundidad:
- Archivos de configuración (package.json, pyproject.toml, etc.)
- Estructura de carpetas
- README.md y cualquier documentación existente
- Archivos de código representativos (entry points, modelos, componentes principales)
- Tests existentes
- Configuraciones de CI/CD si existen

### Paso 2 — Generar stack.md

```markdown
# Stack Técnico

Última actualización: [YYYY-MM-DD]

## Lenguaje Principal
- **[Lenguaje]** [versión]

## Framework(s)
- **[Framework]** [versión] — [propósito]
- **[Framework2]** [versión] — [propósito]

## Base de Datos
- **[DB]** [versión] — [ORM si aplica]

## Testing
- **[Framework de testing]** [versión]
- Comando: `[comando para correr tests]`
- Cobertura: [si está configurada]

## Build & Dev
- **[Bundler/Builder]** [versión]
- Dev: `[comando]`
- Build: `[comando]`
- Preview: `[comando si existe]`

## Dependencias Clave
| Paquete | Versión | Propósito |
|---------|---------|-----------|
| [nombre] | [versión] | [para qué sirve en el proyecto] |

## Herramientas de Calidad
- Linter: [eslint/flake8/etc. + config]
- Formatter: [prettier/black/etc.]
- Type checker: [tsc/mypy/etc.]
```

### Paso 3 — Generar architecture.md

```markdown
# Arquitectura del Proyecto

Última actualización: [YYYY-MM-DD]

## Visión General
[2-3 líneas describiendo qué hace el proyecto]

## Patrón Arquitectónico
[Feature-based / Layer-based / Clean Architecture / Hexagonal / etc.]
[Justificación si se puede inferir]

## Estructura de Carpetas
```
[árbol de carpetas principales con descripción de cada una]
```

## Decisiones de Arquitectura
| Decisión | Elección | Alternativas | Razón inferida |
|----------|----------|--------------|----------------|
| [decisión] | [qué se eligió] | [alternativas] | [por qué] |

## Flujo Principal
[Descripción del flujo de datos / request más común]

## Puntos de Entrada
- [Archivo/ruta]: [qué es]

## Integraciones Externas
- [Servicio/API]: [cómo se integra]
```

### Paso 4 — Generar conventions.md

```markdown
# Convenciones del Proyecto

Última actualización: [YYYY-MM-DD]

## Naming
- **Archivos**: [detectado: kebab-case / snake_case / PascalCase]
- **Variables/Funciones**: [detectado]
- **Clases/Tipos/Interfaces**: [detectado]
- **Constantes**: [detectado]
- **Tests**: [patrón detectado: *.test.ts / test_*.py / etc.]

## Organización de Archivos
[Cómo se organizan los archivos según el patrón detectado]
[Dónde van los tests relativos al código]

## Patrones de Código Detectados
[Patrones recurrentes observados en el código real]

## Commits
[Convención si se detecta en historial: conventional commits, etc.]

## Branches
[Estrategia si se detecta: main/develop, feature branches, etc.]
```

### Paso 5 — Generar known-issues.md

```markdown
# Issues Conocidos y Gotchas

Última actualización: [YYYY-MM-DD]

## Deuda Técnica Detectada
[Código con TODO/FIXME/HACK comments]
[Patrones problemáticos observados]

## Gotchas del Proyecto
[Cosas raras o no obvias detectadas en el código]

## Limitaciones Actuales
[Limitaciones funcionales evidentes en el código]

## Workarounds en Uso
[Si hay workarounds documentados en el código, listarlos aquí]

---
*Este archivo se actualiza durante el desarrollo. Ejecutar /memory:update después de resolver issues.*
```

### Paso 6 — Generar changelog-ai.md

```markdown
# Changelog de Cambios por AI

Este archivo registra los cambios significativos realizados por Claude.
Se actualiza ejecutando /memory:update al finalizar una sesión de trabajo.

## Formato
### [YYYY-MM-DD] — [Nombre del cambio]
**Qué se hizo**: [descripción]
**Archivos modificados**: [lista]
**Decisiones tomadas**: [decisiones relevantes]
**Notas**: [cualquier cosa importante para sesiones futuras]

---

*Historial vacío — se llenará durante el desarrollo.*
```

---

## Proceso: /memory:update

### Cuándo usar
Después de:
- Completar un ciclo SDD (/sdd:archive)
- Hacer cambios arquitectónicos significativos
- Resolver bugs importantes
- Cambiar convenciones o patrones del proyecto
- Al final de una sesión larga de trabajo

### Paso 1 — Analizar qué cambió en esta sesión

Reviso el contexto de la sesión actual:
- Qué archivos fueron creados/modificados
- Qué decisiones se tomaron
- Qué problemas se encontraron y resolvieron
- Si cambió el stack (nuevas deps, versiones actualizadas)

### Paso 2 — Determinar qué archivos actualizar

| Si en la sesión... | Actualizo |
|-------------------|-----------|
| Se agregaron/quitaron dependencias | `stack.md` |
| Se tomaron decisiones de arquitectura | `architecture.md` |
| Se definieron/cambiaron convenciones | `conventions.md` |
| Se encontraron/resolvieron bugs | `known-issues.md` |
| Se hizo cualquier cambio significativo | `changelog-ai.md` |

### Paso 3 — Actualizar stack.md (si aplica)

Solo actualizo las secciones que cambiaron. Agrego sin borrar historia:
- Nueva dependencia: la añado a la tabla con su versión y propósito
- Dependencia removida: la marco como `~~[nombre]~~ (removido [fecha])`
- Versión actualizada: actualizo el número

### Paso 4 — Actualizar architecture.md (si aplica)

Si se tomaron decisiones nuevas, las añado a la tabla de decisiones:
```markdown
| [nueva decisión] | [elección] | [alternativas] | [razón real] |
```

Si cambió la estructura de carpetas, actualizo el árbol.

### Paso 5 — Actualizar known-issues.md (si aplica)

- Issues resueltos: los muevo a una sección `## Issues Resueltos` con fecha de resolución
- Issues nuevos encontrados: los añado a la sección correspondiente

### Paso 6 — Añadir entrada a changelog-ai.md

Siempre añado una entrada al inicio (cronológicamente descendente):

```markdown
### [YYYY-MM-DD] — [Nombre descriptivo del trabajo]
**Qué se hizo**: [descripción concisa]
**Archivos modificados**:
- `ruta/archivo.ext` — [qué cambió]
**Decisiones tomadas**:
- [decisión relevante para sesiones futuras]
**Notas**: [cualquier cosa importante]
```

### Paso 7 — Resumen al usuario

```
✅ Memoria actualizada

Archivos modificados:
  - docs/ai-context/stack.md — añadidas 2 dependencias
  - docs/ai-context/known-issues.md — 1 issue resuelto, 1 nuevo
  - docs/ai-context/changelog-ai.md — entrada añadida

Sin cambios:
  - docs/ai-context/architecture.md
  - docs/ai-context/conventions.md
```

---

## Reglas

- Leo código real para inferir, nunca invento
- Actualizo de forma incremental, nunca sobreescribo todo
- Marco con [Por confirmar] lo que no puedo determinar con certeza
- Preservo el historial: los items resueltos se mueven, no se borran
- Si `docs/ai-context/` no existe y se ejecuta `/memory:update`, sugiero `/memory:init` primero

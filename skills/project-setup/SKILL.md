# project-setup

> Despliega la arquitectura SDD completa con capa de memoria híbrida en el proyecto actual.

**Triggers**: project:setup, inicializar proyecto, setup sdd, configurar claude proyecto, nuevo proyecto sdd

---

## Qué hace este skill

Cuando el usuario ejecuta `/project:setup`, analizo el proyecto actual y genero:
1. `CLAUDE.md` en la raíz del proyecto con contexto real detectado
2. `docs/ai-context/` con los 5 archivos de memoria inicializados
3. `openspec/config.yaml` para el ciclo SDD
4. Registro de skills relevantes según el stack detectado

---

## Proceso de Setup

### Paso 1 — Detección del proyecto

Leo y analizo:
- `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `pom.xml`
- Estructura de carpetas (src/, app/, lib/, tests/, etc.)
- Archivos de configuración (tsconfig, eslint, prettier, etc.)
- README.md si existe
- Carpetas de docs existentes
- `.git/` para confirmar que es un repositorio

**Infiero:**
- Lenguaje principal y versión
- Framework(s) en uso
- Base de datos / ORM
- Herramientas de testing
- Herramientas de build / bundler
- Convenciones de naming detectadas (camelCase, snake_case, etc.)
- Estructura de carpetas (feature-based, layer-based, monorepo, etc.)

### Paso 2 — Generar CLAUDE.md del proyecto

Creo `CLAUDE.md` en la raíz con estas secciones:

```markdown
# [Nombre del Proyecto]

## Stack
[Stack detectado con versiones]

## Arquitectura
[Estructura de carpetas explicada]
[Patrón arquitectónico detectado]

## Convenciones
[Naming conventions detectadas]
[Patrones de código observados]

## Comandos Importantes
[Scripts de package.json / Makefile / etc.]

## Memoria de Proyecto
Al inicio de cada sesión, lee los archivos relevantes en docs/ai-context/:
- docs/ai-context/stack.md — Stack técnico detallado
- docs/ai-context/architecture.md — Decisiones de arquitectura
- docs/ai-context/conventions.md — Convenciones del equipo
- docs/ai-context/known-issues.md — Bugs conocidos y gotchas
- docs/ai-context/changelog-ai.md — Historial de cambios del AI

Al finalizar trabajo significativo: actualiza los archivos relevantes o
ejecuta /memory:update para que el AI los actualice.

## Skills Activas
[Lista de skills relevantes para este proyecto]

## SDD — Spec-Driven Development
Este proyecto usa SDD. Los artefactos viven en openspec/.
Para iniciar un cambio: /sdd:new <nombre-cambio>
Para ciclo rápido: /sdd:ff <nombre-cambio>
```

### Paso 3 — Inicializar docs/ai-context/

Creo los 5 archivos con contenido real basado en lo detectado:

#### `docs/ai-context/stack.md`
```markdown
# Stack Técnico

Última actualización: [fecha]

## Lenguaje
- [Lenguaje]: [versión]

## Framework Principal
- [Framework]: [versión]
- [Detalles de configuración relevantes]

## Base de Datos / ORM
- [Si aplica]

## Testing
- [Framework de testing]
- [Comandos para correr tests]

## Build / Bundler
- [Herramienta]: [versión]
- [Comando de build]
- [Comando de dev]

## Dependencias Clave
| Paquete | Versión | Propósito |
|---------|---------|-----------|
| [nombre] | [versión] | [para qué sirve] |
```

#### `docs/ai-context/architecture.md`
```markdown
# Arquitectura del Proyecto

Última actualización: [fecha]

## Patrón Arquitectónico
[Detectado: feature-based / layer-based / clean architecture / etc.]

## Estructura de Carpetas
[Árbol explicado con propósito de cada carpeta]

## Decisiones de Arquitectura
| Decisión | Elección | Alternativas | Razón |
|----------|----------|--------------|-------|
[Inferidas del código existente]

## Flujo de Datos
[Descripción del flujo principal]

## Puntos de Entrada
[Entry points principales del sistema]
```

#### `docs/ai-context/conventions.md`
```markdown
# Convenciones del Proyecto

Última actualización: [fecha]

## Naming
- Archivos: [detectado]
- Variables/Funciones: [detectado]
- Clases/Tipos: [detectado]
- Constantes: [detectado]

## Estructura de Archivos
[Cómo se organizan los archivos de cada tipo]

## Patrones de Código
[Patrones detectados en el código existente]

## Git
[Convenciones de commits si se detectan]
[Estrategia de branches si se detecta]

## Testing
[Dónde van los tests]
[Convenciones de naming de tests]
```

#### `docs/ai-context/known-issues.md`
```markdown
# Issues Conocidos

Última actualización: [fecha]

## Bugs Activos
[Vacío al inicio — se llena durante el desarrollo]

## Gotchas y Limitaciones
[Cualquier cosa rara detectada en el código existente]

## Deuda Técnica Identificada
[Patrones problemáticos detectados]

## Workarounds en Uso
[Si hay workarounds en el código, documentarlos aquí]
```

#### `docs/ai-context/changelog-ai.md`
```markdown
# Changelog de Cambios por AI

Este archivo registra los cambios significativos realizados por Claude.

## Formato de Entrada
### [YYYY-MM-DD] — [Nombre del cambio]
**Qué se hizo**: [descripción]
**Archivos modificados**: [lista]
**Decisiones tomadas**: [decisiones relevantes]
**Notas**: [cualquier cosa importante]

---

[Las entradas se agregan aquí cronológicamente]
```

### Paso 4 — Crear openspec/config.yaml

```yaml
project:
  name: "[nombre detectado]"
  description: "[descripción del README o inferida]"
  stack:
    language: "[lenguaje]"
    framework: "[framework]"
    database: "[db o none]"
  conventions:
    naming: "[snake_case|camelCase|kebab-case]"
    structure: "[feature|layer|mono]"

artifact_store:
  mode: openspec

rules:
  proposal:
    - "Debe incluir plan de rollback"
    - "Debe definir criterios de éxito medibles"
  specs:
    - "Usar Given/When/Then para todos los escenarios"
    - "Incluir casos límite y estados de error"
  design:
    - "Cada decisión debe tener justificación"
    - "Preferir patrones existentes del proyecto"
  tasks:
    - "Tareas atómicas y verificables"
    - "Incluir rutas de archivos en descripción"
  apply:
    - "Seguir convenciones del proyecto"
    - "Correr tests antes de marcar completo"
  verify:
    - "Verificar compliance con specs primero"
    - "Luego verificar adherencia al diseño"
```

### Paso 5 — Reporte final

Presento al usuario:
```
✅ Proyecto configurado: [nombre]

Stack detectado:
  - [lenguaje + versión]
  - [framework + versión]
  - [testing framework]

Archivos creados:
  - CLAUDE.md
  - docs/ai-context/stack.md
  - docs/ai-context/architecture.md
  - docs/ai-context/conventions.md
  - docs/ai-context/known-issues.md
  - docs/ai-context/changelog-ai.md
  - openspec/config.yaml

Próximos pasos:
  1. Revisa y ajusta CLAUDE.md con detalles que yo no pude detectar
  2. Para iniciar un cambio: /sdd:new <nombre>
  3. Para crear skills específicas del proyecto: /skill:create <nombre>
```

---

## Reglas

- NUNCA sobreescribo archivos existentes sin advertir y pedir confirmación
- Si ya existe `CLAUDE.md`, ofrezco merge inteligente o crear backup
- Si ya existe `docs/ai-context/`, ofrezco actualizar solo lo que falta
- Siempre leo código real — nunca invento el stack
- Si no puedo detectar algo con certeza, lo marco como `[Por confirmar]`

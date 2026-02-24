# project-audit

> Deep diagnostic of Claude/SDD configuration. Read-only. Produces a structured report that /project:fix consumes as its spec.

**Triggers**: `/project:audit`, auditar proyecto, revisar config claude, diagnostico sdd, health check proyecto

---

## Rol en el flujo SDD meta-configuración

Este skill es el **equivalente a la fase SPEC** del ciclo SDD, aplicado a la configuración del proyecto:

```
/project:audit  →  audit-report.md  →  /project:fix  →  /project:audit (verify)
     (spec)           (artefacto)          (apply)           (verify)
```

El reporte generado ES la especificación que `/project:fix` implementa. Sin audit, no hay fix.

**Regla absoluta**: Este skill NUNCA modifica archivos. Solo lee y reporta.

---

## Artefacto de salida

Al finalizar, guarda el reporte en:
```
[project_root]/.claude/audit-report.md
```

Este archivo persiste entre sesiones y es el input de `/project:fix`.

---

## Proceso de Auditoría — 7 Dimensiones

Ejecuto todas las dimensiones de forma sistemática, leyendo archivos reales. Nunca asumo.

---

### Dimensión 1 — CLAUDE.md

**Objetivo**: Verificar que el CLAUDE.md del proyecto es completo, preciso y habilita SDD.

**Project type detection (run before checks):**

Check if the project is a `global-config` repo:
- Condition A: `install.sh` + `sync.sh` exist at project root, OR
- Condition B: `openspec/config.yaml` contains `framework: "Claude Code SDD meta-system"`

If detected as global-config:
- Accept `CLAUDE.md` at root as equivalent to `.claude/CLAUDE.md`
- Note in report header: `Project Type: global-config`
- The CLAUDE.md path check passes without penalty

**Checks a ejecutar:**

| Check | Cómo verifico | Severidad si falla |
|-------|--------------|-------------------|
| Existe `.claude/CLAUDE.md` (or root `CLAUDE.md` for global-config repos) | Intento leerlo | ❌ CRÍTICO |
| No está vacío (>50 líneas) | Contar líneas | ❌ CRÍTICO |
| Tiene sección Stack | Buscar `## Tech Stack` o `## Stack` | ⚠️ ALTO |
| Stack coincide con package.json/pyproject.toml | Leer ambos, comparar versiones clave | ⚠️ ALTO |
| Tiene sección Architecture | Buscar `## Architecture` | ⚠️ ALTO |
| Tiene Skills registry | Buscar tabla de skills | ⚠️ ALTO |
| Tiene Commands registry | Buscar tabla de commands | ⚠️ MEDIO |
| Tiene Unbreakable Rules | Buscar `## Unbreakable Rules` o similar | ⚠️ MEDIO |
| Tiene Plan Mode Rules | Buscar `## Plan Mode` | ℹ️ BAJO |
| Menciona SDD (`/sdd:new` o `/sdd:ff`) | Buscar texto `/sdd:` | ⚠️ ALTO |
| Referencias a ai-context/ son correctas | Verificar que las rutas mencionadas existen | ⚠️ MEDIO |

**Para el stack**: leo `package.json` (o equivalente), extraigo las 5-10 dependencias más importantes, y comparo con lo declarado en CLAUDE.md. Reporto discrepancias específicas con versión declarada vs versión real.

---

### Dimensión 2 — Memoria (ai-context/)

**Objetivo**: Verificar que la capa de memoria existe, tiene contenido sustancial y es coherente con el código real.

**Checks de existencia:**

| Archivo | Líneas mínimas aceptables |
|---------|--------------------------|
| `ai-context/stack.md` | > 30 líneas |
| `ai-context/architecture.md` | > 40 líneas |
| `ai-context/conventions.md` | > 30 líneas |
| `ai-context/known-issues.md` | > 10 líneas (puede ser breve si el proyecto es nuevo) |
| `ai-context/changelog-ai.md` | > 5 líneas (al menos una entrada) |

**Checks de contenido** (para cada archivo que existe):

- **stack.md**: ¿Menciona las mismas versiones que package.json? Busco las top-5 dependencias del proyecto y verifico que están documentadas.
- **architecture.md**: ¿Menciona directorios que realmente existen en el proyecto? Leo el árbol de carpetas y cruzo.
- **conventions.md**: ¿Las convenciones documentadas mencionan patrones que se usan en el código real? Tomo 2-3 archivos de muestra y verifico.
- **known-issues.md**: ¿Tiene contenido real o es un template vacío? Busco frases como "[Por confirmar]" o "[Vacío]".
- **changelog-ai.md**: ¿Tiene al menos una entrada con fecha? Verifico formato `## YYYY-MM-DD`.

**Nota sobre ubicación**: La ruta puede ser `ai-context/` (sin docs/) o `docs/ai-context/`. Verifico ambas.

---

### Dimensión 3 — SDD Orchestrator

**Objetivo**: Verificar que el ciclo SDD está completamente operativo en este proyecto.

**Sub-checks:**

#### 3a. Global SDD skills (prerequisito de todo lo demás)
Leo si existen los 8 archivos en `~/.claude/skills/`:
- `sdd-explore/SKILL.md`
- `sdd-propose/SKILL.md`
- `sdd-spec/SKILL.md`
- `sdd-design/SKILL.md`
- `sdd-tasks/SKILL.md`
- `sdd-apply/SKILL.md`
- `sdd-verify/SKILL.md`
- `sdd-archive/SKILL.md`

Si alguno falta → ❌ CRÍTICO (SDD no puede funcionar sin las fases).

#### 3b. openspec/ en el proyecto
| Check | Severidad |
|-------|-----------|
| Existe `openspec/` | ❌ CRÍTICO (SDD no tiene dónde guardar artefactos) |
| Existe `openspec/config.yaml` | ❌ CRÍTICO (orquestador no puede arrancar) |
| `config.yaml` tiene `artifact_store.mode: openspec` | ⚠️ ALTO |
| `config.yaml` tiene nombre y stack del proyecto | ℹ️ BAJO |

#### 3c. CLAUDE.md menciona SDD
| Check | Severidad |
|-------|-----------|
| Contiene `/sdd:new` o `/sdd:ff` | ⚠️ ALTO |
| Tiene sección explicando el flujo SDD | ℹ️ BAJO |

#### 3d. Cambios huérfanos
Leo `openspec/changes/` (si existe). Un cambio huérfano es una carpeta en `changes/` que NO está en `changes/archive/` y cuya última modificación tiene >14 días.

Listo:
```
Cambios huérfanos detectados:
  - nombre-cambio: última fase completada "tasks" (lleva X días sin actividad)
```

---

### Dimensión 4 — Skills Quality

**Objetivo**: Verificar que las skills son sustanciales y que el registry en CLAUDE.md es exacto.

**Checks:**

#### 4a. Registry vs disco (bidireccional)
- Por cada skill listada en CLAUDE.md → verifico que el archivo/directorio existe en `.claude/skills/`
- Por cada archivo en `.claude/skills/` → verifico que está listado en CLAUDE.md
- Reporto: skills en registry pero no en disco / skills en disco pero no en registry

#### 4b. Contenido mínimo
Para cada skill file (`.md` o directorio con `SKILL.md`):
- ¿Tiene más de 30 líneas? → Si no, es probablemente un stub
- ¿Tiene alguna sección de proceso/instrucciones? → Si no, no es funcional

#### 4c. Global tech skills relevantes no instaladas
Leo el stack del proyecto (package.json) y verifico si existen en `~/.claude/skills/` skills tecnológicas relevantes que no están en el proyecto:

| Si proyecto usa | Skill global disponible |
|-----------------|------------------------|
| React 18+ | `react-19/SKILL.md` |
| Next.js 14+ | `nextjs-15/SKILL.md` |
| TypeScript | `typescript/SKILL.md` |
| Zustand | `zustand-5/SKILL.md` |
| Tailwind | `tailwind-4/SKILL.md` |
| Zod | `zod-4/SKILL.md` |
| Playwright | `playwright/SKILL.md` |

---

### Dimensión 5 — Commands Quality

**Objetivo**: Verificar que los commands son funcionales y el registry es exacto.

**Checks:**

#### 5a. Registry vs disco (bidireccional)
- Por cada command listado en CLAUDE.md → verifico que el archivo existe en `.claude/commands/`
- Por cada archivo en `.claude/commands/` → verifico que está listado en CLAUDE.md
- Reporto discrepancias en ambas direcciones

#### 5b. Contenido mínimo
Para cada command file:
- ¿Tiene más de 20 líneas?
- ¿Tiene sección de pasos o proceso definido? (busco "##", "Paso", "Step", lista numerada)
- Si es un stub sin proceso definido → marcarlo como ⚠️ NO FUNCIONAL

---

### Dimensión 6 — Cross-reference Integrity

**Objetivo**: Todo lo referenciado en la configuración de Claude debe existir en disco.

**Checks:**

| Qué verifico | Dónde busco referencias |
|-------------|------------------------|
| Docs referenciados en CLAUDE.md | Sección `## Documentation` → `.claude/docs/` |
| Templates referenciados en CLAUDE.md | Sección templates → `.claude/templates/` |
| Rutas mencionadas en skills | Scan de skills buscando paths (`/lib/`, `/domain/`, `pages/api/`) |
| Rutas mencionadas en ai-context/ | Verificar que dirs documentados en architecture.md existen |
| Skill files mencionadas en commands | Si un command importa o referencia una skill |

Para cada referencia rota: reporto el archivo fuente, la línea aproximada, y el path que no existe.

---

### Dimensión 8 — Testing & Verification Integrity

**Objetivo**: Verificar que el proyecto exige y evidencia pruebas reales antes de archivar cambios SDD.

**Checks:**

#### 8a. openspec/config.yaml tiene sección de testing
| Check | Severidad |
|-------|-----------|
| `config.yaml` tiene bloque `testing:` | ⚠️ ALTO |
| Define `minimum_score_to_archive` | ⚠️ ALTO |
| Define `required_artifacts_per_change` | ⚠️ MEDIO |
| Define `verify_report_requirements` | ⚠️ MEDIO |
| Tiene `test_project` o estrategia de prueba documentada | ℹ️ BAJO |

#### 8b. Cambios archivados tienen verify-report.md
Para cada carpeta en `openspec/changes/archive/`:
- ¿Existe `verify-report.md`? Si no → ⚠️ ALTO
- ¿Tiene al menos un ítem `[x]` en su checklist? Si no → ⚠️ ALTO
- ¿Menciona qué proyecto/contexto fue usado para verificar? Si no → ℹ️ BAJO

Reporto:
```
Cambios archivados sin verify-report.md: [lista]
Cambios con verify-report.md vacío o sin [x]: [lista]
```

#### 8c. Cambios activos tienen criterios de verificación definidos
Para cada carpeta activa en `openspec/changes/` (no archivadas):
- Si tiene `tasks.md` → ¿incluye sección de criterios de verificación?
- Si tiene `design.md` → ¿define cómo se probará el cambio?

#### 8d. Reglas de verify en config.yaml son ejecutables
Leo el bloque `rules.verify` del `openspec/config.yaml` y evalúo:
- ¿Son verificables objetivamente o son frases vacías como "asegurarse de que funciona"?
- ¿Al menos una regla menciona `/project:audit` o una métrica concreta?

---

### Dimensión 7 — Architecture Compliance (sampling)

**Objetivo**: Verificar con muestras reales que el código sigue la arquitectura documentada.

**Metodología**: No analizo todo el código. Tomo muestras representativas.

**Checks de muestra:**

#### 7a. API routes (reviso 3 al azar)
- ¿Usan el wrapper de observabilidad (`withSegmentAPI` o equivalente)?
- ¿Contienen lógica de negocio directamente? (señal: imports de ORM/BD directo)
- ¿Tienen más de 50 líneas de lógica? (posible violación de "thin handler")

#### 7b. Domain services (reviso 3 al azar)
- ¿Importan el ORM desde el path correcto (`lib/prisma` u equivalente)?
- ¿Las funciones siguen la convención de naming documentada (`*Fn`, `*Service`, etc.)?

#### 7c. Components (reviso 2 al azar)
- ¿Importan servicios directamente en lugar de usar hooks?
- ¿Tienen lógica de negocio inline?

#### 7d. Violaciones críticas (busco en todo el codebase)
```
Busco señales de violaciones graves:
- new PrismaClient() fuera de lib/
- import { PrismaClient } fuera de lib/
- font-weight (si el proyecto tiene SCSS y la convención lo prohíbe)
- console.log en archivos de producción (no en tests)
```

Para cada violación: reporto archivo, línea, y la regla violada.

---

## Formato del Reporte

El reporte se guarda en `.claude/audit-report.md` con esta estructura exacta:

```markdown
# Audit Report — [Nombre del Proyecto]
Generated: [YYYY-MM-DD HH:MM]
Score: [XX/100]
SDD Ready: [YES|NO|PARTIAL]

---

## FIX_MANIFEST
<!-- Este bloque es consumido por /project:fix — NO modificar manualmente -->
```yaml
score: [XX]
sdd_ready: [true|false|partial]
generated_at: "[timestamp]"
project_root: "[ruta absoluta]"

required_actions:
  critical:
    - id: "[id-unico]"
      type: "[create_file|update_file|create_dir|add_registry_entry|install_skill]"
      target: "[ruta o elemento]"
      reason: "[por qué es necesario]"
      template: "[nombre_template si aplica]"
  high:
    - id: "[id-unico]"
      type: "..."
      target: "..."
      reason: "..."
  medium:
    - ...
  low:
    - ...

missing_global_skills:
  - "[skill-name]"

orphaned_changes:
  - name: "[nombre]"
    last_phase: "[fase]"
    days_inactive: [N]

violations:
  - file: "[ruta]"
    line: [N]
    rule: "[regla violada]"
    severity: "[critical|high|medium]"
```​
---

## Resumen Ejecutivo
[3-5 líneas describiendo el estado general del proyecto desde la perspectiva de Claude/SDD]

---

## Score: [XX]/100

| Dimensión | Puntos | Max | Estado |
|-----------|--------|-----|--------|
| CLAUDE.md completo y preciso | [X] | 20 | ✅/⚠️/❌ |
| Memoria inicializada | [X] | 15 | ✅/⚠️/❌ |
| Memoria con contenido sustancial | [X] | 10 | ✅/⚠️/❌ |
| SDD Orchestrator operativo | [X] | 20 | ✅/⚠️/❌ |
| Skills registry íntegro y funcional | [X] | 10 | ✅/⚠️/❌ |
| Commands registry íntegro y funcional | [X] | 10 | ✅/⚠️/❌ |
| Cross-references válidas | [X] | 5 | ✅/⚠️/❌ |
| Architecture compliance | [X] | 5 | ✅/⚠️/❌ |
| Testing & Verification integrity | [X] | 5 | ✅/⚠️/❌ |
| **TOTAL** | **[X]** | **100** | |

**SDD Readiness**: [FULL / PARTIAL / NOT CONFIGURED]
- FULL: openspec/ existe, config.yaml válido, CLAUDE.md menciona /sdd:*, global skills presentes
- PARTIAL: Algunos elementos SDD presentes pero incompletos
- NOT CONFIGURED: openspec/ no existe

---

## Dimensión 1 — CLAUDE.md [OK|ADVERTENCIA|CRÍTICO]

| Check | Estado | Detalle |
|-------|--------|---------|
| Existe `.claude/CLAUDE.md` (or root `CLAUDE.md` for global-config repos) | ✅/❌ | |
| Tiene >50 líneas | ✅/❌ | [X] líneas |
| Stack documentado | ✅/⚠️/❌ | |
| Stack vs package.json | ✅/⚠️/❌ | [discrepancias específicas] |
| Tiene Architecture section | ✅/⚠️/❌ | |
| Skills registry presente | ✅/⚠️/❌ | |
| Commands registry presente | ✅/⚠️/❌ | |
| Menciona SDD (/sdd:*) | ✅/⚠️/❌ | |

**Discrepancias de Stack:**
[Lista cada discrepancia: "Declara React 18, actual ^19.0.0"]

---

## Dimensión 2 — Memoria [OK|ADVERTENCIA|CRÍTICO]

| Archivo | Existe | Líneas | Contenido | Coherencia |
|---------|--------|--------|-----------|------------|
| stack.md | ✅/❌ | [N] | ✅/⚠️/❌ | ✅/⚠️/❌ |
| architecture.md | ✅/❌ | [N] | ✅/⚠️/❌ | ✅/⚠️/❌ |
| conventions.md | ✅/❌ | [N] | ✅/⚠️/❌ | ✅/⚠️/❌ |
| known-issues.md | ✅/❌ | [N] | ✅/⚠️/❌ | ✅/⚠️/❌ |
| changelog-ai.md | ✅/❌ | [N] | ✅/⚠️/❌ | N/A |

**Problemas de coherencia detectados:**
[Lista problemas concretos con archivo + qué está desactualizado]

---

## Dimensión 3 — SDD Orchestrator [OK|ADVERTENCIA|CRÍTICO]

**Global SDD Skills:**
| Skill | Existe |
|-------|--------|
| sdd-explore | ✅/❌ |
| sdd-propose | ✅/❌ |
| sdd-spec | ✅/❌ |
| sdd-design | ✅/❌ |
| sdd-tasks | ✅/❌ |
| sdd-apply | ✅/❌ |
| sdd-verify | ✅/❌ |
| sdd-archive | ✅/❌ |

**openspec/ en proyecto:**
| Check | Estado |
|-------|--------|
| `openspec/` existe | ✅/❌ |
| `openspec/config.yaml` existe | ✅/❌ |
| Config válido | ✅/⚠️/❌ |

**CLAUDE.md menciona SDD:** ✅/❌

**Cambios huérfanos:** [ninguno | lista]

---

## Dimensión 4 — Skills [OK|ADVERTENCIA|CRÍTICO]

**Skills en registry pero no en disco:**
[lista o "ninguna"]

**Skills en disco pero no en registry:**
[lista o "ninguna"]

**Skills con contenido insuficiente (<30 líneas):**
[lista o "ninguna"]

**Global tech skills recomendadas no instaladas:**
[lista con comando para instalar: /skill:add nombre]

---

## Dimensión 5 — Commands [OK|ADVERTENCIA|CRÍTICO]

**Commands en registry pero no en disco:**
[lista o "ninguna"]

**Commands en disco pero no en registry:**
[lista o "ninguna"]

**Commands sin proceso definido (stubs):**
[lista o "ninguna"]

---

## Dimensión 6 — Cross-references [OK|ADVERTENCIA|CRÍTICO]

**Referencias rotas:**
| Archivo fuente | Referencia | Problema |
|----------------|-----------|---------|
[lista o "ninguna"]

---

## Dimensión 7 — Architecture Compliance [OK|ADVERTENCIA|CRÍTICO]

**Archivos de muestra analizados:** [lista]

**Violaciones encontradas:**
| Archivo | Línea | Regla violada | Severidad |
|---------|-------|--------------|-----------|
[lista o "ninguna"]

---

## Dimensión 8 — Testing & Verification [OK|ADVERTENCIA|CRÍTICO]

**openspec/config.yaml tiene bloque testing:** ✅/❌

**Cambios archivados sin verify-report.md:**
[lista o "ninguna"]

**Cambios archivados con verify-report.md vacío (sin [x]):**
[lista o "ninguna"]

**Reglas de verify son ejecutables:** ✅/⚠️/❌

---

## Acciones Requeridas

### Críticas (bloquean SDD):
1. [acción concreta] → ejecutar `/project:fix` o manualmente: [instrucción]

### Altas (degradan calidad):
1. [acción concreta]

### Medias:
1. [acción concreta]

### Bajas (mejoras opcionales):
1. [acción concreta]

---

*Para implementar estas correcciones: ejecutar `/project:fix`*
*Este reporte fue generado por `/project:audit` — no modificar el bloque FIX_MANIFEST manualmente*
```

---

## Scoring detallado

| Dimensión | Criterio | Puntos máx |
|-----------|---------|------------|
| **CLAUDE.md** | Existe + estructura completa + stack preciso + SDD refs | 20 |
| **Memoria — existencia** | Los 5 archivos existen | 15 |
| **Memoria — calidad** | Contenido sustancial + coherente con código | 10 |
| **SDD Orchestrator** | Global skills + openspec/ + config.yaml + CLAUDE.md refs | 20 |
| **Skills** | Registry exacto + contenido mínimo + sin skills globales faltantes | 10 |
| **Commands** | Registry exacto + commands funcionales | 10 |
| **Cross-references** | Sin referencias rotas | 5 |
| **Architecture** | Sin violaciones críticas en muestras | 5 |
| **Testing & Verification** | config.yaml tiene testing block + cambios archivados tienen verify-report.md | 5 |

**Interpretación:**
- 90-100: SDD fully operational, excelente mantenimiento
- 75-89: Listo para usar SDD, mejoras menores pendientes
- 50-74: SDD parcialmente configurado, necesita `/project:fix`
- <50: Requiere setup completo

---

## Reglas de ejecución

1. **Siempre leo archivos reales** — nunca asumo el contenido de un archivo
2. **Ejecuto en un subagente** con herramientas de lectura — nunca en contexto principal
3. **Siempre guardo el reporte** en `.claude/audit-report.md` antes de presentar al usuario
4. **El FIX_MANIFEST es YAML válido** — verifico que el bloque sea parseable
5. **Nunca modifico nada** — este skill es 100% read-only
6. **Si no puedo leer un archivo**, lo reporto como ❌ con el error exacto, no asumo que no existe
7. **Al finalizar**, notifico al usuario: "Reporte guardado en `.claude/audit-report.md`. Para implementar las correcciones: `/project:fix`"

# project-audit

> Audita la configuración Claude de un proyecto y genera un reporte de salud con recomendaciones.

**Triggers**: project:audit, auditar proyecto, revisar config claude, diagnostico proyecto, health check proyecto

---

## Qué hace este skill

Cuando el usuario ejecuta `/project:audit`, analizo el proyecto actual y genero un reporte de salud que evalúa:
- Presencia y calidad del CLAUDE.md
- Estado de la capa de memoria (docs/ai-context/)
- Configuración SDD (openspec/)
- Skills disponibles y pertinencia
- Desincronización entre código real y documentación AI

---

## Proceso de Auditoría

### Dimensión 1 — CLAUDE.md

Verifico si existe y evalúo:

| Check | Estado | Observación |
|-------|--------|-------------|
| Existe CLAUDE.md en raíz | ✅/❌ | |
| Tiene sección de Stack | ✅/⚠️/❌ | |
| Stack documentado está actualizado | ✅/⚠️/❌ | Comparo con package.json/pyproject.toml |
| Tiene instrucciones de memoria | ✅/⚠️/❌ | |
| Tiene registro de skills activas | ✅/⚠️/❌ | |
| Tiene referencia a SDD | ✅/⚠️/❌ | |

**Severidades:**
- ❌ CRÍTICO: Falta o está vacío
- ⚠️ ADVERTENCIA: Existe pero desactualizado/incompleto
- ✅ OK: Presente y correcto

### Dimensión 2 — Capa de Memoria

Verifico `docs/ai-context/`:

| Archivo | Existe | Último update | Fresco* |
|---------|--------|---------------|---------|
| stack.md | ✅/❌ | [fecha] | ✅/⚠️ |
| architecture.md | ✅/❌ | [fecha] | ✅/⚠️ |
| conventions.md | ✅/❌ | [fecha] | ✅/⚠️ |
| known-issues.md | ✅/❌ | [fecha] | ✅/⚠️ |
| changelog-ai.md | ✅/❌ | [fecha] | ✅/⚠️ |

*Fresco = modificado en los últimos 30 días o coherente con el código actual

Para cada archivo que existe, verifico coherencia básica con el código real:
- ¿El stack documentado coincide con las dependencias reales?
- ¿Las convenciones documentadas se siguen en el código?
- ¿Los issues conocidos siguen presentes o ya fueron resueltos?

### Dimensión 3 — SDD (openspec/)

Verifico si hay ciclos SDD en progreso o completados:

| Check | Estado |
|-------|--------|
| Existe openspec/ | ✅/❌ |
| Existe openspec/config.yaml | ✅/❌ |
| Hay cambios activos (sin archivar) | [lista] |
| Hay cambios archivados | [count] |
| Specs maestras actualizadas | ✅/⚠️/❌ |

Si hay cambios activos sin terminar, los listo con su estado:
```
Cambios en progreso:
  - add-user-auth: hasta fase "tasks" (falta apply/verify/archive)
  - fix-payment-bug: hasta fase "design" (falta tasks/apply/verify/archive)
```

### Dimensión 4 — Skills

Verifico qué skills están disponibles y cuáles deberían estar:

**Skills del proyecto** (`.claude/skills/`):
- Listo las existentes
- Evalúo si están actualizadas vs el código real

**Skills recomendadas faltantes:**
Basado en el stack detectado, sugiero skills que deberían existir:
```
Stack detectado: Next.js 15 + TypeScript + Zod
Skills recomendadas no instaladas:
  - nextjs-15 (disponible en catálogo global)
  - typescript (disponible en catálogo global)
  - zod-4 (disponible en catálogo global)

Instalar con: /skill:add nextjs-15
```

---

## Reporte de Salud

Genero un reporte estructurado:

```markdown
# Reporte de Salud — [Nombre del Proyecto]
Fecha: [fecha]

## Puntuación General: [XX/100]

## Resumen Ejecutivo
[2-3 líneas del estado general]

## CLAUDE.md — [OK|ADVERTENCIA|CRÍTICO]
[Detalles de checks]

## Memoria (docs/ai-context/) — [OK|ADVERTENCIA|CRÍTICO]
[Detalles de checks]
[Archivos desactualizados o faltantes]

## SDD (openspec/) — [OK|ADVERTENCIA|CRÍTICO]
[Estado de cambios activos]
[Estado de specs maestras]

## Skills — [OK|ADVERTENCIA|CRÍTICO]
[Skills presentes]
[Skills recomendadas faltantes]

## Acciones Recomendadas

### Críticas (hacer ahora):
1. [acción] → [comando para ejecutarlo]

### Importantes (hacer pronto):
1. [acción] → [comando o instrucción]

### Opcionales (mejoras):
1. [acción]
```

---

## Puntuación

| Componente | Peso | Puntos |
|------------|------|--------|
| CLAUDE.md completo | 25% | 0-25 |
| Memoria inicializada | 25% | 0-25 |
| Memoria actualizada (<30 días) | 20% | 0-20 |
| Skills relevantes instaladas | 15% | 0-15 |
| SDD sin cambios huérfanos | 15% | 0-15 |

**Interpretación:**
- 90-100: Excelente
- 70-89: Bien, mejoras menores
- 50-69: Necesita atención
- <50: Requiere setup

---

## Reglas

- Leo código real para verificar coherencia — nunca asumo
- No modifico nada durante la auditoría, solo reporto
- Si detecto información desactualizada en ai-context/, indico qué cambió
- Siempre termino con acciones concretas y sus comandos

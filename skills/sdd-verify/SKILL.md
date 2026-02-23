# sdd-verify

> Verifica que la implementación cumple con las specs, el diseño y el plan de tareas.

**Triggers**: sdd:verify, verificar implementación, quality gate, validar cambio, sdd verify

---

## Propósito

La verificación es el **quality gate** antes del archivo. Valida objetivamente que lo implementado cumple con lo especificado. No arregla nada — solo reporta.

---

## Proceso

### Paso 1 — Cargar todos los artefactos

Leo:
- `openspec/changes/<nombre-cambio>/tasks.md` — qué se planificó
- `openspec/changes/<nombre-cambio>/specs/` — qué se requería
- `openspec/changes/<nombre-cambio>/design.md` — cómo se diseñó
- Los archivos de código que fueron creados/modificados

### Paso 2 — Check de Completitud (Tasks)

Cuento tareas totales vs completadas:

```markdown
### Completitud
| Métrica | Valor |
|---------|-------|
| Tareas totales | [N] |
| Tareas completadas [x] | [M] |
| Tareas incompletas [ ] | [K] |

Tareas incompletas:
- [ ] [número y descripción de cada una]
```

**Severidad:**
- Tareas de lógica core incompletas → CRÍTICO
- Tareas de cleanup/docs incompletas → ADVERTENCIA

### Paso 3 — Check de Correctitud (Specs)

Para CADA requisito en los spec.md:

1. Busco evidencia en el código de que está implementado
2. Para CADA escenario Given/When/Then:
   - ¿Está el DADO manejado? (precondición/guard)
   - ¿Está el CUANDO implementado? (el action/endpoint)
   - ¿Está el ENTONCES verificable? (el resultado correcto)

```markdown
### Correctitud (Specs)
| Requisito | Estado | Notas |
|-----------|--------|-------|
| [Req 1] | ✅ Implementado | |
| [Req 2] | ⚠️ Parcial | Falta escenario de error 401 |
| [Req 3] | ❌ No implementado | No existe el endpoint /auth/refresh |

### Cobertura de Escenarios
| Escenario | Estado |
|-----------|--------|
| Login exitoso | ✅ Cubierto |
| Login fallido — contraseña incorrecta | ✅ Cubierto |
| Login fallido — usuario no existe | ⚠️ Parcial — implementado pero sin test |
| Token expirado | ❌ No cubierto |
```

### Paso 4 — Check de Coherencia (Design)

Verifico que se siguieron las decisiones del design:

```markdown
### Coherencia (Design)
| Decisión | ¿Seguida? | Notas |
|----------|-----------|-------|
| Validación con Zod | ✅ Sí | |
| JWT con RS256 | ⚠️ Desviación | Se usó HS256. El dev lo documentó en tasks. |
| Repository pattern | ✅ Sí | |
```

### Paso 5 — Check de Testing

```markdown
### Testing
| Área | Tests Existen | Escenarios Cubiertos |
|------|---------------|---------------------|
| AuthService.login() | ✅ Sí | 3/4 escenarios |
| AuthController | ✅ Sí | Happy paths únicamente |
| Middleware JWT | ❌ No | — |
```

### Paso 6 — Crear verify-report.md

Creo `openspec/changes/<nombre-cambio>/verify-report.md`:

```markdown
# Reporte de Verificación: [nombre-cambio]

Fecha: [YYYY-MM-DD]
Verificador: sdd-verify

## Resumen

| Dimensión | Estado |
|-----------|--------|
| Completitud (Tasks) | ✅ OK / ⚠️ ADVERTENCIA / ❌ CRÍTICO |
| Correctitud (Specs) | ✅ OK / ⚠️ ADVERTENCIA / ❌ CRÍTICO |
| Coherencia (Design) | ✅ OK / ⚠️ ADVERTENCIA / ❌ CRÍTICO |
| Testing | ✅ OK / ⚠️ ADVERTENCIA / ❌ CRÍTICO |

## Veredicto: PASS / PASS CON ADVERTENCIAS / FAIL

---

## Detalle: Completitud
[tablas del paso 2]

## Detalle: Correctitud
[tablas del paso 3]

## Detalle: Coherencia
[tablas del paso 4]

## Detalle: Testing
[tablas del paso 5]

---

## Issues Encontrados

### CRÍTICOS (deben resolverse antes de archivar):
- [descripción concreta del issue]
[o: "Ninguno."]

### ADVERTENCIAS (deberían resolverse):
- [descripción]
[o: "Ninguna."]

### SUGERENCIAS (mejoras opcionales):
- [descripción]
[o: "Ninguna."]
```

---

## Criterios de Veredicto

| Veredicto | Condición |
|-----------|-----------|
| **PASS** | 0 críticos, 0 advertencias |
| **PASS CON ADVERTENCIAS** | 0 críticos, 1+ advertencias |
| **FAIL** | 1+ críticos |

---

## Severidades

| Severidad | Descripción | Bloquea archivo |
|-----------|-------------|-----------------|
| **CRÍTICO** | Requisito no implementado, escenario principal no cubierto, tarea core incompleta | Sí |
| **ADVERTENCIA** | Escenario de edge case sin test, desviación del design, tarea de cleanup pendiente | No |
| **SUGERENCIA** | Mejora de calidad opcional | No |

---

## Output al Orquestador

```json
{
  "status": "ok|warning|failed",
  "resumen": "Verificación [nombre-cambio]: [veredicto]. [N] críticos, [M] advertencias.",
  "artefactos": ["openspec/changes/<nombre>/verify-report.md"],
  "siguiente_recomendado": ["sdd-archive (si PASS o PASS CON ADVERTENCIAS)"],
  "riesgos": ["CRÍTICO: [descripción si hay]"]
}
```

---

## Reglas

- SOLO reporto — no corrijo nada durante la verificación
- Leo código real — no asumo que algo funciona porque existe el archivo
- Soy objetivo: reporto lo que ES, no lo que debería ser
- Si hay desviaciones documentadas en tasks.md, las evalúo con el contexto
- Un FAIL no es personal — es información para mejorar
- Ejecuto los tests si es posible (via Bash tool): reporte los resultados reales

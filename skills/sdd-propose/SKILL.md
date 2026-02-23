# sdd-propose

> Crea una propuesta de cambio con intención clara, alcance definido y enfoque técnico.

**Triggers**: sdd:propose, crear propuesta, definir cambio, propuesta sdd

---

## Propósito

La propuesta define el **QUÉ y el POR QUÉ** antes de entrar en detalles técnicos. Es el contrato de alcance del cambio. Sin propuesta aprobada, no hay specs ni diseño.

---

## Proceso

### Paso 1 — Leer contexto previo

Si existe `openspec/changes/<nombre-cambio>/exploration.md`, lo leo primero.
Si existe `openspec/config.yaml`, leo las reglas del proyecto.
Si existe `docs/ai-context/architecture.md`, lo consulto para coherencia.

### Paso 2 — Entender la petición en profundidad

Si la petición es ambigua, pregunto:
- ¿Cuál es el problema o necesidad que motiva este cambio?
- ¿Hay restricciones conocidas (performance, compatibilidad, etc.)?
- ¿Hay partes que explícitamente están FUERA de alcance?

### Paso 3 — Crear directorio del cambio

```
openspec/changes/<nombre-cambio>/
```

### Paso 4 — Escribir proposal.md

Creo `openspec/changes/<nombre-cambio>/proposal.md`:

```markdown
# Propuesta: [nombre-cambio]

Fecha: [YYYY-MM-DD]
Estado: Borrador

## Intención
[Una oración clara: qué problema resuelve o qué necesidad cubre]

## Motivación
[Por qué esto es necesario ahora. Contexto del negocio o técnico.]

## Alcance

### Incluido
- [entregable 1]
- [entregable 2]
- [entregable 3]

### Excluido (explícitamente fuera de alcance)
- [qué NO se va a hacer y por qué]

## Enfoque Propuesto
[Descripción de alto nivel de la solución técnica.
No entra en detalle de implementación — eso es el design.
Explica el "cómo" a nivel conceptual.]

## Áreas Afectadas
| Área/Módulo | Tipo de Cambio | Impacto |
|-------------|----------------|---------|
| [área] | Nuevo/Modificado/Eliminado | Bajo/Medio/Alto |

## Riesgos
| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|-----------|
| [riesgo] | Baja/Media/Alta | Bajo/Medio/Alto | [cómo mitigarlo] |

## Plan de Rollback
[Cómo revertir si algo sale mal.
Debe ser concreto: qué archivos, qué comandos, qué pasos.]

## Dependencias
- [Qué debe existir/completarse antes de empezar]
- [Cambios en otras partes del sistema que esto requiere]

## Criterios de Éxito
- [ ] [criterio medible y verificable 1]
- [ ] [criterio medible y verificable 2]
- [ ] [criterio medible y verificable 3]

## Estimación de Esfuerzo
[Bajo (horas) / Medio (1-2 días) / Alto (varios días)]
```

### Paso 5 — Resumen al orquestador

Devuelvo un resumen ejecutivo claro:

```
Propuesta creada: [nombre-cambio]

Intención: [una línea]
Alcance: [N entregables incluidos, M excluidos]
Enfoque: [una línea]
Riesgo: Bajo/Medio/Alto
Siguiente paso: specs + design (pueden correr en paralelo)
```

---

## Output al Orquestador

```json
{
  "status": "ok|warning|blocked",
  "resumen": "Propuesta [nombre]: [intención en una línea]. Riesgo [nivel].",
  "artefactos": ["openspec/changes/<nombre>/proposal.md"],
  "siguiente_recomendado": ["sdd-spec", "sdd-design"],
  "riesgos": ["[riesgo principal si hay]"]
}
```

---

## Reglas

- SIEMPRE crear `proposal.md` — es la entrada para todas las fases siguientes
- Toda propuesta DEBE tener plan de rollback y criterios de éxito
- Los criterios de éxito deben ser MEDIBLES y VERIFICABLES (no vagos)
- El alcance excluido es tan importante como el incluido — previene scope creep
- No entro en detalles de implementación — eso es trabajo de `sdd-design`
- Si la propuesta es trivial (cambio de 1-2 líneas), lo indico y sugiero omitir el ciclo completo

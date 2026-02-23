# sdd-explore

> Investiga y analiza una idea o área del codebase antes de comprometerse a cambios.

**Triggers**: sdd:explore, explorar, investigar codebase, analizar antes de cambiar, research feature

---

## Propósito

La fase de exploración es **opcional pero valiosa**. Su objetivo es entender el terreno antes de proponer cambios. No crea código, no modifica nada. Solo lee y analiza.

Úsala cuando:
- La petición es vaga o compleja
- No estás seguro del alcance del cambio
- Quieres entender el impacto antes de comprometerte
- Hay múltiples enfoques posibles

---

## Proceso

### Paso 1 — Entender la petición

Clasifico qué tipo de exploración se necesita:
- **Feature nueva**: ¿Qué existe ya? ¿Dónde encajaría?
- **Bug**: ¿Dónde está el problema? ¿Cuál es la causa raíz?
- **Refactor**: ¿Qué código está afectado? ¿Cuáles son los riesgos?
- **Integración**: ¿Qué existe para conectar? ¿Qué falta?

### Paso 2 — Investigar el codebase

Leo código real siguiendo esta jerarquía:
1. Entry points del área afectada
2. Archivos relacionados con la funcionalidad
3. Tests existentes (revelan comportamiento esperado)
4. Configuraciones relevantes
5. `docs/ai-context/architecture.md` si existe (para entender decisiones pasadas)

### Paso 3 — Analizar enfoques

Para cada enfoque posible genero una tabla comparativa:

| Enfoque | Pros | Contras | Esfuerzo | Riesgo |
|---------|------|---------|----------|--------|
| [Opción A] | | | Bajo/Medio/Alto | Bajo/Medio/Alto |
| [Opción B] | | | | |

### Paso 4 — Identificar riesgos y dependencias

- Código que se rompería con el cambio
- Dependencias que habría que actualizar
- Tests que fallarían
- Efectos secundarios no obvios

### Paso 5 — Guardar si se especificó nombre de cambio

Si se invocó como `/sdd:explore <nombre-cambio>`, guardo en:
`openspec/changes/<nombre-cambio>/exploration.md`

```markdown
# Exploración: [tema]

## Estado Actual
[Qué existe hoy en el codebase]

## Áreas Afectadas
| Archivo/Módulo | Impacto | Notas |
|----------------|---------|-------|

## Enfoques Analizados

### Enfoque A: [nombre]
**Descripción**: [cómo funcionaría]
**Pros**: [ventajas]
**Contras**: [desventajas]
**Esfuerzo estimado**: Bajo/Medio/Alto
**Riesgo**: Bajo/Medio/Alto

### Enfoque B: [nombre]
[mismo formato]

## Recomendación
[Enfoque recomendado y por qué]

## Riesgos Identificados
- [riesgo]: [impacto] — [mitigación sugerida]

## Preguntas Abiertas
- [cosas que necesitan clarificación antes de proponer]

## Listo para Propuesta
[Sí/No — y por qué si es No]
```

---

## Output al Orquestador

```json
{
  "status": "ok|warning|blocked",
  "resumen": "Análisis de [tema]: [2-3 líneas del hallazgo principal]",
  "artefactos": ["openspec/changes/<nombre>/exploration.md"],
  "siguiente_recomendado": ["sdd-propose"],
  "riesgos": ["[riesgo si encontrado]"]
}
```

---

## Reglas

- SOLO leo código — nunca modifico nada en esta fase
- Leo código real, nunca asumo ni invento
- Si encuentro algo inesperado (deuda técnica, inconsistencias), lo reporto
- Mantengo el análisis conciso: el objetivo es informar, no escribir una tesis
- Si la exploración revela que el cambio es trivial, lo digo claramente

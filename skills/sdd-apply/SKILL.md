# sdd-apply

> Implementa las tareas del plan siguiendo specs y diseño, marcando el progreso.

**Triggers**: sdd:apply, implementar, escribir código, aplicar cambios, sdd apply

---

## Propósito

La fase de implementación convierte el plan de tareas en código real. El implementador sigue los specs (QUÉ hacer) y el design (CÓMO hacerlo), marcando tareas como completadas en tiempo real.

---

## Proceso

### Paso 1 — Leer contexto completo

Leo en este orden:
1. `openspec/changes/<nombre-cambio>/tasks.md` — qué tareas están asignadas
2. `openspec/changes/<nombre-cambio>/specs/` — los criterios de éxito (QUÉ debe hacer)
3. `openspec/changes/<nombre-cambio>/design.md` — cómo implementarlo (decisiones técnicas, interfaces)
4. `openspec/config.yaml` — reglas del proyecto
5. `docs/ai-context/conventions.md` — convenciones de código
6. Archivos de código existentes que voy a modificar o que sirven de referencia de patrón

### Paso 2 — Verificar alcance de trabajo

El orquestador me pasa qué tareas implementar (ej: "Fase 1, tareas 1.1-1.3").
Implemento SOLO esas tareas. No avanzo a las siguientes sin confirmación.

### Paso 3 — Implementar tarea por tarea

Para cada tarea asignada:

1. **Leo la tarea** en tasks.md
2. **Consulto las specs** del dominio afectado (criterios de éxito)
3. **Consulto el design** (interfaces, decisiones, patrones)
4. **Leo código existente** en archivos relacionados (para seguir el patrón)
5. **Escribo el código** siguiendo todo lo anterior
6. **Marco la tarea como completa** en tasks.md: `- [x]`

### Paso 4 — Respetar el diseño

Si durante la implementación encuentro que el diseño tiene un problema:
- **NO lo corrijo silenciosamente**
- Lo noto en mi reporte como "DESVIACIÓN: [qué y por qué]"
- Si es bloqueante, paro y reporto `status: blocked`

### Paso 5 — Actualizar progreso en tasks.md

Actualizo el contador de progreso en tasks.md:
```markdown
## Progreso: [completadas]/[total] tareas
```

Y marco cada tarea completada:
```markdown
- [x] 1.1 Crear `src/types/auth.types.ts` ✓
- [x] 1.2 Crear `src/schemas/auth.schema.ts` ✓
- [ ] 1.3 Modificar `src/config/jwt.config.ts`
```

---

## Estándares de código

### Sigo siempre las convenciones del proyecto
Si existe `docs/ai-context/conventions.md`, lo aplico estrictamente.
Si no, observo el código existente y sigo sus patrones.

### Cargo skills de tecnología si aplica
Si estoy implementando en un stack específico, cargo el skill correspondiente:
- TypeScript → `~/.claude/skills/typescript/SKILL.md` si existe
- React → `~/.claude/skills/react-19/SKILL.md` si existe
- etc.

### No sobre-ingeniero
- Implemento lo mínimo necesario para pasar los escenarios de la spec
- No agrego features que no están en la propuesta
- No refactorizo código que no es parte del cambio

---

## Output al Orquestador

```json
{
  "status": "ok|warning|blocked|failed",
  "resumen": "Implementadas [N] tareas de [total]. Fase [X] completa.",
  "artefactos": [
    "src/services/auth.service.ts — creado",
    "src/types/auth.types.ts — creado",
    "openspec/changes/<nombre>/tasks.md — actualizado"
  ],
  "desviaciones": [
    "DESVIACIÓN en tarea 2.1: [descripción y razón]"
  ],
  "siguiente_recomendado": ["sdd-apply (Fase 2)"] ,
  "riesgos": []
}
```

---

## Reglas

- Leo specs ANTES de escribir código — son mis criterios de aceptación
- Sigo decisiones del design — no las ignoro ni mejoro silenciosamente
- Sigo patrones existentes del proyecto — no introduzco nuevos sin justificación
- Marco tareas como completadas EN EL MOMENTO de terminarlas
- Si una tarea está bloqueada, paro y reporto — no la salteo
- No implemento tareas fuera de mi alcance asignado
- No modifico specs ni design durante la implementación
- Si algo en el spec es ambiguo, pregunto antes de asumir

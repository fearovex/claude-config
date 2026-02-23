# sdd-archive

> Sincroniza las delta specs a las specs maestras y archiva el cambio completado.

**Triggers**: sdd:archive, archivar cambio, finalizar ciclo sdd, cerrar cambio, sdd archive

---

## Propósito

El archivo es el **paso final** del ciclo SDD. Integra los aprendizajes del cambio en las specs maestras (fuente de verdad permanente) y mueve el cambio al historial. Es irreversible — confirmo con el usuario antes de ejecutar.

---

## Ciclo de Vida de las Specs

```
1. openspec/specs/ describe el comportamiento ACTUAL del sistema
2. Un cambio propone modificaciones (como deltas)
3. La implementación hace los cambios reales en el código
4. El archivo FUSIONA los deltas con las specs maestras
5. openspec/specs/ ahora describe el NUEVO comportamiento
6. El próximo cambio parte de las specs actualizadas
```

---

## Proceso

### Paso 1 — Verificar que es archivable

Leo `openspec/changes/<nombre-cambio>/verify-report.md` si existe.

Si hay issues CRÍTICOS sin resolver:
```
⛔ No se puede archivar.

El reporte de verificación tiene [N] issues críticos:
- [issue 1]
- [issue 2]

Resuelve los issues y ejecuta /sdd:verify de nuevo antes de archivar.
```

Si no hay reporte de verificación, lo informo y pregunto si continuar de todas formas.

### Paso 2 — Confirmar con el usuario

```
¿Confirmas archivar el cambio "[nombre-cambio]"?

Esto realizará las siguientes acciones IRREVERSIBLES:
1. Fusionar delta specs → specs maestras en openspec/specs/
2. Mover openspec/changes/[nombre]/ → openspec/changes/archive/[fecha]-[nombre]/

[PASS CON ADVERTENCIAS — las advertencias quedaron sin resolver]
[o: Verificación: PASS]

¿Continuar? [s/n]
```

### Paso 3 — Sincronizar delta specs a specs maestras

Para cada archivo de delta spec en `openspec/changes/<nombre>/specs/`:

#### Si existe spec maestra (`openspec/specs/<dominio>/spec.md`):

Aplico el delta:

**ADDED** → Agrego los requisitos nuevos al final del archivo de spec maestra
**MODIFIED** → Reemplazo el requisito existente con la nueva versión
**REMOVED** → Elimino el requisito (con comentario de auditoría)

Ejemplo de merge:
```markdown
<!-- Antes en spec maestra -->
### Requisito: Export JSON
El sistema DEBE exportar datos en formato JSON.

<!-- Después de aplicar MODIFIED desde delta -->
### Requisito: Export JSON
El sistema DEBE exportar datos en formato JSON y CSV.
*(Modificado en: 2026-02-23 por cambio "add-csv-export")*
```

**Preservo TODO lo que NO está en el delta.**

#### Si NO existe spec maestra:

Copio el archivo delta a `openspec/specs/<dominio>/spec.md` (se convierte en spec completa).

### Paso 4 — Mover a archivo

Muevo la carpeta del cambio:
```
openspec/changes/<nombre-cambio>/
→ openspec/changes/archive/YYYY-MM-DD-<nombre-cambio>/
```

Creo `openspec/changes/archive/` si no existe.

### Paso 5 — Crear nota de cierre

Creo `openspec/changes/archive/YYYY-MM-DD-<nombre>/CLOSURE.md`:

```markdown
# Cierre: [nombre-cambio]

Fecha de inicio: [fecha de proposal.md]
Fecha de cierre: [YYYY-MM-DD]

## Resumen
[Qué se hizo en una o dos líneas]

## Specs Modificadas
| Dominio | Acción | Cambio |
|---------|--------|--------|
| [dominio] | Añadido/Modificado/Creado | [descripción] |

## Archivos Modificados en el Código
[Lista de archivos principales que cambiaron]

## Decisiones Clave Tomadas
[Las decisiones de architecture.md relevantes para el futuro]

## Lecciones Aprendidas
[Si hubo desviaciones, problemas, o insights durante el ciclo]
```

### Paso 6 — Sugerir actualizar memoria

```
✅ Cambio "[nombre-cambio]" archivado correctamente.

Specs maestras actualizadas:
  - openspec/specs/auth/spec.md — 2 requisitos añadidos

Archivado en:
  - openspec/changes/archive/2026-02-23-[nombre]/

Recomendación: Ejecuta /memory:update para actualizar
docs/ai-context/ con las decisiones de este ciclo.
```

---

## Output al Orquestador

```json
{
  "status": "ok|warning|failed",
  "resumen": "Cambio [nombre] archivado. [N] specs maestras actualizadas.",
  "artefactos": [
    "openspec/specs/<dominio>/spec.md — actualizado",
    "openspec/changes/archive/YYYY-MM-DD-<nombre>/ — creado"
  ],
  "siguiente_recomendado": ["memory:update"],
  "riesgos": []
}
```

---

## Reglas

- NUNCA archivo con issues CRÍTICOS sin resolver
- SIEMPRE confirmo con el usuario antes de ejecutar (es irreversible)
- PRESERVO todo el contenido de specs maestras que no esté en el delta
- El historial de archive es INMUTABLE — nunca elimino archivos de archive/
- Si el merge es destructivo (ej: el delta elimina mucho), lo muestro explícitamente al usuario
- Si spec maestra tiene conflictos con el delta, los muestro y pregunto cómo resolver

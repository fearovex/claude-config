# project-update

> Actualiza y migra la configuración Claude de un proyecto al estado actual del user-level.

**Triggers**: project:update, actualizar config proyecto, migrar sdd, sync proyecto claude, actualizar claude proyecto

---

## Qué hace este skill

Cuando el usuario ejecuta `/project:update`, sincronizo la configuración Claude del proyecto con:
- Cambios en el user-level CLAUDE.md
- Nuevas skills disponibles en el catálogo global
- Cambios en el stack real del proyecto (nuevas deps, versiones)
- Mejoras en la estructura de memoria

---

## Casos de Uso

### Caso A — Actualizar stack en ai-context/

El proyecto tiene nuevas dependencias o versiones que no están documentadas:

1. Leo el stack actual del código (`package.json`, etc.)
2. Comparo con `docs/ai-context/stack.md`
3. Muestro diff de cambios detectados
4. Actualizo `stack.md` con las diferencias (confirmando con usuario)

### Caso B — Actualizar CLAUDE.md del proyecto

El user-level CLAUDE.md o las convenciones de SDD cambiaron:

1. Leo el `CLAUDE.md` del proyecto
2. Identifico secciones que corresponden a templates del user-level
3. Propongo actualizaciones conservando la personalización del proyecto
4. Confirmo con usuario antes de escribir

Secciones que sincronizo:
- Instrucciones de memoria (protocolo al inicio/fin de sesión)
- Comandos SDD disponibles
- Registry de skills (añado las nuevas del catálogo)

Secciones que NUNCA toco sin confirmación explícita:
- Stack del proyecto
- Arquitectura documentada
- Convenciones específicas del equipo
- Known issues

### Caso C — Agregar archivos de memoria faltantes

Si `docs/ai-context/` existe pero le faltan archivos:

1. Detecto qué archivos faltan
2. Genero solo los que faltan, leyendo el código real
3. No modifico los existentes

### Caso D — Migrar estructura antigua

Si el proyecto tiene una estructura de memoria diferente (ej: AGENTS.md, memory.md, etc.):

1. Identifico la estructura existente
2. Propongo migración al nuevo formato
3. Preservo TODO el contenido existente en la migración
4. Crea estructura nueva + archiva la antigua en `docs/ai-context/legacy/`

---

## Proceso

### Paso 1 — Diagnóstico rápido

Ejecuto una auditoría interna (como `project-audit` pero sin reporte completo) para identificar qué necesita actualización.

### Paso 2 — Plan de cambios

Presento al usuario exactamente qué voy a cambiar:

```
Cambios propuestos:

ACTUALIZAR:
  - docs/ai-context/stack.md
    Motivo: Se detectaron 3 dependencias nuevas (zod 4.0, tanstack-query 5.x)

CREAR:
  - docs/ai-context/known-issues.md
    Motivo: Archivo faltante

SIN CAMBIOS:
  - CLAUDE.md (personalización del proyecto detectada)
  - docs/ai-context/architecture.md (actualizado hace 5 días)

¿Procedo? [s/n]
```

### Paso 3 — Ejecución

Aplico solo los cambios aprobados:
- Cambios de stack: actualizo sección por sección, no reescribo
- Archivos nuevos: genero con contenido real detectado
- CLAUDE.md: uso merge inteligente preservando custom content

### Paso 4 — Resumen

```
✅ Actualización completada

Cambios aplicados:
  - docs/ai-context/stack.md — actualizadas 3 dependencias
  - docs/ai-context/known-issues.md — creado

Sin cambios:
  - CLAUDE.md
  - docs/ai-context/architecture.md

Recomendación: Revisa docs/ai-context/architecture.md,
la estructura de carpetas cambió desde la última actualización.
```

---

## Reglas

- NUNCA sobreescribo sin mostrar qué cambia y pedir confirmación
- Preservo TODO el contenido existente como base, solo añado/actualizo
- Si hay conflicto entre lo existente y lo nuevo, lo muestro y pregunto
- Backup automático antes de modificar (`CLAUDE.md.bak`, etc.) si el archivo tiene más de 30 líneas
- Los archivos de `docs/ai-context/` son del equipo — los trato con respeto

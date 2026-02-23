# sdd-spec

> Escribe especificaciones delta con requisitos y escenarios Given/When/Then.

**Triggers**: sdd:spec, escribir specs, especificaciones, requisitos funcionales, sdd spec

---

## Propósito

Las specs definen el **QUÉ debe hacer el sistema** desde la perspectiva del comportamiento observable. No dicen cómo implementarlo. Son la fuente de verdad para la verificación.

**Concepto clave — Delta Specs:**
Las specs son deltas (cambios) sobre lo que ya existe, no reemplazos completos.
- Si no hay spec existente: escribo una spec completa
- Si ya hay spec: escribo ADDED/MODIFIED/REMOVED sections

---

## Proceso

### Paso 1 — Leer artefactos previos

Leo obligatoriamente:
- `openspec/changes/<nombre-cambio>/proposal.md` (el QUÉ y POR QUÉ)
- `openspec/specs/<dominio>/spec.md` si existe (spec actual del dominio)
- `docs/ai-context/architecture.md` si existe (para entender el sistema actual)

### Paso 2 — Identificar dominios afectados

De la propuesta extraigo los dominios que necesitan specs:
- Un dominio = un área funcional coherente (auth, payments, users, notifications, etc.)
- Cada dominio tiene su propio archivo de spec

### Paso 3 — Escribir delta specs

Para cada dominio afectado, creo o actualizo:
`openspec/changes/<nombre-cambio>/specs/<dominio>/spec.md`

#### Si NO hay spec existente — Spec completa:

```markdown
# Spec: [Dominio]

Cambio: [nombre-cambio]
Fecha: [YYYY-MM-DD]

## Requisitos

### Requisito: [Nombre descriptivo]
[Descripción usando keywords RFC 2119]

#### Escenario: [Nombre del caso]
- **DADO** [precondición — estado del sistema]
- **CUANDO** [acción — qué ocurre]
- **ENTONCES** [resultado observable — qué debe pasar]
- **Y** [resultado adicional si aplica]

#### Escenario: [Caso límite]
- **DADO** [...]
- **CUANDO** [...]
- **ENTONCES** [...]
```

#### Si YA existe spec — Delta:

```markdown
# Delta Spec: [Dominio]

Cambio: [nombre-cambio]
Fecha: [YYYY-MM-DD]
Base: openspec/specs/[dominio]/spec.md

## ADDED — Requisitos nuevos

### Requisito: [Nombre]
[Descripción]

#### Escenario: [Nombre]
- **DADO** [...]
- **CUANDO** [...]
- **ENTONCES** [...]

## MODIFIED — Requisitos modificados

### Requisito: [Nombre del requisito existente]
[Nueva descripción]
*(Antes: [descripción anterior])*

#### Escenario: [Nombre] *(modificado)*
- **DADO** [...]
- **CUANDO** [...]
- **ENTONCES** [...]

## REMOVED — Requisitos eliminados

### Requisito: [Nombre]
*(Razón: [por qué se elimina])*
```

### Keywords RFC 2119 (obligatorio usarlos)

| Keyword | Significado |
|---------|-------------|
| **DEBE** / **MUST** | Requisito absoluto |
| **NO DEBE** / **MUST NOT** | Prohibición absoluta |
| **DEBERÍA** / **SHOULD** | Recomendado (excepciones permitidas con justificación) |
| **PUEDE** / **MAY** | Opcional |

### Tipos de escenarios a cubrir

Para cada requisito incluyo:
1. **Happy path**: El flujo normal y exitoso
2. **Casos límite**: Valores extremos, listas vacías, máximos
3. **Casos de error**: Qué pasa cuando algo falla
4. **Casos de seguridad**: Si aplica (autenticación, autorización, permisos)

---

## Ejemplos de escenarios bien escritos

### ✅ Bien escrito
```
#### Escenario: Login exitoso con credenciales válidas
- DADO que el usuario existe con email "user@example.com" y contraseña correcta
- CUANDO envía POST /auth/login con esas credenciales
- ENTONCES recibe status 200
- Y recibe un JWT válido en el campo "token"
- Y el token expira en 24 horas

#### Escenario: Login fallido con contraseña incorrecta
- DADO que el usuario existe con email "user@example.com"
- CUANDO envía POST /auth/login con contraseña incorrecta
- ENTONCES recibe status 401
- Y el mensaje de error NO revela si el email existe o no
```

### ❌ Mal escrito (muy vago)
```
#### Escenario: El usuario puede hacer login
- DADO que hay un usuario
- CUANDO hace login
- ENTONCES funciona
```

---

## Output al Orquestador

```json
{
  "status": "ok|warning|blocked",
  "resumen": "Specs para [nombre-cambio]: [N] dominios, [M] requisitos, [K] escenarios.",
  "artefactos": [
    "openspec/changes/<nombre>/specs/<dominio1>/spec.md",
    "openspec/changes/<nombre>/specs/<dominio2>/spec.md"
  ],
  "siguiente_recomendado": ["sdd-tasks (después de sdd-design)"],
  "riesgos": []
}
```

---

## Reglas

- Las specs describen COMPORTAMIENTO OBSERVABLE, no implementación
- Cada requisito DEBE tener al menos 1 escenario (happy path mínimo)
- Los escenarios DEBEN ser testables y verificables
- NO incluyo detalles de implementación (eso es `sdd-design`)
- NO invento comportamiento — me baso en la propuesta y código existente
- Si algo es ambiguo en la propuesta, lo marco como `[Pendiente clarificación]` y lo listo en riesgos

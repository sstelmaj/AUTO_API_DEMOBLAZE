---
name: generate-spec
description: "Genera la especificación técnica ASDD (spec.md) para un feature. Usar cuando el usuario pida generar una spec, crear la especificación técnica, o documentar los requerimientos de un feature antes de implementar."
argument-hint: "<nombre-feature>"
---

# Skill: generate-spec

Genera la especificación técnica en `.github/specs/<feature>.spec.md` siguiendo el estándar ASDD.

## Proceso

1. Leer requerimiento en `.github/requirements/<feature>.md`
2. Leer el diccionario de dominio en `.github/copilot-instructions.md`
3. Explorar el código existente para no duplicar lo que ya existe
4. Aplicar la plantilla exacta que se define abajo
5. Guardar en `.github/specs/<nombre-feature-kebab-case>.spec.md`

## Plantilla obligatoria

```markdown
---
id: SPEC-001
status: DRAFT
feature: <nombre-feature>
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
author: spec-generator
version: "1.0"
related-specs: []
---

# <Nombre del Feature>

## 1. REQUERIMIENTOS

### Historias de Usuario
| ID    | Como... | Quiero... | Para... |
|-------|---------|-----------|---------|
| HU-001 | [rol] | [acción] | [beneficio] |

### Criterios de Aceptación (Gherkin)
```gherkin
Escenario: [nombre]
  Dado que [precondición]
  Cuando [acción]
  Entonces [resultado esperado]
```

### Reglas de Negocio
- RN-001: [regla]

---

## 2. DISEÑO

### Endpoints involucrados
| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| GET | /api/... | [descripción] | No |

### Modelo de datos de prueba
```json
{
  "campo": "valor_ejemplo"
}
```

### Notas de diseño
- [decisiones técnicas relevantes]

### Estrategia de datos de prueba
- **Externalización obligatoria:** los payloads de prueba deben vivir en archivos `.json` separados, nunca inline en los `.feature` files.
- **Ubicación:** `src/test/java/testdata/<método>/` — separados de los `.feature` en `features/`.
- **Campos dinámicos:** credenciales (`email`, `password`) se inyectan en runtime desde el `.feature` con `* set`. No incluir en JSON estáticos.
- **Datos sintéticos:** dominio `@mailinator.com`, contraseñas con patrón `P@ss_<Contexto>_<ID>`. NUNCA PII real.

---

## 3. LISTA DE TAREAS

### QA / Automatización
- [ ] Generar escenarios Gherkin + inventario de archivos JSON (`/gherkin-case-generator`)
- [ ] Identificar riesgos (`/risk-identifier`)
- [ ] Implementar `.feature` files Karate (`/unit-testing`)
- [ ] Generar archivos `.json` en `testdata/` (`/unit-testing`)
- [ ] Generar `pom.xml`, Maven Wrapper, `karate-config.js` y `TestRunner.java` (`/unit-testing`)
- [ ] Ejecutar suite y validar resultados (`./mvnw test`)
```

## Reglas

- `status` debe ser `DRAFT` al crear; el usuario lo cambia a `APPROVED` antes de implementar
- `id` incremental: revisar specs existentes en `.github/specs/` para no repetir
- No inventar endpoints — basarse en la documentación de la API referenciada en el requerimiento
- Si el requerimiento es ambiguo, listar preguntas antes de generar la spec

---
name: gherkin-case-generator
description: "Mapea flujos críticos, genera escenarios Gherkin y datos de prueba desde la spec. Para proyectos Karate DSL, genera también el formato compatible con .feature files. Output en docs/output/qa/."
argument-hint: "<nombre-feature>"
---

# Gherkin Case Generator

## Proceso
1. Lee spec: `.github/specs/<feature>.spec.md` — criterios de aceptación y reglas de negocio
2. Identifica flujos críticos (happy paths + error paths + edge cases)
3. Genera escenario Gherkin por cada criterio
4. Define datos de prueba sintéticos por escenario
5. **Genera inventario de archivos JSON** — lista los archivos `.json` que `/unit-testing` debe crear en `testdata/`
6. Guarda en `docs/output/qa/<feature>-gherkin.md`

## Flujos críticos — identificar primero
| Tipo | Impacto | Incluir en |
|------|---------|-----------|
| Happy path principal | Alto | `@smoke @critico` |
| Validación de entrada | Medio | `@error-path` |
| Autorización / auth | Alto | `@smoke @seguridad` |
| Caso borde | Variable | `@edge-case` |

## Formato Gherkin

```gherkin
#language: es
Característica: [funcionalidad en lenguaje de negocio]

  @happy-path @critico
  Escenario: [flujo exitoso]
    Dado que [precondición de negocio]
    Cuando [acción del usuario]
    Entonces [resultado verificable]

  @error-path
  Escenario: [error esperado]
    Dado que [precondición]
    Cuando [acción inválida]
    Entonces [mensaje de error apropiado]
    Y [la operación NO se realiza]

  @edge-case
  Esquema del escenario: Validar <campo>
    Dado que el usuario ingresa "<valor>"
    Cuando intenta guardar
    Entonces el sistema muestra "<resultado>"
    Ejemplos:
      | valor | resultado              |
      | ""    | "Campo requerido"      |
      | "x"   | "Mínimo 3 caracteres"  |
```

## Datos de prueba — incluir en el documento
| Escenario | Campo | Válido | Inválido | Borde |
|-----------|-------|--------|----------|-------|
| [nombre]  | [campo] | [valor ok] | [valor ko] | [límite] |

## Inventario de archivos JSON — obligatorio para Karate

Cuando el contexto es Karate DSL, generar una tabla con los archivos `.json` que el skill `/unit-testing` debe crear en `src/test/java/testdata/`. Esta tabla es el contrato de entrega de datos.

```markdown
### Archivos de datos de prueba (`testdata/`)

| Archivo | Ruta en testdata/ | Escenario | Tipo | Campos dinámicos |
|---------|-------------------|-----------|------|------------------|
| `create_account_valid.json` | `testdata/post/` | F-04: Crear cuenta válida | happy-path | `email`, `password` |
| `create_account_duplicate.json` | `testdata/post/` | F-05: Email duplicado (1er intento) | setup | — |
| `create_account_duplicate_retry.json` | `testdata/post/` | F-05: Email duplicado (2do intento) | error-path | — |
| `create_account_no_email.json` | `testdata/post/` | F-06: Sin campo email | edge-case | — |
| `create_account_for_update.json` | `testdata/put/` | F-07: Setup para actualizar | setup | `email`, `password` |
| `update_account_valid.json` | `testdata/put/` | F-07: Actualizar cuenta | happy-path | `email`, `password` |
| `update_account_bad_password.json` | `testdata/put/` | F-08: Credenciales incorrectas | error-path | — |
| `create_account_for_delete.json` | `testdata/delete/` | F-10: Setup para eliminar | setup | `email`, `password` |
| `delete_account_bad_password.json` | `testdata/delete/` | F-11: Credenciales incorrectas | error-path | — |
```

**Convención de nombrado:**
- Payload directo: `<acción>_<variante>.json`
- Precondición/setup: `create_account_for_<operación>.json`
- Error path: `<acción>_<tipo_error>.json`

**Campos dinámicos:** campos que el `.feature` inyecta con `* set payload.<campo> = <variable>` después del `read()`. No incluirlos en el JSON estático.

## Formato Karate (para pruebas API automatizadas)

Cuando el contexto es Karate DSL, generar también escenarios en sintaxis Karate como referencia para `/unit-testing`:

```gherkin
@<tag-http>
Feature: <descripción del endpoint en lenguaje de negocio>

  Background:
    * url baseUrl

  @smoke @happy-path
  Scenario: <flujo exitoso>
    Given path '<ruta>'
    When method <get|post|put|delete>
    Then status 200
    And match response.responseCode == '200'

  @error-path
  Scenario: <flujo de error>
    Given path '<ruta>'
    And param email = 'no-existe@test.com'
    When method <get|post|put|delete>
    Then status 200
    And match response.responseCode == '404'
```

Output:
- `docs/output/qa/<feature>-gherkin.md` — documentación con escenarios en español + inventario de archivos JSON
- La sección Karate en el doc sirve como referencia directa para `/unit-testing`
- La tabla de archivos JSON es el contrato que `/unit-testing` usa para generar los `.json` en `testdata/`

## Reglas
- Lenguaje de negocio — sin rutas API ni IDs técnicos en el Gherkin documental
- Datos siempre sintéticos — NUNCA datos de producción
- Mínimo por HU: 1 happy path + 1 error + 1 edge case
- Para APIs REST con Karate: keywords en inglés (`Given`, `When`, `Then`, `And`)

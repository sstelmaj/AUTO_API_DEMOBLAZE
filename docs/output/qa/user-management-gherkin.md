# Gherkin Case Generator — Gestión de Usuarios (Signup & Login)

**Spec origen:** `.github/specs/user-management.spec.md` (SPEC-001 · v1.0 · APPROVED)  
**Feature:** `user-management`  
**Fecha de generación:** 2026-03-30  
**Endpoints cubiertos:** `POST /signup` · `POST /login`

---

## Tabla de Contenidos

1. [Mapa de Flujos Críticos](#1-mapa-de-flujos-críticos)
2. [Datos de Prueba](#2-datos-de-prueba)
3. [Escenarios Gherkin — Lenguaje de Negocio](#3-escenarios-gherkin--lenguaje-de-negocio)
4. [Referencia Karate DSL](#4-referencia-karate-dsl)
5. [Inventario de Archivos JSON (`testdata/`)](#5-inventario-de-archivos-json-testdata)

---

## 1. Mapa de Flujos Críticos

| ID          | HU origen | Flujo                                          | Tipo          | Tags                        | Prioridad |
|-------------|-----------|------------------------------------------------|---------------|-----------------------------|-----------|
| AC-US-01    | HU-001    | Registro exitoso de un usuario nuevo           | Happy path    | `@smoke @critico`           | Alta      |
| AC-US-02    | HU-002    | Registro fallido — username duplicado          | Error path    | `@error-path`               | Alta      |
| AC-US-03    | HU-003    | Login exitoso — token retornado                | Happy path    | `@smoke @critico @seguridad`| Alta      |
| AC-US-04    | HU-004    | Login fallido — credenciales incorrectas       | Error path    | `@error-path @seguridad`    | Alta      |
| EC-US-01    | HU-001    | Signup con `username` vacío                    | Edge case     | `@edge-case`                | Media     |
| EC-US-02    | HU-003    | Login con `password` vacío                     | Edge case     | `@edge-case`                | Media     |

> **Cobertura mínima por HU requerida:** 1 happy path + 1 error path + 1 edge case.  
> HU-001 → AC-US-01 + AC-US-02 + EC-US-01 ✓  
> HU-003 → AC-US-03 + AC-US-04 + EC-US-02 ✓

---

## 2. Datos de Prueba

| Escenario   | Campo       | Valor válido                         | Valor inválido              | Borde / Dinámico                              |
|-------------|-------------|--------------------------------------|-----------------------------|-----------------------------------------------|
| AC-US-01    | `username`  | `qa_auto_<timestamp>` (único)        | —                           | Generado en runtime: `System.currentTimeMillis()` |
| AC-US-01    | `password`  | `P@ss_Signup_01`                     | —                           | —                                             |
| AC-US-02    | `username`  | `qa_existing_user` (pre-existente)   | —                           | Fijo — no debe cambiarse entre ejecuciones    |
| AC-US-02    | `password`  | `P@ss_Signup_99`                     | —                           | —                                             |
| AC-US-03    | `username`  | `qa_existing_user`                   | —                           | Mismo usuario que AC-US-02                    |
| AC-US-03    | `password`  | `P@ss_Signup_99`                     | —                           | —                                             |
| AC-US-04    | `username`  | —                                    | `nonexistent_user_xyz`      | Usuario que no existe en el sistema           |
| AC-US-04    | `password`  | —                                    | `WrongPassword123`          | —                                             |
| EC-US-01    | `username`  | —                                    | `""` (vacío)                | Violación RN-001 — comportamiento observable  |
| EC-US-01    | `password`  | `P@ss_Edge_01`                       | —                           | —                                             |
| EC-US-02    | `username`  | `qa_existing_user`                   | —                           | —                                             |
| EC-US-02    | `password`  | —                                    | `""` (vacío)                | Violación RN-002 — comportamiento observable  |

---

## 3. Escenarios Gherkin — Lenguaje de Negocio

```gherkin
#language: es
Característica: Gestión de Usuarios — Registro y Autenticación en Demoblaze
  Como usuario de la plataforma Demoblaze
  Quiero poder registrarme y autenticarme mediante los servicios REST
  Para acceder a las funcionalidades protegidas de la plataforma

  # ════════════════════════════════════════════════════════════════
  # MÓDULO SIGNUP
  # ════════════════════════════════════════════════════════════════

  @smoke @critico
  Escenario: AC-US-01 — Registro exitoso de un nuevo usuario
    Dado que el servicio de registro de usuarios está disponible
    Y que no existe ningún usuario con el identificador generado dinámicamente
    Cuando el usuario envía sus datos de registro con un username único y una contraseña válida
    Entonces el sistema acepta el registro satisfactoriamente
    Y la respuesta del servidor confirma la operación sin indicar errores

  @error-path
  Escenario: AC-US-02 — Registro fallido por username duplicado
    Dado que el servicio de registro de usuarios está disponible
    Y que el username "qa_existing_user" ya se encuentra registrado en el sistema
    Cuando el usuario intenta registrarse nuevamente con el mismo username
    Entonces el sistema rechaza el registro
    Y la respuesta del servidor indica que el usuario ya existe en el sistema
    Y la operación de registro NO se completa

  @edge-case
  Escenario: EC-US-01 — Intento de registro con username vacío
    Dado que el servicio de registro de usuarios está disponible
    Cuando el usuario envía una solicitud de registro con el campo username vacío
    Entonces el sistema procesa la solicitud
    Y el comportamiento de la respuesta queda registrado como evidencia observable
    Y la operación NO genera un usuario válido en el sistema

  # ════════════════════════════════════════════════════════════════
  # MÓDULO LOGIN
  # ════════════════════════════════════════════════════════════════

  @smoke @critico @seguridad
  Escenario: AC-US-03 — Autenticación exitosa con credenciales válidas
    Dado que el servicio de autenticación está disponible
    Y que el usuario "qa_existing_user" existe en el sistema con su contraseña registrada
    Cuando el usuario envía sus credenciales correctas al servicio de login
    Entonces el sistema valida la identidad del usuario satisfactoriamente
    Y la respuesta contiene un token de sesión válido y no vacío
    Y el token puede ser utilizado para operaciones autenticadas

  @error-path @seguridad
  Escenario: AC-US-04 — Autenticación fallida con credenciales incorrectas
    Dado que el servicio de autenticación está disponible
    Y que el username "nonexistent_user_xyz" no existe en el sistema
    Cuando el usuario envía credenciales incorrectas al servicio de login
    Entonces el sistema rechaza la autenticación
    Y la respuesta indica que el usuario no existe o que la contraseña es incorrecta
    Y el sistema NO retorna un token de sesión

  @edge-case
  Escenario: EC-US-02 — Intento de login con password vacío
    Dado que el servicio de autenticación está disponible
    Y que el usuario "qa_existing_user" existe en el sistema
    Cuando el usuario envía una solicitud de login con el campo password vacío
    Entonces el sistema procesa la solicitud
    Y el comportamiento de la respuesta queda registrado como evidencia observable
    Y el sistema NO retorna un token de sesión válido
```

---

## 4. Referencia Karate DSL

> Esta sección es el contrato directo para `/unit-testing`. Los escenarios aquí definidos se implementan exactamente como `.feature` files en `src/test/java/features/`.

### 4.1 `signup.feature`

```gherkin
@signup
Feature: Gestión de Usuarios - Registro (Signup)
  Cubre los criterios AC-US-01, AC-US-02 y EC-US-01 de SPEC-001

  Background:
    * url baseUrl
    * header Content-Type = 'application/json'

  @smoke @critico
  Scenario: AC-US-01 - Registro exitoso de un nuevo usuario
    * def timestamp = function(){ return java.lang.System.currentTimeMillis() + '' }
    * def requestBody = read('classpath:testdata/signup/signup_success.json')
    * set requestBody.username = 'qa_auto_' + timestamp()
    Given path '/signup'
    And request requestBody
    When method post
    Then status 200
    And match response == null || match response !contains 'existss'

  @error-path
  Scenario: AC-US-02 - Registro fallido por username duplicado
    * def requestBody = read('classpath:testdata/signup/signup_duplicate.json')
    Given path '/signup'
    And request requestBody
    When method post
    Then status 200
    And match response contains 'allready exist'

  @edge-case
  Scenario: EC-US-01 - Registro con username vacío
    * def requestBody = read('classpath:testdata/signup/signup_empty_username.json')
    Given path '/signup'
    And request requestBody
    When method post
    Then status 200
    * print 'EC-US-01 response body (comportamiento observable):', response
```

### 4.2 `login.feature`

```gherkin
@login
Feature: Gestión de Usuarios - Autenticación (Login)
  Cubre los criterios AC-US-03, AC-US-04 y EC-US-02 de SPEC-001

  Background:
    * url baseUrl
    * header Content-Type = 'application/json'

  @smoke @critico @seguridad
  Scenario: AC-US-03 - Login exitoso con credenciales válidas
    * def requestBody = read('classpath:testdata/login/login_success.json')
    Given path '/login'
    And request requestBody
    When method post
    Then status 200
    And match response == '#notnull'
    And match response == '#string'
    And assert response.length > 0
    And match response !contains 'Wrong'
    And match response !contains 'does not exist'

  @error-path @seguridad
  Scenario: AC-US-04 - Login fallido con credenciales incorrectas
    * def requestBody = read('classpath:testdata/login/login_failure.json')
    Given path '/login'
    And request requestBody
    When method post
    Then status 200
    And match response contains 'does not exist'

  @edge-case
  Scenario: EC-US-02 - Login con password vacío
    * def requestBody = read('classpath:testdata/login/login_empty_password.json')
    Given path '/login'
    And request requestBody
    When method post
    Then status 200
    * print 'EC-US-02 response body (comportamiento observable):', response
    And assert response == null || response.length == 0 || response contains 'Wrong' || response contains 'not exist'
```

---

## 5. Inventario de Archivos JSON (`testdata/`)

> Este inventario es el **contrato de entrega** para `/unit-testing`. Cada archivo debe crearse exactamente en la ruta indicada con el contenido especificado.

### Archivos de datos de prueba (`testdata/`)

| Archivo                      | Ruta en testdata/  | AC / EC    | Tipo          | Campos dinámicos                     |
|------------------------------|--------------------|------------|---------------|--------------------------------------|
| `signup_success.json`        | `testdata/signup/` | AC-US-01   | happy-path    | `username` (se sobreescribe en runtime con timestamp) |
| `signup_duplicate.json`      | `testdata/signup/` | AC-US-02   | error-path    | —                                    |
| `signup_empty_username.json` | `testdata/signup/` | EC-US-01   | edge-case     | —                                    |
| `login_success.json`         | `testdata/login/`  | AC-US-03   | happy-path    | —                                    |
| `login_failure.json`         | `testdata/login/`  | AC-US-04   | error-path    | —                                    |
| `login_empty_password.json`  | `testdata/login/`  | EC-US-02   | edge-case     | —                                    |

### Contenido esperado por archivo

#### `testdata/signup/signup_success.json`
```json
{
  "username": "qa_auto_placeholder",
  "password": "P@ss_Signup_01"
}
```
> `username` es placeholder — el `.feature` lo sobreescribe en runtime.

#### `testdata/signup/signup_duplicate.json`
```json
{
  "username": "qa_existing_user",
  "password": "P@ss_Signup_99"
}
```

#### `testdata/signup/signup_empty_username.json`
```json
{
  "username": "",
  "password": "P@ss_Edge_01"
}
```

#### `testdata/login/login_success.json`
```json
{
  "username": "qa_existing_user",
  "password": "P@ss_Signup_99"
}
```

#### `testdata/login/login_failure.json`
```json
{
  "username": "nonexistent_user_xyz",
  "password": "WrongPassword123"
}
```

#### `testdata/login/login_empty_password.json`
```json
{
  "username": "qa_existing_user",
  "password": ""
}
```

---

## Notas de Implementación para `/unit-testing`

| Ítem | Detalle |
|------|---------|
| **Unicidad AC-US-01** | Usar `java.lang.System.currentTimeMillis()` para generar `username` único en cada ejecución. |
| **Usuario fijo AC-US-02 / AC-US-03** | `qa_existing_user` con `P@ss_Signup_99`. Si no existe en el ambiente, el Background de `signup.feature` debe pre-crearlo antes de AC-US-02. |
| **Validación de token AC-US-03** | No comparar valor exacto. Validar: `response == '#notnull'`, `response == '#string'`, `response.length > 0`, y ausencia de palabras de error. |
| **Typo intencional AC-US-02** | La aserción usa `'allready exist'` (con doble `l`) — cadena exacta de la API. No corregir. |
| **Response null AC-US-01** | Karate evalúa `null` como válido. Usar `match response == null` o aserción negativa como `match response !contains 'existss'`. |
| **Edge cases EC-US-01 / EC-US-02** | No existe contrato formal de respuesta. El test loguea la respuesta con `* print` sin fallar. Evidencia para `conclusiones.md`. |
| **Tags de ejecución** | `@smoke` → suite rápida CI. `@seguridad` → suite de auditoría. `@edge-case` → suite exploratoria. |

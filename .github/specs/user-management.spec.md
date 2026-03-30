---
id: SPEC-001
status: DRAFT
feature: user-management
created: 2026-03-30
updated: 2026-03-30
author: spec-generator
version: "1.0"
related-specs: []
---

# Gestión de Usuarios — Signup & Login

## 1. REQUERIMIENTOS

### Historias de Usuario

| ID     | Como...                   | Quiero...                                                             | Para...                                                          |
|--------|---------------------------|-----------------------------------------------------------------------|------------------------------------------------------------------|
| HU-001 | Usuario no registrado     | registrarme con un `username` y `password` únicos                     | crear mi cuenta y poder acceder a la plataforma Demoblaze        |
| HU-002 | Usuario no registrado     | recibir un mensaje de error si mi `username` ya existe                | saber que debo elegir un identificador diferente                 |
| HU-003 | Usuario registrado        | autenticarme con mi `username` y `password` correctos                 | obtener un token de sesión y acceder a funcionalidades protegidas |
| HU-004 | Usuario registrado        | recibir un mensaje de error claro al ingresar credenciales incorrectas | conocer la razón del fallo y reintentar con datos válidos        |

---

### Criterios de Aceptación (Gherkin)

```gherkin
# ── AC-US-01: Registro Exitoso ──────────────────────────────────────────────
Escenario: Registro exitoso de un nuevo usuario
  Dado que el endpoint POST "https://api.demoblaze.com/signup" está disponible
  Y que el username "qa_auto_user_{{timestamp}}" NO existe en la base de datos
  Cuando se envía un POST con body { "username": "qa_auto_user_{{timestamp}}", "password": "P@ss_Signup_01" }
  Entonces el código de estado HTTP es 200
  Y el cuerpo de la respuesta es null o no contiene la cadena "existss"

# ── AC-US-02: Registro Fallido — Usuario Duplicado ──────────────────────────
Escenario: Registro fallido por username duplicado
  Dado que el endpoint POST "https://api.demoblaze.com/signup" está disponible
  Y que el username "qa_existing_user" YA existe en la base de datos
  Cuando se envía un POST con body { "username": "qa_existing_user", "password": "P@ss_Signup_99" }
  Entonces el código de estado HTTP es 200
  Y el cuerpo de la respuesta contiene exactamente "This user allready exist."

# ── AC-US-03: Autenticación Exitosa ──────────────────────────────────────────
Escenario: Login exitoso con credenciales válidas
  Dado que el endpoint POST "https://api.demoblaze.com/login" está disponible
  Y que el usuario "qa_existing_user" con password "P@ss_Signup_99" existe en la base de datos
  Cuando se envía un POST con body { "username": "qa_existing_user", "password": "P@ss_Signup_99" }
  Entonces el código de estado HTTP es 200
  Y el cuerpo de la respuesta es una cadena de texto no vacía (token de sesión)
  Y el token no contiene las cadenas "Wrong" ni "does not exist"

# ── AC-US-04: Autenticación Fallida ──────────────────────────────────────────
Escenario: Login fallido con credenciales incorrectas
  Dado que el endpoint POST "https://api.demoblaze.com/login" está disponible
  Y que el username "nonexistent_user_xyz" NO existe en la base de datos
  Cuando se envía un POST con body { "username": "nonexistent_user_xyz", "password": "WrongPassword123" }
  Entonces el código de estado HTTP es 200
  Y el cuerpo de la respuesta contiene "User does not exist." o "Wrong password."
  Y el cuerpo de la respuesta NO es un token válido (string alfanumérico sin espacios y de longitud > 30)
```

---

### Reglas de Negocio

- **RN-001:** El campo `username` es obligatorio en Signup y Login. Su ausencia o valor vacío constituye un error de validación.
- **RN-002:** El campo `password` es obligatorio en Signup y Login. Su ausencia o valor vacío constituye un error de validación.
- **RN-003:** El `username` debe ser único en el sistema. Un segundo Signup con el mismo `username` debe ser rechazado con el mensaje `"This user allready exist."` (typo intencional de la API — esta cadena exacta debe usarse en las aserciones).
- **RN-004:** La API retorna siempre HTTP `200 OK` en el transporte. La discriminación éxito/fallo se realiza exclusivamente inspeccionando el **cuerpo de la respuesta (Response Body)**.
- **RN-005:** Un Login exitoso retorna un token de sesión como string no vacío. Un Login fallido retorna el mensaje `"User does not exist."` o `"Wrong password."`.
- **RN-006:** El Response Body de un Signup exitoso es `null`. Este valor es válido y el test NO debe fallar por ello.
- **RN-007:** Los payloads de prueba NUNCA deben contener datos PII reales. Se usan datos sintéticos con patrón `P@ss_<Contexto>_<ID>`.

---

## 2. DISEÑO

### Endpoints involucrados

| Método | Endpoint                               | Descripción                                       | Auth requerida |
|--------|----------------------------------------|---------------------------------------------------|----------------|
| `POST` | `https://api.demoblaze.com/signup`     | Registra un nuevo usuario en el sistema           | No             |
| `POST` | `https://api.demoblaze.com/login`      | Autentica un usuario y retorna un token de sesión | No             |

**URL Base (karate-config.js):**
```javascript
var baseUrl = 'https://api.demoblaze.com';
```

**Headers comunes (Background de cada .feature):**
```
Content-Type: application/json
```

---

### Modelo de datos de prueba

#### Signup — Usuario Nuevo (AC-US-01)
> Archivo: `src/test/java/testdata/signup/signup_success.json`

```json
{
  "username": "qa_auto_user_dynamic",
  "password": "P@ss_Signup_01"
}
```
> **Nota de implementación:** el campo `username` debe ser sobreescrito en runtime desde el `.feature` con un valor dinámico (timestamp) para garantizar unicidad en cada ejecución. Usar `* set requestBody.username = 'qa_auto_' + karate.get('timestamp')`.

#### Signup — Usuario Duplicado (AC-US-02)
> Archivo: `src/test/java/testdata/signup/signup_duplicate.json`

```json
{
  "username": "qa_existing_user",
  "password": "P@ss_Signup_99"
}
```

#### Login — Credenciales Válidas (AC-US-03)
> Archivo: `src/test/java/testdata/login/login_success.json`

```json
{
  "username": "qa_existing_user",
  "password": "P@ss_Signup_99"
}
```

#### Login — Credenciales Inválidas (AC-US-04)
> Archivo: `src/test/java/testdata/login/login_failure.json`

```json
{
  "username": "nonexistent_user_xyz",
  "password": "WrongPassword123"
}
```

---

### Respuestas esperadas por escenario

| ID       | HTTP Status | Response Body esperado                              | Tipo       |
|----------|-------------|-----------------------------------------------------|------------|
| AC-US-01 | `200`       | `null`                                              | `null`     |
| AC-US-02 | `200`       | `"This user allready exist."`                       | `string`   |
| AC-US-03 | `200`       | Token JWT/string dinámico, no vacío                 | `string`   |
| AC-US-04 | `200`       | `"User does not exist."` o `"Wrong password."`      | `string`   |

---

### Notas de diseño

- **RN-004 implica doble aserción:** todo escenario valida `status == 200` (transporte) Y el contenido del body (lógica de negocio). Las aserciones de negocio van en la sección `Then` y son obligatorias.
- **Token dinámico (AC-US-03):** no se compara el valor exacto del token. Se valida que `response` sea un string con `length > 0` y que no contenga palabras de error.
- **Unicidad en Signup (AC-US-01):** el `username` debe incluir un componente temporal (`karate.get('timestamp')` o `java.lang.System.currentTimeMillis()`) para evitar colisiones entre ejecuciones consecutivas.
- **Usuario fijo para duplicidad y login (AC-US-02, AC-US-03):** se usa el usuario `qa_existing_user` pre-existente. Si no existe, se debe pre-crear en un `Background` o `@BeforeAll` usando el endpoint de Signup.
- **No hay endpoint de DELETE:** no es posible limpiar usuarios post-prueba. Los tests deben diseñarse para ser idempotentes usando usuarios fijos para los escenarios negativos y timestamps para los positivos.

---

### Estrategia de datos de prueba

- **Externalización obligatoria:** los payloads de prueba deben vivir en archivos `.json` separados, nunca inline en los `.feature` files.
- **Ubicación:**
  - `src/test/java/testdata/signup/` — payloads para `signup.feature`
  - `src/test/java/testdata/login/` — payloads para `login.feature`
- **Campos dinámicos:** el `username` en AC-US-01 se inyecta en runtime desde el `.feature` con `* set`. No incluir valores dinámicos en los JSON estáticos.
- **Datos sintéticos:** usernames con prefijo `qa_`, contraseñas con patrón `P@ss_<Contexto>_<ID>`. NUNCA datos PII reales.
- **Un archivo JSON por escenario:** `signup_success.json`, `signup_duplicate.json`, `login_success.json`, `login_failure.json`.

---

### Inventario de archivos del proyecto

| Archivo                                              | Responsabilidad                                              |
|------------------------------------------------------|--------------------------------------------------------------|
| `src/test/java/features/signup.feature`              | Escenarios Gherkin de Signup (AC-US-01, AC-US-02)            |
| `src/test/java/features/login.feature`               | Escenarios Gherkin de Login (AC-US-03, AC-US-04)             |
| `src/test/java/testdata/signup/signup_success.json`  | Payload para registro exitoso                                |
| `src/test/java/testdata/signup/signup_duplicate.json`| Payload para registro duplicado                              |
| `src/test/java/testdata/login/login_success.json`    | Payload para login exitoso                                   |
| `src/test/java/testdata/login/login_failure.json`    | Payload para login fallido                                   |
| `src/test/java/karate-config.js`                     | Config global: URL base, variables de entorno                |
| `src/test/java/TestRunner.java`                      | JUnit 4 runner — orquesta la ejecución de la suite           |
| `pom.xml`                                            | Dependencias Maven: karate-junit4, maven-surefire-plugin     |
| `mvnw` / `mvnw.cmd`                                  | Maven Wrapper para ejecución sin Maven instalado globalmente  |
| `README.md`                                          | Pre-requisitos, comandos de ejecución, estructura del proyecto|
| `conclusiones.md`                                    | Trazabilidad de hallazgos, resultados y lecciones aprendidas |

---

## 3. LISTA DE TAREAS

### QA / Automatización

- [ ] Generar escenarios Gherkin + inventario de archivos JSON (`/gherkin-case-generator`)
- [ ] Identificar riesgos (`/risk-identifier`)
- [ ] Implementar `.feature` files Karate (`/unit-testing`)
- [ ] Generar archivos `.json` en `testdata/` (`/unit-testing`)
- [ ] Generar `pom.xml`, Maven Wrapper, `karate-config.js` y `TestRunner.java` (`/unit-testing`)
- [ ] Ejecutar suite y validar resultados (`./mvnw test`)
- [ ] Generar y poblar `conclusiones.md` con hallazgos de la ejecución
- [ ] Actualizar `README.md` con instrucciones de entorno y ejecución

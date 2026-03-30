# Business Requirements Document
**Módulo:** Gestión de Usuarios — Signup & Login  
**API Target:** `https://api.demoblaze.com`  
**Versión:** 1.0.0  
**Fecha:** 2026-03-30  
**Autor:** Senior QA Automation Architect  
**Estado:** APPROVED  
**Destino:** Generación automática de SPEC Karate DSL (flujo ASDD)

---

## Tabla de Contenidos

1. [Alcance](#1-alcance)
2. [Service Contracts](#2-service-contracts)
3. [Acceptance Criteria](#3-acceptance-criteria)
4. [Expected Evidence](#4-expected-evidence)
5. [Estándares de Desarrollo](#5-estándares-de-desarrollo)
6. [Estructura de Archivos](#6-estructura-de-archivos)
7. [Instrucciones de Entorno (readme.md)](#7-instrucciones-de-entorno-readmemd)
8. [Trazabilidad de Hallazgos (conclusiones.md)](#8-trazabilidad-de-hallazgos-conclusionesmd)

---

## 1. Alcance

Este documento establece los requerimientos funcionales y no funcionales para la validación automatizada de los servicios REST de **Gestión de Usuarios** de la plataforma Demoblaze. Los módulos en alcance son:

| Módulo       | Descripción                                                    | Prioridad |
|--------------|----------------------------------------------------------------|-----------|
| **Signup**   | Registro de un nuevo usuario en el sistema                     | Alta      |
| **Login**    | Autenticación de un usuario existente y obtención de token     | Alta      |

**Fuera de alcance:** administración de productos, carrito de compras, procesamiento de pagos.

---

## 2. Service Contracts

### 2.1 URL Base

```
https://api.demoblaze.com
```

### 2.2 Definición de Endpoints

| Servicio | Método HTTP | Endpoint completo                       | Content-Type       | Autenticación requerida |
|----------|-------------|------------------------------------------|--------------------|--------------------------|
| Signup   | `POST`      | `https://api.demoblaze.com/signup`       | `application/json` | No                       |
| Login    | `POST`      | `https://api.demoblaze.com/login`        | `application/json` | No                       |

### 2.3 Modelado de Datos — Request Body

Ambos servicios comparten la misma estructura de entrada. Los dos campos son **obligatorios**. La ausencia de cualquiera de ellos debe ser tratada como error de validación.

#### Estructura canónica (JSON)

```json
{
  "username": "<string: obligatorio, no vacío>",
  "password": "<string: obligatorio, no vacío>"
}
```

#### Descripción de Campos

| Campo        | Tipo     | Obligatorio | Restricciones                             | Ejemplo             |
|--------------|----------|-------------|-------------------------------------------|---------------------|
| `username`   | `string` | Sí          | No vacío. Debe ser único (aplica Signup). | `"testUser_01"`     |
| `password`   | `string` | Sí          | No vacío. No se almacena en texto plano.  | `"P@ss_Test_01"`    |

#### Payload de ejemplo — Signup (nuevo usuario)

```json
{
  "username": "qa_auto_user_01",
  "password": "P@ss_Signup_01"
}
```

#### Payload de ejemplo — Login (usuario existente)

```json
{
  "username": "qa_auto_user_01",
  "password": "P@ss_Signup_01"
}
```

### 2.4 Encabezados HTTP requeridos

```
Content-Type: application/json
```

> No se requiere token de autorización en la cabecera para estos dos endpoints. El token se **recibe** como respuesta del Login.

---

## 3. Acceptance Criteria

### Matriz de Aceptación

| ID      | Módulo  | Escenario                          | Trigger                                                      | Resultado esperado                                            | HTTP Status esperado |
|---------|---------|------------------------------------|--------------------------------------------------------------|---------------------------------------------------------------|----------------------|
| AC-US-01 | Signup  | Registro Exitoso                   | POST con `username` y `password` válidos y únicos            | Mensaje de confirmación o token de registro                   | `200 OK`             |
| AC-US-02 | Signup  | Registro Fallido – Usuario Duplicado | POST con `username` ya registrado en la base de datos       | Mensaje de error indicando que el usuario ya existe           | `200 OK` *(ver nota)*|
| AC-US-03 | Login   | Autenticación Exitosa              | POST con credenciales válidas (usuario existente)            | Token de sesión no nulo en el cuerpo de la respuesta          | `200 OK`             |
| AC-US-04 | Login   | Autenticación Fallida              | POST con `username` inexistente o `password` incorrecta      | Mensaje `"Wrong password."` o `"User does not exist."`        | `200 OK` *(ver nota)*|

> **Nota sobre códigos HTTP:** La API de Demoblaze retorna siempre `200 OK` a nivel de transporte HTTP. La discriminación de éxito/falla se realiza inspeccionando el **cuerpo de la respuesta**. Los scripts de prueba deben validar ambos niveles: el código de transporte Y el payload.

---

### AC-US-01 — Registro Exitoso

**Objetivo:** Verificar que el sistema permite crear un usuario nuevo y retorna una confirmación.

**Pre-condición:** El `username` utilizado NO debe existir previamente en la base de datos.

**Request:**
```json
{
  "username": "qa_new_user_{{timestamp}}",
  "password": "P@ss_Signup_01"
}
```

**Criterios de validación:**
- HTTP Status Code es `200`.
- El cuerpo de la respuesta no es nulo.
- La respuesta no contiene la cadena `"existss"` (error de duplicidad de la API).

**Response Body esperado (referencia):**
```json
null
```
> La API retorna `null` como body en un registro exitoso. El test DEBE aceptar `null` como respuesta válida y NO fallar por ello.

---

### AC-US-02 — Registro Fallido (Usuario Duplicado)

**Objetivo:** Verificar que el sistema rechaza el registro cuando el `username` ya existe, retornando un mensaje de error claro.

**Pre-condición:** El `username` utilizado DEBE existir previamente en la base de datos (usuario pre-creado o reutilizado de AC-US-01).

**Request:**
```json
{
  "username": "qa_existing_user",
  "password": "P@ss_Signup_99"
}
```

**Criterios de validación:**
- HTTP Status Code es `200`.
- El cuerpo de la respuesta contiene el texto `"This user allready exist."` (sic — error tipográfico intencional de la API; los tests deben usar esta cadena exacta).

**Response Body esperado:**
```json
"This user allready exist."
```

---

### AC-US-03 — Autenticación Exitosa

**Objetivo:** Verificar que el sistema autentica correctamente a un usuario existente y retorna un token de sesión válido.

**Pre-condición:** El usuario fue registrado previamente (puede depender de AC-US-01 o de un usuario fijo en `testdata`).

**Request:**
```json
{
  "username": "qa_existing_user",
  "password": "P@ss_Signup_99"
}
```

**Criterios de validación:**
- HTTP Status Code es `200`.
- El cuerpo de la respuesta es una cadena no vacía (el token).
- El token no contiene la cadena `"Wrong"` ni `"does not exist"`.

**Response Body esperado (referencia):**
```json
"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```
> El valor exacto del token es dinámico. El test debe validar que existe un valor de tipo `string` y que tiene longitud mayor a 0.

---

### AC-US-04 — Autenticación Fallida

**Objetivo:** Verificar que el sistema rechaza el login con credenciales incorrectas y retorna un mensaje de error apropiado.

**Pre-condición:** El `username` no existe en el sistema, O la `password` no corresponde al usuario.

**Request (usuario inexistente):**
```json
{
  "username": "nonexistent_user_xyz",
  "password": "WrongPassword123"
}
```

**Criterios de validación:**
- HTTP Status Code es `200`.
- El cuerpo de la respuesta contiene `"User does not exist."` O `"Wrong password."`.
- El cuerpo de la respuesta NO es un token válido (no es una cadena alfanumérica larga sin espacios).

**Response Body esperado:**
```json
"User does not exist."
```

---

## 4. Expected Evidence

Para cada caso de aceptación, el framework de automatización debe capturar y persistir la siguiente evidencia:

### 4.1 Tabla de Evidencias por Caso

| ID      | Artefacto a capturar                   | Validación mínima requerida                                | Reporte Karate |
|---------|-----------------------------------------|------------------------------------------------------------|----------------|
| AC-US-01 | HTTP Status + Response Body            | `status == 200` AND `response == null OR response != null` | Sí             |
| AC-US-02 | HTTP Status + Response Body (string)   | `status == 200` AND `response contains "allready exist"`   | Sí             |
| AC-US-03 | HTTP Status + Token (string)           | `status == 200` AND `response.length > 0`                  | Sí             |
| AC-US-04 | HTTP Status + Response Body (string)   | `status == 200` AND `response contains "does not exist"`   | Sí             |

### 4.2 Reportes Generados

El runner de Karate debe generar automáticamente los siguientes reportes en cada ejecución:

| Reporte          | Ruta                                      | Formato   | Descripción                                      |
|------------------|-------------------------------------------|-----------|--------------------------------------------------|
| Reporte HTML     | `target/karate-reports/karate-summary.html` | HTML      | Resumen visual de todos los escenarios           |
| Reporte JSON     | `target/karate-reports/*.json`            | JSON      | Datos crudos para integración CI/CD              |
| Cucumber Report  | `target/cucumber-html-reports/`           | HTML      | Reporte estilo BDD con pasos Gherkin             |

### 4.3 Convenciones de Logging

- Cada request enviado debe ser logeado (método, URL, body).
- Cada response recibida debe ser logeada (status, body).
- Las aserciones fallidas deben incluir el valor esperado vs. el valor actual.

---

## 5. Estándares de Desarrollo

### 5.1 Clean Code en Karate DSL

La implementación final DEBE cumplir los siguientes principios:

| Principio                  | Aplicación en Karate DSL                                                                                          |
|----------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Responsabilidad única**  | Cada archivo `.feature` cubre un único servicio. `signup.feature` NO mezcla lógica de login.                     |
| **No hardcoding**          | Los payloads residen en archivos `.json` externos bajo `src/test/java/testdata/`. Nunca inline en los `.feature`. |
| **DRY (Don't Repeat Yourself)** | La configuración de la URL base y headers comunes se centraliza en `karate-config.js`.                       |
| **Background para setup**  | Las configuraciones comunes al feature (URL, headers) van en la sección `Background:` del `.feature`.            |
| **Nombres descriptivos**   | Los escenarios, variables y archivos usan nombres que expresan su intención: `signup_success.json`, no `data1.json`. |
| **Eliminación de código muerto** | No dejar escenarios comentados ni features vacíos en el repositorio final.                               |

### 5.2 Estrategia de Git — Commits Atómicos

Cada commit al repositorio debe representar una **única unidad lógica de cambio**. Se prohíben los commits masivos ("god commits").

#### Convención de mensajes (Conventional Commits)

```
<tipo>(<ámbito>): <descripción corta en imperativo>
```

| Tipo       | Cuándo usarlo                                                    |
|------------|------------------------------------------------------------------|
| `feat`     | Adición de un nuevo archivo `.feature`, caso de prueba o config  |
| `fix`      | Corrección de un caso fallido o bug en la lógica del test        |
| `docs`     | Actualización de `README.md`, `conclusiones.md` u otro `.md`     |
| `refactor` | Reestructuración de archivos sin cambio de comportamiento        |
| `test`     | Ajustes a datos de prueba en `testdata/*.json`                   |
| `chore`    | Cambios en `pom.xml`, `.gitignore`, Maven Wrapper                |

#### Secuencia de commits sugerida

```
chore: initialize maven project structure with pom.xml and wrapper
chore: add karate-config.js and TestRunner.java
feat: add signup feature file with background setup
test: add testdata json files for signup scenarios
feat: add login feature file with token validation
test: add testdata json files for login scenarios
docs: add README with environment setup instructions
docs: add conclusiones.md with findings traceability
```

---

## 6. Estructura de Archivos

La separación de responsabilidades en el proyecto de automatización debe ser la siguiente:

```
AUTO_API_DEMOBLAZE/
│
├── .github/
│   ├── requirements/
│   │   └── user-management.md          ← Este documento (fuente de verdad)
│   ├── specs/
│   │   └── user-management.spec.md     ← Generado por /generate-spec
│   └── copilot-instructions.md
│
├── src/
│   └── test/
│       └── java/
│           ├── testdata/               ← Payloads JSON externalizados
│           │   ├── signup/
│           │   │   ├── signup_success.json
│           │   │   └── signup_duplicate.json
│           │   └── login/
│           │       ├── login_success.json
│           │       └── login_failure.json
│           ├── features/               ← Feature files Karate DSL
│           │   ├── signup.feature
│           │   └── login.feature
│           ├── karate-config.js        ← Configuración global (URL base, env)
│           └── TestRunner.java         ← JUnit 4 runner con configuración CI
│
├── target/                             ← Generado por Maven (ignorado en .gitignore)
│   └── karate-reports/
│
├── .gitignore
├── pom.xml                             ← Dependencias y configuración Maven
├── mvnw / mvnw.cmd                     ← Maven Wrapper
├── README.md                           ← Instrucciones de entorno y ejecución
└── conclusiones.md                     ← Trazabilidad de hallazgos y resultados
```

---

## 7. Instrucciones de Entorno (readme.md)

El archivo `README.md` del repositorio DEBE contener como mínimo las siguientes secciones:

### Secciones obligatorias del README

1. **Descripción del Proyecto:** Qué se prueba y con qué tecnología.
2. **Pre-requisitos de instalación:**
   - Java JDK 11 o superior (verificar con `java -version`)
   - Maven 3.6+ o uso del Maven Wrapper incluido (`./mvnw`)
   - Conexión a internet (la API es externa)
3. **Cómo ejecutar las pruebas:**
   ```bash
   # Usando Maven Wrapper (recomendado)
   ./mvnw test

   # Usando Maven instalado globalmente
   mvn test

   # Ejecutar un feature específico
   mvn test -Dkarate.options="--tags @signup"
   ```
4. **Cómo ver los reportes:** Ruta del reporte HTML tras la ejecución.
5. **Variables de entorno:** Si aplica, listar variables configurables en `karate-config.js`.
6. **Estructura del proyecto:** Referencia al árbol de directorios de la sección 6.

---

## 8. Trazabilidad de Hallazgos (conclusiones.md)

El archivo `conclusiones.md` DEBE generarse al finalizar el ejercicio y DEBE contener las siguientes secciones para garantizar la trazabilidad de los hallazgos:

### Secciones obligatorias de conclusiones.md

| Sección                          | Contenido esperado                                                                                                     |
|----------------------------------|------------------------------------------------------------------------------------------------------------------------|
| **Resumen Ejecutivo**            | Porcentaje de casos pasados/fallidos. Total de escenarios ejecutados.                                                  |
| **Hallazgos por Caso de Prueba** | Tabla con ID, escenario, resultado (PASS/FAIL), HTTP status obtenido vs. esperado, y evidencia (extracto del body).   |
| **Comportamientos Observados**   | Documentar comportamientos no estándar de la API (ej: siempre retorna 200, error tipográfico en mensaje de duplicidad).|
| **Riesgos Identificados**        | Lista de riesgos de calidad observados durante la ejecución (clasificación ASD: Alto/Medio/Bajo).                      |
| **Recomendaciones**              | Mejoras sugeridas para la API y para la suite de pruebas.                                                              |
| **Lecciones Aprendidas**         | Reflexión técnica sobre el uso del framework Karate DSL y el flujo ASDD.                                               |

### Plantilla de tabla de hallazgos

```markdown
| ID       | Escenario                    | Resultado | Status HTTP obtenido | Status HTTP esperado | Observación                        |
|----------|------------------------------|-----------|----------------------|----------------------|------------------------------------|
| AC-US-01 | Registro Exitoso             | PASS      | 200                  | 200                  | Response body es `null` (esperado) |
| AC-US-02 | Registro Duplicado           | PASS      | 200                  | 200                  | Mensaje con typo "allready"        |
| AC-US-03 | Login Exitoso                | PASS      | 200                  | 200                  | Token retornado correctamente      |
| AC-US-04 | Login Fallido                | PASS      | 200                  | 200                  | Mensaje "User does not exist."     |
```

---

## Glosario de Dominio

| Término     | Definición en este contexto                                      |
|-------------|------------------------------------------------------------------|
| `username`  | Identificador único del usuario en la plataforma Demoblaze       |
| `password`  | Credencial de acceso del usuario                                 |
| `token`     | Cadena de texto retornada por Login que autentica al usuario     |
| `testdata`  | Archivos JSON externos con los payloads de los escenarios        |
| `feature`   | Unidad de funcionalidad descrita en Gherkin e implementada en Karate |
| `runner`    | Clase Java (`TestRunner.java`) que orquesta la ejecución de Karate |

---

*Este documento es la única fuente de verdad para la generación de specs y scripts de automatización bajo el flujo ASDD. Cualquier cambio en los requerimientos debe reflejarse primero aquí antes de modificar specs o código.*

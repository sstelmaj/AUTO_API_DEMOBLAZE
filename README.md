# AUTO_API_DEMOBLAZE

Suite de automatización de pruebas API con **Karate DSL** para el módulo de **Gestión de Usuarios** (Signup & Login) de la plataforma [Demoblaze](https://www.demoblaze.com).

---

## Tabla de Contenidos

1. [Descripción](#descripción)
2. [Requisitos del entorno](#requisitos-del-entorno)
3. [Estructura del proyecto](#estructura-del-proyecto)
4. [Ejecución paso a paso](#ejecución-paso-a-paso)
5. [Ejecución por tags](#ejecución-por-tags)
6. [Reporte de resultados](#reporte-de-resultados)
7. [Escenarios cubiertos](#escenarios-cubiertos)

---

## Descripción

| Campo          | Detalle                                              |
|----------------|------------------------------------------------------|
| **API target** | `https://api.demoblaze.com`                          |
| **Endpoints**  | `POST /signup`, `POST /login`                        |
| **Framework**  | Karate DSL 1.4.1 + JUnit 5                           |
| **Build tool** | Maven 3.6+                                           |
| **Java**       | Java 11+                                             |
| **Spec origen**| SPEC-001 v1.0 (`.github/specs/user-management.spec.md`) |
| **Escenarios** | 6 escenarios (4 AC + 2 Edge Cases)                   |

---

## Requisitos del entorno

Antes de ejecutar la suite, verificá que tu entorno cumple con lo siguiente:

| Herramienta | Versión mínima | Verificación                   |
|-------------|----------------|--------------------------------|
| **Java JDK**| 11             | `java -version`                |
| **Maven**   | 3.6.0          | `mvn --version`                |
| **Git**     | cualquiera     | `git --version`                |
| **Red**     | —              | Acceso a `api.demoblaze.com`   |

> **Nota:** El proyecto fue desarrollado y validado con **Java 17.0.8 (Amazon Corretto)** y **Maven 3.9.14**. Java 11 es el mínimo requerido por el `pom.xml`.

---

## Estructura del proyecto

```
AUTO_API_DEMOBLAZE/
├── .github/
│   ├── requirements/user-management.md      # BRD — fuente de verdad de negocio
│   └── specs/user-management.spec.md        # SPEC-001 APPROVED — fuente técnica
├── docs/
│   └── output/qa/
│       ├── user-management-gherkin.md       # Escenarios Gherkin declarativos
│       └── risk-matrix.md                   # Matriz de riesgos ASD
├── src/
│   └── test/
│       └── java/
│           ├── karate-config.js             # Configuración global (baseUrl, SSL, timeouts)
│           ├── runners/
│           │   └── TestRunner.java          # Runner JUnit 5 con reporte consolidado
│           ├── features/
│           │   ├── signup.feature           # AC-US-01, AC-US-02, EC-US-01
│           │   ├── login.feature            # AC-US-03, AC-US-04, EC-US-02
│           │   └── helpers/
│           │       └── create_existing_user.feature  # Setup idempotente (@ignore)
│           └── testdata/
│               ├── signup/
│               │   ├── signup_success.json
│               │   ├── signup_duplicate.json
│               │   └── signup_empty_username.json
│               └── login/
│                   ├── login_success.json
│                   ├── login_failure.json
│                   └── login_empty_password.json
├── pom.xml
├── mvnw / mvnw.cmd
└── .gitignore
```

---

## Ejecución paso a paso

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/sstelmaj/AUTO_API_DEMOBLAZE.git
cd AUTO_API_DEMOBLAZE
```

### Paso 2 — Verificar el entorno

```bash
java -version
mvn --version
```

Salida esperada (ejemplo):

```
openjdk version "17.0.8" ...
Apache Maven 3.9.14 ...
```

### Paso 3 — Ejecutar la suite completa

```bash
mvn test
```

> Si preferís usar el Maven Wrapper incluido en el proyecto:
> - **Windows:** `.\mvnw.cmd test`
> - **Linux / macOS:** `./mvnw test`

### Paso 4 — Verificar resultado en consola

Al finalizar, la consola mostrará un resumen como:

```
scenarios:  3 | passed:  3 | failed:  0   ← signup.feature
scenarios:  3 | passed:  3 | failed:  0   ← login.feature
scenarios:  6 | passed:  6 | failed:  0   ← total consolidado
[INFO] BUILD SUCCESS
```

### Paso 5 — Ver el reporte HTML

Abrí el reporte consolidado en tu navegador:

```
target/karate-reports/karate-summary.html
```

Reportes individuales por feature:

```
target/karate-reports/features.signup.html
target/karate-reports/features.login.html
```

---

## Ejecución por tags

Podés ejecutar un subconjunto de escenarios usando tags de Karate:

| Tag           | Descripción                                   | Comando                                               |
|---------------|-----------------------------------------------|-------------------------------------------------------|
| `@smoke`      | Escenarios críticos de camino feliz           | `mvn test "-Dkarate.options=--tags @smoke"`           |
| `@error-path` | Escenarios de flujo de error                  | `mvn test "-Dkarate.options=--tags @error-path"`      |
| `@edge-case`  | Escenarios de borde sin contrato formal       | `mvn test "-Dkarate.options=--tags @edge-case"`       |
| `@seguridad`  | Escenarios con implicaciones de seguridad     | `mvn test "-Dkarate.options=--tags @seguridad"`       |
| `@critico`    | Escenarios críticos bloqueantes de release    | `mvn test "-Dkarate.options=--tags @critico"`         |

> **PowerShell:** el argumento `-D` debe ir dentro de una sola cadena de comillas (`"-Dkarate.options=..."`) para que el espacio no parta el argumento en dos. La sintaxis `mvn test -Dkarate.options="--tags @smoke"` falla en PowerShell.

---

## Reporte de resultados

Karate genera automáticamente los siguientes artefactos en `target/karate-reports/`:

| Archivo                       | Contenido                                                |
|-------------------------------|----------------------------------------------------------|
| `karate-summary.html`         | Reporte consolidado de todos los escenarios              |
| `karate-tags.html`            | Desglose de resultados por tag                           |
| `karate-timeline.html`        | Línea de tiempo de ejecución                             |
| `features.signup.html`        | Reporte detallado de `signup.feature`                    |
| `features.login.html`         | Reporte detallado de `login.feature`                     |
| `features.signup.json`        | Datos Cucumber JSON para integración CI/CD               |
| `features.login.json`         | Datos Cucumber JSON para integración CI/CD               |

---

## Escenarios cubiertos

| ID        | Feature  | Descripción                                             | Tags                          | Resultado |
|-----------|----------|---------------------------------------------------------|-------------------------------|-----------|
| AC-US-01  | Signup   | Registro exitoso con username único (timestamp)         | `@smoke @critico @happy-path` | ✅ PASS   |
| AC-US-02  | Signup   | Registro fallido por username duplicado                 | `@error-path`                 | ✅ PASS   |
| EC-US-01  | Signup   | Username vacío — HTTP 500 (comportamiento observable)   | `@edge-case`                  | ✅ PASS   |
| AC-US-03  | Login    | Login exitoso — token de sesión válido                  | `@smoke @critico @seguridad`  | ✅ PASS   |
| AC-US-04  | Login    | Login fallido — usuario inexistente                     | `@error-path @seguridad`      | ✅ PASS   |
| EC-US-02  | Login    | Password vacío — errorMessage observable                | `@edge-case`                  | ✅ PASS   |

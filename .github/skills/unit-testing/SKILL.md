---
name: unit-testing
description: "Genera el proyecto Karate completo: pom.xml, Maven Wrapper, karate-config.js, TestRunner.java, archivos .feature y archivos .json de datos de prueba externalizados para los 4 métodos HTTP (GET, POST, PUT, DELETE) apuntando a la API automationexercise.com. Usar cuando el usuario pida implementar, generar o crear pruebas Karate, tests API o el proyecto de automatización."
argument-hint: "<nombre-feature | all>"
---

# Skill: unit-testing — Karate DSL

Genera el proyecto de automatización completo con Karate DSL para la API automationexercise.com.

## Primer paso — cargar contexto

Lee antes de generar cualquier archivo:
```
.github/instructions/tests.instructions.md
.github/specs/<feature>.spec.md  (si existe)
.github/docs/qa-guidelines.md
```

## Artefactos a generar

### 1. `pom.xml` (raíz del proyecto)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.sofka.training</groupId>
    <artifactId>auto-api-karate</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <karate.version>1.4.1</karate.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>com.intuit.karate</groupId>
            <artifactId>karate-junit5</artifactId>
            <version>${karate.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <testResources>
            <testResource>
                <directory>src/test/java</directory>
                <excludes>
                    <exclude>**/*.java</exclude>
                </excludes>
            </testResource>
        </testResources>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.2.5</version>
                <configuration>
                    <includes>
                        <include>runners/TestRunner.java</include>
                    </includes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### 2. Maven Wrapper (ejecutar en raíz del proyecto)

```bash
mvn wrapper:wrapper
```

Esto genera `mvnw`, `mvnw.cmd` y `.mvn/wrapper/maven-wrapper.properties`.
El wrapper permite ejecutar los tests **sin tener Maven instalado** — solo requiere Java 11+.

### 3. `src/test/java/karate-config.js`

```javascript
function fn() {
  var config = {
    baseUrl: 'https://automationexercise.com',
    connectTimeout: 10000,
    readTimeout: 10000
  };
  karate.configure('ssl', true);
  karate.configure('connectTimeout', config.connectTimeout);
  karate.configure('readTimeout', config.readTimeout);
  return config;
}
```

### 4. `src/test/java/runners/TestRunner.java`

```java
package runners;

import com.intuit.karate.junit5.Karate;

class TestRunner {

    @Karate.Test
    Karate testAll() {
        return Karate.run("classpath:features").relativeTo(getClass());
    }

    @Karate.Test
    Karate testGet() {
        return Karate.run("classpath:features/get").relativeTo(getClass());
    }

    @Karate.Test
    Karate testPost() {
        return Karate.run("classpath:features/post").relativeTo(getClass());
    }

    @Karate.Test
    Karate testPut() {
        return Karate.run("classpath:features/put").relativeTo(getClass());
    }

    @Karate.Test
    Karate testDelete() {
        return Karate.run("classpath:features/delete").relativeTo(getClass());
    }
}
```

### 5. Datos de prueba externalizados — archivos `.json` en `testdata/`

> **REGLA OBLIGATORIA:** Los payloads y datos de prueba NUNCA van inline en los `.feature` files.
> Deben externalizarse en archivos `.json` dentro de `src/test/java/testdata/<método>/`.

**Estructura de carpetas para datos:**

```
src/test/java/
├── testdata/
│   ├── post/
│   │   ├── create_account_valid.json
│   │   ├── create_account_duplicate.json
│   │   └── create_account_no_email.json
│   ├── put/
│   │   ├── create_account_for_update.json    # precondición: crear cuenta antes de actualizar
│   │   ├── update_account_valid.json
│   │   └── update_account_bad_password.json
│   └── delete/
│       ├── create_account_for_delete.json    # precondición: crear cuenta antes de eliminar
│       ├── delete_account_bad_password.json
│       └── delete_account_nonexistent.json
```

**Convención de nombrado para archivos `.json`:**

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Payload directo del test | `<acción>_<variante>.json` | `create_account_valid.json` |
| Precondición / setup | `create_account_for_<operación>.json` | `create_account_for_delete.json` |
| Error path | `<acción>_<tipo_error>.json` | `update_account_bad_password.json` |
| Edge case | `<acción>_<caso_borde>.json` | `create_account_no_email.json` |

**Ejemplo de archivo `.json` de payload (POST):**

```json
{
  "name": "Test User Sofka",
  "title": "Mr",
  "birth_date": "15",
  "birth_month": "June",
  "birth_year": "1990",
  "firstname": "Test",
  "lastname": "Sofka",
  "company": "Sofka Training",
  "address1": "Calle Falsa 123",
  "address2": "",
  "country": "Colombia",
  "zipcode": "110111",
  "state": "Cundinamarca",
  "city": "Bogotá",
  "mobile_number": "3001234567"
}
```

> **Nota:** Los campos dinámicos (`email`, `password`) se inyectan en el `.feature` con `* set payload.email = testEmail` después del `read()`. NUNCA incluir credenciales estáticas en los JSON.

**Cómo usar `read()` en el `.feature`:**

```gherkin
# Leer payload desde testdata/ usando classpath
* def payload = read('classpath:testdata/post/create_account_valid.json')
* set payload.email = testEmail
* set payload.password = testPassword
Given path '/api/createAccount'
And form fields payload
When method post
```

### 6. Features — uno por operación HTTP

**Patrón de archivo `.feature`:**

```gherkin
@<tag-http>
Feature: <Descripción del endpoint en lenguaje de negocio>

  Background:
    * url baseUrl

  @smoke @happy-path
  Scenario: <Flujo exitoso>
    * def payload = read('classpath:testdata/<método>/<archivo>.json')
    Given path '<ruta-del-endpoint>'
    And form fields payload
    When method <get|post|put|delete>
    Then status <código-http-esperado>
    And match response.responseCode == <código-esperado>

  @error-path
  Scenario: <Flujo de error>
    * def payload = read('classpath:testdata/<método>/<archivo_error>.json')
    Given path '<ruta-del-endpoint>'
    And form fields payload
    When method <get|post|put|delete>
    Then status 200
    And match response.responseCode == <código-de-error>
```

> **PROHIBIDO:** Poner JSON inline en el `.feature` con `And request """{ ... }"""` para payloads complejos.
> **EXCEPCIÓN:** `And request {}` vacío es aceptable para escenarios de error simples (ej: POST a endpoint GET-only).

## Endpoints a cubrir (automationexercise.com/api_list)

| Método | Endpoint | Feature file | Data files | Tag |
|--------|----------|-------------|------------|-----|
| GET | `/api/productsList` | `features/get/get_products_list.feature` | — (sin payload) | `@get` |
| POST | `/api/createAccount` | `features/post/post_create_account.feature` | `testdata/post/*.json` | `@post` |
| PUT | `/api/updateAccount` | `features/put/put_update_account.feature` | `testdata/put/*.json` | `@put` |
| DELETE | `/api/deleteAccount` | `features/delete/delete_account.feature` | `testdata/delete/*.json` | `@delete` |

## Assertions Karate — referencias rápidas

```gherkin
# Verificar status
Then status 200

# Match exacto de un campo
And match response.responseCode == 200

# Match que contiene (lista no vacía)
And match response.products == '#notempty'

# Match tipo de dato
And match response.products[0].id == '#number'

# Match con schema
And match response ==
  """
  {
    "responseCode": '#number',
    "products": '#array'
  }
  """
```

## Comando de ejecución

```bash
./mvnw test                                          # todos los escenarios (Unix/Mac)
mvnw.cmd test                                        # todos los escenarios (Windows)
./mvnw test -Dkarate.options="--tags @smoke"         # solo tag @smoke
```

> **Requisito del entorno:** Solo se necesita **Java 11+** instalado. El Maven Wrapper descarga Maven automáticamente.

## Reglas de generación

1. Generar TODOS los 4 archivos `.feature` + `build.gradle` + `karate-config.js` + `TestRunner.java`
2. Cada `.feature` incluye mínimo: 1 happy-path (`@smoke`) + 1 error-path
3. Datos de prueba: SIEMPRE sintéticos, usar `karate.random()` para emails únicos
4. No hardcodear `baseUrl` — siempre via `karate-config.js`
5. Guardar en rutas exactas definidas en `tests.instructions.md`

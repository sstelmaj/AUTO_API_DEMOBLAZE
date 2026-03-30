---
applyTo: "src/test/**"
---

# Stack de Pruebas — Karate DSL

## Tecnologías

| Componente | Versión mínima | Notas |
|-----------|---------------|-------|
| Java | 11 | Requerido por Karate 1.4.x |
| Maven | 3.9+ | Gestión de dependencias y ejecución (vía Maven Wrapper) |
| Maven Wrapper | 3.3+ | Incluido en el repo — NO requiere Maven instalado |
| Karate | 1.4.1 | `com.intuit.karate:karate-junit5` |
| JUnit 5 | 5.9 | Runner de Karate |

## Requisitos del entorno

- **Solo se necesita Java 11+** instalado en la máquina.
- El Maven Wrapper (`mvnw` / `mvnw.cmd`) descarga Maven automáticamente en la primera ejecución.
- No se requiere ninguna otra instalación ni configuración manual.

## Estructura de carpetas

```
src/
└── test/
    └── java/
        ├── features/
        │   ├── get/
        │   │   └── get_products_list.feature
        │   ├── post/
        │   │   └── post_create_account.feature
        │   ├── put/
        │   │   └── put_update_account.feature
        │   └── delete/
        │       └── delete_account.feature
        ├── testdata/
        │   ├── post/
        │   │   ├── create_account_valid.json
        │   │   ├── create_account_duplicate.json
        │   │   └── create_account_no_email.json
        │   ├── put/
        │   │   ├── create_account_for_update.json
        │   │   ├── update_account_valid.json
        │   │   └── update_account_bad_password.json
        │   └── delete/
        │       ├── create_account_for_delete.json
        │       ├── delete_account_bad_password.json
        │       └── delete_account_nonexistent.json
        ├── karate-config.js
        └── runners/
            └── TestRunner.java
```

## Convenciones obligatorias

- Archivos `.feature`: snake_case, descripción del endpoint (`get_products_list.feature`)
- Archivos `.json` de datos: snake_case, en `testdata/<método>/` — NUNCA dentro de `features/`
- Runner: `TestRunner.java` anotado con `@Karate.Test`
- `karate-config.js`: define `baseUrl` como variable global
- Tags: `@smoke`, `@get`, `@post`, `@put`, `@delete`, `@happy-path`, `@error-path`
- Idioma de las features: inglés para keywords Karate, español en comentarios/descripción

## Convenciones de archivos `.json` (datos de prueba)

| Tipo | Patrón de nombrado | Ejemplo |
|------|--------------------|---------|
| Payload directo (happy path) | `<acción>_<variante>.json` | `create_account_valid.json` |
| Precondición / setup | `create_account_for_<operación>.json` | `create_account_for_delete.json` |
| Error path | `<acción>_<tipo_error>.json` | `update_account_bad_password.json` |
| Edge case | `<acción>_<caso_borde>.json` | `create_account_no_email.json` |

### Reglas de datos externalizados

- **Los payloads NUNCA van inline** en los `.feature` — siempre en archivos `.json` externalizados en `testdata/`.
- **Leer con classpath:** `* def payload = read('classpath:testdata/post/create_account_valid.json')`
- **Campos dinámicos** (`email`, `password`) se inyectan en el `.feature` con `* set payload.email = testEmail` después del `read()`.
- **No incluir credenciales estáticas** en archivos `.json` que correspondan a escenarios con datos dinámicos.
- **Excepción:** `And request {}` vacío es aceptable para escenarios como POST a endpoint GET-only.

## pom.xml — dependencias obligatorias

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

## Comando de ejecución

```bash
./mvnw test                                          # todos los escenarios (Unix/Mac)
mvnw.cmd test                                        # todos los escenarios (Windows)
./mvnw test -Dkarate.options="--tags @smoke"         # solo tag @smoke
```

## API bajo prueba

- Base URL: `https://automationexercise.com`
- Documentación: https://automationexercise.com/api_list
- Sin autenticación para endpoints públicos (GET productos, GET marcas)
- Autenticación requerida para: POST/PUT/DELETE de cuenta de usuario (`email` + `password` en el body)

## Reglas del código Karate

- Usar `* configure ssl = true` en `karate-config.js` para aceptar el certificado del servidor
- Assertions con `* match response ==` o `* match response contains`
- Datos de prueba sintéticos: NUNCA usar datos reales de producción
- Un `.feature` por endpoint/operación
- Separar happy-path y error-path en `Scenario` distintos dentro del mismo `.feature`
- Payloads complejos siempre externalizados en `testdata/` con `read('classpath:testdata/...')`

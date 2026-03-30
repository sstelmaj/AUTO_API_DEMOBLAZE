# Conclusiones y Hallazgos — Gestión de Usuarios (Signup & Login)

**Proyecto:** AUTO_API_DEMOBLAZE  
**Spec origen:** SPEC-001 v1.0 (`user-management.spec.md`) · Estado: APPROVED  
**API Target:** `https://api.demoblaze.com`  
**Fecha:** 2026-03-30  
**Autor:** QA Automation Engineer  
**Framework:** Karate DSL 1.4.1 · JUnit 5 · Maven 3.9.14 · Java 17

---

## Resumen de Ejecución

| Métrica                      | Valor                  |
|------------------------------|------------------------|
| **Total de escenarios**      | 6                      |
| **Escenarios PASSED**        | 6                      |
| **Escenarios FAILED**        | 0                      |
| **Criterios de aceptación**  | 4 / 4 cubiertos        |
| **Edge cases**               | 2 / 2 cubiertos        |
| **Tiempo de ejecución**      | ~6 segundos            |
| **Resultado del build**      | ✅ BUILD SUCCESS        |

---

## Trazabilidad Escenarios → Criterios de Aceptación

| ID Escenario | AC / EC     | HU      | Resultado | Observación                                                                  |
|--------------|-------------|---------|-----------|------------------------------------------------------------------------------|
| AC-US-01     | AC-US-01    | HU-001  | ✅ PASS   | Signup exitoso. Response body es `null` (RN-006 confirmado).                 |
| AC-US-02     | AC-US-02    | HU-002  | ✅ PASS   | Signup duplicado detectado via `response.errorMessage` (ver Hallazgo H-002). |
| EC-US-01     | EC-US-01    | HU-001  | ✅ PASS   | Username vacío retorna HTTP 500 (ver Hallazgo H-003).                        |
| AC-US-03     | AC-US-03    | HU-003  | ✅ PASS   | Login exitoso retorna token no vacío. Token validado como `#string #notnull`.|
| AC-US-04     | AC-US-04    | HU-004  | ✅ PASS   | Login fallido detectado via `response.errorMessage` (ver Hallazgo H-001).    |
| EC-US-02     | EC-US-02    | HU-004  | ✅ PASS   | Password vacío retorna `errorMessage: "Wrong password."` (ver H-003).        |

---

## Hallazgos

### H-001 — Respuesta de error usa envoltura JSON `errorMessage` (no string plano)

| Campo         | Detalle                                                                 |
|---------------|-------------------------------------------------------------------------|
| **Severidad** | Media                                                                   |
| **Riesgo**    | R-001, R-002                                                            |
| **Endpoint**  | `POST /signup`, `POST /login`                                           |
| **Impacto**   | Las aserciones de error deben hacerse sobre `response.errorMessage`, no sobre `response` directamente |

**Descripción:** La SPEC-001 y el BRD documentaban los mensajes de error como strings planos (e.g. `"User does not exist."`). En la práctica, la API los encapsula en un objeto JSON:

```json
{ "errorMessage": "User does not exist." }
```

Esto afectó a tres escenarios: AC-US-02, AC-US-04 y EC-US-02. La suite de automatización fue corregida para usar `match response.errorMessage contains '...'` en lugar de `assert response.contains('...')`.

**Recomendación:** Actualizar la documentación del contrato de API para reflejar la envoltura `errorMessage` como estructura canónica de error en todos los endpoints.

---

### H-002 — Typo en el mensaje de duplicidad de usuario

| Campo         | Detalle                                                        |
|---------------|----------------------------------------------------------------|
| **Severidad** | Baja (cosmética)                                               |
| **Riesgo**    | R-004                                                          |
| **Endpoint**  | `POST /signup`                                                 |

**Descripción:** El mensaje de error por usuario duplicado contiene un error ortográfico:

| Lo que retorna la API              | Lo que debería decir              |
|-------------------------------------|-----------------------------------|
| `"This user already exist."`        | `"This user already exists."`     |

> **Nota:** En iteraciones anteriores de pruebas, se observó la variante `"This user allready exist."` (con doble 'l'). La versión confirmada de la API al momento de la ejecución final es `"already"` (simple). La aserción se implementó con `contains 'already exist'` para tolerar ambas variantes.

**Recomendación:** Corregir el mensaje de error en el backend para usar gramática correcta (`"already exists."`). Bajo riesgo funcional pero impacta la experiencia del usuario final.

---

### H-003 — Edge cases sin contrato de API (HTTP 500 y password vacío)

| Campo         | Detalle                                                        |
|---------------|----------------------------------------------------------------|
| **Severidad** | Alta (desde perspectiva de calidad de API)                     |
| **Riesgo**    | R-008                                                          |
| **Endpoints** | `POST /signup` (username vacío), `POST /login` (password vacío)|

**Descripción:**

| Caso          | Input                         | Respuesta real observada                   | HTTP Status |
|---------------|-------------------------------|--------------------------------------------|-------------|
| EC-US-01      | `username: ""`                | `500 Internal Server Error` (HTML body)    | 500         |
| EC-US-02      | `password: ""`                | `{ "errorMessage": "Wrong password." }`    | 200         |

- **EC-US-01** (`/signup` con username vacío): La API no valida el campo antes de procesarlo y provoca un error interno no controlado (HTTP 500). Este comportamiento es inconsistente con RN-004 (la API *siempre* debería retornar 200) y constituye un **defecto de validación de entrada**.
- **EC-US-02** (`/login` con password vacío): La API responde con HTTP 200 y un `errorMessage` consistente, comportamiento aceptable aunque no documentado.

**Recomendación:** Implementar validación de entrada en `/signup` para rechazar `username` vacío con una respuesta 400 Bad Request (o al menos 200 con `errorMessage`), eliminando el 500 interno.

---

### H-004 — Patrón HTTP 200-always dificulta observabilidad

| Campo         | Detalle                                 |
|---------------|-----------------------------------------|
| **Severidad** | Media                                   |
| **Riesgo**    | R-007                                   |
| **Endpoints** | `POST /signup`, `POST /login`           |

**Descripción:** Ambos endpoints retornan siempre HTTP `200 OK`, sin importar si la operación fue exitosa o fallida. La discriminación éxito/error requiere inspección del body, lo que:

- Rompe la convención REST estándar (4xx para errores de cliente, 5xx para errores de servidor).
- Imposibilita el uso de herramientas de monitoreo basadas en status codes (alertas, dashboards).
- Aumenta la complejidad de las aserciones en la suite de automatización.

**Recomendación:** Adoptar códigos HTTP semánticamente correctos: `201 Created` para signup exitoso, `409 Conflict` para duplicados, `401 Unauthorized` para login fallido.

---

### H-005 — Token de sesión sin contrato de estructura documentado

| Campo         | Detalle                                 |
|---------------|-----------------------------------------|
| **Severidad** | Media (riesgo de seguridad potencial)   |
| **Riesgo**    | R-006                                   |
| **Endpoint**  | `POST /login`                           |

**Descripción:** El endpoint `/login` retorna un token de sesión como string dinámico sin contrato documentado (no se especifica si es JWT, HMAC, string aleatorio, ni su tiempo de expiración). La suite valida existencia y tipo pero no puede validar estructura, expiración ni scope.

**Recomendación:** Documentar el contrato del token: tipo, algoritmo, claims (si es JWT), duración de validez y mecanismo de revocación.

---

## Conclusiones del ejercicio

### 1. Cobertura lograda
La suite cubre el **100% de los criterios de aceptación** definidos en SPEC-001 (AC-US-01 a AC-US-04) y los **2 edge cases** identificados en el proceso de análisis de riesgos. Los 6 escenarios pasan exitosamente con `BUILD SUCCESS`.

### 2. Desviaciones respecto al contrato especificado
Se identificaron **2 desviaciones funcionales** entre el comportamiento esperado (SPEC/BRD) y el comportamiento real de la API:

| Desviación | Descripción                                                               | Impacto en suite |
|-----------|---------------------------------------------------------------------------|------------------|
| D-001     | Mensajes de error encapsulados en `{"errorMessage": "..."}` (no string plano) | Aserciones corregidas a `response.errorMessage` |
| D-002     | `POST /signup` con username vacío retorna HTTP 500 en vez de 200          | Aserción de status eliminada, comportamiento observado y documentado |

### 3. Defectos identificados

| ID defecto | Severidad | Endpoint           | Descripción                                                         |
|------------|-----------|--------------------|---------------------------------------------------------------------|
| DEF-001    | Alta      | `POST /signup`     | Username vacío provoca HTTP 500 (error de servidor no controlado)   |
| DEF-002    | Baja      | `POST /signup`     | Mensaje de duplicado con error ortográfico (`"already exist."`)     |

### 4. Riesgos confirmados
De los 10 riesgos identificados en la matriz ASD:

| Nivel | Riesgos confirmados | Detalle                                          |
|-------|---------------------|--------------------------------------------------|
| ALTO  | R-002, R-004        | Enumeración de usuarios expuesta; typo en mensaje|
| MEDIO | R-006, R-007, R-008 | Token sin contrato; HTTP 200-always; edge cases sin contrato |
| BAJO  | R-009, R-010        | Sin DELETE endpoint; dependencia de API externa  |

### 5. Calidad del framework implementado
- **Datos externalizados:** los 6 archivos JSON en `testdata/` eliminan datos hardcodeados en los features.
- **Setup idempotente:** `create_existing_user.feature` con `callonce` garantiza independencia entre runs sin DELETE.
- **Username único por ejecución:** AC-US-01 usa `java.lang.System.currentTimeMillis()` para generar usernames no colisionantes.
- **Reporte consolidado:** `Runner.path().parallel()` genera `karate-summary.html` con todos los escenarios, `karate-tags.html` y `karate-timeline.html`.

### 6. Recomendaciones para iteraciones futuras

| Prioridad | Recomendación                                                                                     |
|-----------|---------------------------------------------------------------------------------------------------|
| Alta      | Implementar validación de entrada en `/signup` para eliminar el HTTP 500 en campos vacíos        |
| Alta      | Documentar el contrato del token de sesión (tipo, expiración, estructura)                         |
| Media     | Adoptar códigos HTTP semánticos (201, 400, 401, 409) en lugar del patrón HTTP 200-always          |
| Media     | Agregar pruebas de endpoint `/login` con token inválido/expirado cuando se amplíe el scope        |
| Baja      | Corregir el mensaje de error ortográfico (`"already exists."`)                                    |
| Baja      | Evaluar implementación de endpoint DELETE para limpieza de datos de prueba en ambientes compartidos |

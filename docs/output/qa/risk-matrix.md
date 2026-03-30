# Matriz de Riesgos — Gestión de Usuarios (Signup & Login)

**Spec origen:** `.github/specs/user-management.spec.md` (SPEC-001 · v1.0 · APPROVED)  
**Feature:** `user-management`  
**API Target:** `https://api.demoblaze.com`  
**Fecha de generación:** 2026-03-30  
**Analista:** risk-identifier (QA Agent · ASDD)

---

## Resumen Ejecutivo

| Métrica | Valor |
|---------|-------|
| **Total de riesgos identificados** | 10 |
| **Nivel ALTO (A) — Obligatorio** | 4 |
| **Nivel MEDIO (S) — Recomendado** | 4 |
| **Nivel BAJO (D) — Opcional** | 2 |
| **Riesgos que bloquean Release** | 4 |

> **Decisión de release:** los 4 riesgos ALTO deben tener cobertura de test verificada antes de promover el código. Los riesgos MEDIO deben documentarse si se omiten.

---

## Detalle de la Matriz

| ID    | HU / AC    | Área          | Descripción del Riesgo                                                                                   | Factores                                              | Nivel | Testing      |
|-------|------------|---------------|----------------------------------------------------------------------------------------------------------|-------------------------------------------------------|-------|--------------|
| R-001 | HU-003 / AC-US-03 | Autenticación | El endpoint `/login` retorna un token de sesión. Si no se valida correctamente, un atacante podría acceder con tokens inválidos o expirados | Autenticación/autorización · Integraciones externas  | **A** | Obligatorio  |
| R-002 | HU-004 / AC-US-04 | Seguridad     | Un login fallido puede exponer información sobre la existencia de usuarios (`"User does not exist."`) — enumeración de usuarios válidos | Autenticación/autorización · Datos personales         | **A** | Obligatorio  |
| R-003 | HU-001 / AC-US-01 | Integridad    | El endpoint `/signup` es accesible sin autenticación previa y sin rate limiting visible — riesgo de creación masiva de cuentas (abuso/spam) | Integraciones con sistemas externos · Sin autenticación previa | **A** | Obligatorio  |
| R-004 | HU-002 / AC-US-02 | Integridad    | El mensaje de error de duplicidad contiene un typo (`"allready"`) — evidencia de falta de validación robusta en el backend; el manejo de duplicados podría ser inconsistente | Código sin historial de confiabilidad · Lógica de negocio | **A** | Obligatorio  |
| R-005 | HU-001 / AC-US-01 | Confiabilidad | El `username` requiere unicidad pero la API no expone un mecanismo de verificación previo al registro — la unicidad sólo se valida en el POST | Funcionalidad de alta frecuencia de uso · Código nuevo | **S** | Recomendado  |
| R-006 | HU-003 / AC-US-03 | Confiabilidad | El token retornado por `/login` no tiene un contrato de estructura documentado (no se sabe si es JWT, opaque token, o string aleatorio) — imposible validar expiración o scope | Integraciones con sistemas externos · Lógica compleja | **S** | Recomendado  |
| R-007 | RN-004     | Observabilidad | La API siempre retorna HTTP `200 OK` independientemente del resultado — patrón no estándar que dificulta el monitoreo automático, alertas y la integración con herramientas de observabilidad | Componentes con dependencias · Integración no estándar | **S** | Recomendado  |
| R-008 | EC-US-01 / EC-US-02 | Validación | Los edge cases con campos vacíos (`username=""`, `password=""`) no tienen un contrato de respuesta definido en el spec — comportamiento de la API es desconocido y puede ser inconsistente | Código nuevo sin historial · Lógica de validación     | **S** | Recomendado  |
| R-009 | HU-001     | Mantenibilidad | No existe endpoint de DELETE para usuarios — la limpieza post-prueba es imposible, acumulando datos de prueba en el ambiente compartido. Riesgo de colisiones si el username timestamp no es suficientemente único | Dependencia no controlada · Ambiente compartido       | **D** | Opcional     |
| R-010 | General    | Disponibilidad | La API es un servicio externo sin SLA documentado (`demoblaze.com`) — las pruebas automatizadas en CI/CD pueden fallar por indisponibilidad del servicio, no por defectos reales | Integraciones con sistemas externos (sin SLA)         | **D** | Opcional     |

---

## Plan de Mitigación — Riesgos ALTO

### R-001: Validación insuficiente del token de sesión en Login

**HU/AC afectado:** HU-003 / AC-US-03  
**Descripción:** El servicio `/login` retorna un token de sesión como string. Sin una validación estructural del token, un test que no verifique el contenido puede pasar con un valor vacío, `null`, o una cadena de error enmascarada como token.

- **Mitigación técnica:**
  - Validar en el `.feature` que `response` es `#notnull`, `#string`, y que `response.length > 0`.
  - Verificar que el token no contiene subcadenas de error: `"Wrong"`, `"does not exist"`, `"null"`.
  - Almacenar el token en una variable Karate (`* def sessionToken = response`) para reutilizarlo en pruebas de endpoints protegidos si se amplía el scope.
- **Tests obligatorios:**
  - `AC-US-03` con aserción positiva completa (tipo + longitud + ausencia de errores).
  - Control negativo: verificar que AC-US-04 NO retorna un token válido bajo las mismas aserciones.
- **Bloqueante para release:** ✅ Sí

---

### R-002: Enumeración de usuarios por mensajes de error diferenciados

**HU/AC afectado:** HU-004 / AC-US-04  
**Descripción:** La API retorna mensajes distintos según si el usuario no existe (`"User does not exist."`) o si la contraseña es incorrecta (`"Wrong password."`). Esta diferenciación permite a un atacante confirmar qué usernames son válidos mediante fuerza bruta, comprometiendo la confidencialidad del directorio de usuarios.

- **Mitigación técnica:**
  - Documentar el comportamiento en `conclusiones.md` como hallazgo de seguridad (clasificación: vulnerabilidad de diseño — OWASP API Security Top 10: API2:2023 Broken Authentication).
  - El test debe cubrir **ambos** mensajes de error para demostrar que el comportamiento es reproducible y determinístico.
  - Incluir el hallazgo en la sección de Recomendaciones del `conclusiones.md` con sugerencia de unificar en un mensaje genérico: `"Invalid credentials."`.
- **Tests obligatorios:**
  - `AC-US-04` con usuario inexistente → `"User does not exist."`.
  - Escenario adicional (si se amplía scope): usuario existente con password erróneo → `"Wrong password."`.
- **Bloqueante para release:** ✅ Sí

---

### R-003: Endpoint `/signup` sin protección contra abuso masivo

**HU/AC afectado:** HU-001 / AC-US-01  
**Descripción:** El endpoint `POST /signup` es completamente público, sin autenticación previa, CAPTCHA, ni evidencia de rate limiting. Esto expone la plataforma a creación automatizada de cuentas falsas (bots), lo que puede agotar recursos del servidor o contaminar la base de datos.

- **Mitigación técnica:**
  - El test AC-US-01 debe generar el `username` con un timestamp de alta resolución (`System.currentTimeMillis()`) para evitar colisiones entre ejecuciones paralelas.
  - Documentar la ausencia de rate limiting en `conclusiones.md` como riesgo de seguridad observado.
  - **No** realizar pruebas de carga o flood contra la API (fuera del scope de este proyecto; requeriría autorización explícita).
- **Tests obligatorios:**
  - `AC-US-01` con username único por timestamp — validar que el sistema acepta el registro.
  - `AC-US-02` — validar que la duplicidad es controlada correctamente.
- **Bloqueante para release:** ✅ Sí

---

### R-004: Inconsistencia en la lógica de validación de duplicados (typo en mensaje)

**HU/AC afectado:** HU-002 / AC-US-02  
**Descripción:** El mensaje de error devuelto para username duplicado contiene un error tipográfico: `"This user allready exist."`. Esto es evidencia de falta de revisión de calidad en el backend. El riesgo es que el mensaje podría cambiar en cualquier versión futura, rompiendo los tests sin que haya un cambio funcional real.

- **Mitigación técnica:**
  - Los tests deben usar la subcadena `"allready exist"` (contiene en lugar de igualdad exacta) para ser más resilientes a variaciones menores del mensaje.
  - En Karate: `match response contains 'allready exist'` — NO usar `match response == 'This user allready exist.'`.
  - Registrar en `conclusiones.md` que el typo es comportamiento documentado y que las aserciones fueron deliberadamente construidas para esta cadena exacta.
- **Tests obligatorios:**
  - `AC-US-02` con aserción de subconjunto (`contains`) en lugar de igualdad exacta.
- **Bloqueante para release:** ✅ Sí

---

## Plan de Gestión — Riesgos MEDIO

| ID    | Acción recomendada | Responsable | Plazo sugerido |
|-------|--------------------|-------------|----------------|
| R-005 | Documentar en `conclusiones.md`: la unicidad de `username` no es verificable antes del POST. Implementar username con timestamp como práctica estándar. | QA Automation | Junto con implementación |
| R-006 | Documentar el comportamiento del token en `conclusiones.md`. No asumir formato JWT — usar aserciones genéricas de string. Registrar como hallazgo para el equipo de la API. | QA Automation | Junto con implementación |
| R-007 | Documentar en `conclusiones.md` el patrón HTTP 200-always como comportamiento no estándar. Incluir recomendación de adoptar RFC 9110 (4xx para errores de cliente). | QA Automation + Tech Lead | Post-ejecución |
| R-008 | Ejecutar edge cases EC-US-01 y EC-US-02. Loguear respuestas sin aserción de fallo. Documentar comportamiento observado. Escalar como hallazgo de validación. | QA Automation | Junto con implementación |

---

## Clasificación por Área de Riesgo

```
SEGURIDAD            ████████████ A · A · (S)   → Cobertura CRÍTICA
INTEGRIDAD DE DATOS  ████████     A · (S)        → Cobertura ALTA
OBSERVABILIDAD       ████         (S)             → Cobertura MEDIA
CONFIABILIDAD        ████████     (S) · (S)       → Cobertura MEDIA
MANTENIBILIDAD       ████         (D)             → Cobertura BAJA
DISPONIBILIDAD       ████         (D)             → Cobertura BAJA
```

---

## Matriz de Cobertura de Tests vs. Riesgos

| Riesgo | Escenario que lo cubre | Estado |
|--------|------------------------|--------|
| R-001  | AC-US-03 (`login.feature`) | ⬜ Pendiente implementación |
| R-002  | AC-US-04 (`login.feature`) | ⬜ Pendiente implementación |
| R-003  | AC-US-01 (`signup.feature`) | ⬜ Pendiente implementación |
| R-004  | AC-US-02 (`signup.feature`) | ⬜ Pendiente implementación |
| R-005  | AC-US-01 (username timestamp) + `conclusiones.md` | ⬜ Pendiente implementación |
| R-006  | AC-US-03 (aserción string genérica) + `conclusiones.md` | ⬜ Pendiente implementación |
| R-007  | Todos los escenarios (validación doble: status + body) + `conclusiones.md` | ⬜ Pendiente implementación |
| R-008  | EC-US-01 + EC-US-02 (`signup.feature`, `login.feature`) | ⬜ Pendiente implementación |
| R-009  | Documentar en `conclusiones.md` | ⬜ Pendiente ejecución |
| R-010  | Documentar en `conclusiones.md` + estrategia retry en CI | ⬜ Pendiente ejecución |

---

*Próximo paso: `/unit-testing` para implementar los `.feature` files y `testdata/*.json` que cubren los riesgos ALTO marcados como Obligatorios.*

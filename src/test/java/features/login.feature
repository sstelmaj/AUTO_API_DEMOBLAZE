@login
Feature: Gestión de Usuarios - Autenticacion de usuarios registrados (Login)
  Cubre criterios AC-US-03, AC-US-04 y EC-US-02 de SPEC-001
  Endpoint: POST https://api.demoblaze.com/login

  Background:
    * url baseUrl
    * header Content-Type = 'application/json'
    # Garantizar que qa_existing_user existe antes de AC-US-03 (se ejecuta una sola vez por feature)
    * callonce read('classpath:features/helpers/create_existing_user.feature')

  # ── AC-US-03: Autenticación Exitosa ──────────────────────────────────────────
  @smoke @critico @seguridad @happy-path
  Scenario: AC-US-03 - Login exitoso con credenciales validas retorna token de sesion
    * def requestBody = read('classpath:testdata/login/login_success.json')
    Given path '/login'
    And request requestBody
    When method post
    Then status 200
    # El token es un string dinamico — se valida existencia, tipo y ausencia de mensajes de error (R-001)
    # Para strings planos: match valida tipo, assert valida contenido via Java String.contains()
    And match response == '#notnull'
    And match response == '#string'
    And assert response.length > 0
    And assert !response.contains('Wrong')
    And assert !response.contains('does not exist')
    # Almacenar token para trazabilidad en el reporte
    * def sessionToken = response
    * print 'AC-US-03 - Token de sesion obtenido (longitud):', sessionToken.length

  # ── AC-US-04: Autenticación Fallida ──────────────────────────────────────────
  @error-path @seguridad
  Scenario: AC-US-04 - Login fallido con usuario inexistente retorna mensaje de error
    * def requestBody = read('classpath:testdata/login/login_failure.json')
    Given path '/login'
    And request requestBody
    When method post
    Then status 200
    # La API retorna un objeto JSON con campo errorMessage (R-002 / OWASP API2:2023)
    And match response.errorMessage contains 'does not exist'

  # ── EC-US-02: Edge Case — Password vacío ─────────────────────────────────────
  @edge-case
  Scenario: EC-US-02 - Login con password vacio - comportamiento observable
    * def requestBody = read('classpath:testdata/login/login_empty_password.json')
    Given path '/login'
    And request requestBody
    When method post
    Then status 200
    # La API retorna un objeto JSON con campo errorMessage para password vacio (R-008)
    * print 'EC-US-02 observacion - password vacio - response body:', response
    And match response.errorMessage != null

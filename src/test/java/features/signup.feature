@signup
Feature: Gestión de Usuarios - Registro de nuevos usuarios (Signup)
  Cubre criterios AC-US-01, AC-US-02 y EC-US-01 de SPEC-001
  Endpoint: POST https://api.demoblaze.com/signup

  Background:
    * url baseUrl
    * header Content-Type = 'application/json'
    # Garantizar que qa_existing_user existe antes de AC-US-02 (se ejecuta una sola vez por feature)
    * callonce read('classpath:features/helpers/create_existing_user.feature')

  # ── AC-US-01: Registro Exitoso ──────────────────────────────────────────────
  @smoke @critico @happy-path
  Scenario: AC-US-01 - Registro exitoso de un nuevo usuario con username unico
    # El username se genera con timestamp para garantizar unicidad en cada ejecucion
    * def timestamp = function(){ return java.lang.System.currentTimeMillis() + '' }
    * def requestBody = read('classpath:testdata/signup/signup_success.json')
    * set requestBody.username = 'qa_auto_' + timestamp()
    Given path '/signup'
    And request requestBody
    When method post
    Then status 200
    # La API retorna null en registro exitoso (RN-006).
    # Verificar que la respuesta no es el mensaje de duplicidad.
    And assert response == null || !response.contains('exist')

  # ── AC-US-02: Registro Fallido — Usuario Duplicado ──────────────────────────
  @error-path
  Scenario: AC-US-02 - Registro fallido por username duplicado
    * def requestBody = read('classpath:testdata/signup/signup_duplicate.json')
    Given path '/signup'
    And request requestBody
    When method post
    Then status 200
    # La API retorna un objeto JSON con campo errorMessage (RN-003)
    And match response.errorMessage contains 'already exist'

  # ── EC-US-01: Edge Case — Username vacío ────────────────────────────────────
  @edge-case
  Scenario: EC-US-01 - Registro con username vacio - comportamiento observable
    * def requestBody = read('classpath:testdata/signup/signup_empty_username.json')
    Given path '/signup'
    And request requestBody
    When method post
    # La API retorna HTTP 500 para username vacio (comportamiento observable, sin contrato — R-008)
    * print 'EC-US-01 observacion - username vacio - status:', responseStatus, '- response body:', response

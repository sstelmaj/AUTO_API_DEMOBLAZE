@ignore
Feature: Helper - Garantizar que qa_existing_user existe antes de los tests dependientes

  Scenario: Setup - Registrar qa_existing_user (idempotente)
    * url baseUrl
    * header Content-Type = 'application/json'
    # Intentar crear el usuario. Si ya existe, la API retorna "This user allready exist." con status 200.
    # Si no existe, lo crea y retorna null con status 200.
    # Ambos resultados son validos para este setup.
    Given path '/signup'
    And request { username: 'qa_existing_user', password: 'P@ss_Signup_99' }
    When method post
    Then status 200
    * print 'Setup qa_existing_user - response:', response

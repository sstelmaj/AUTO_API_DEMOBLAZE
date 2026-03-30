package runners;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class TestRunner {

    // Runner.path genera karate-summary.html con TODOS los escenarios en target/karate-reports/
    // Los features con @ignore (helpers) son excluidos automaticamente por Karate.
    // Para ejecucion selectiva usar: mvn test -Dkarate.options="--tags @smoke"
    @Test
    void testAll() {
        Results results = Runner.path("classpath:features")
                .outputCucumberJson(true)
                .parallel(1);
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}

@REM ----------------------------------------------------------------------------
@REM Maven Wrapper startup script para Windows — generado para AUTO_API_DEMOBLAZE
@REM ----------------------------------------------------------------------------
@echo off

set MAVEN_PROJECTBASEDIR=%~dp0
set MAVEN_WRAPPER_JAR=%MAVEN_PROJECTBASEDIR%.mvn\wrapper\maven-wrapper.jar
set MAVEN_WRAPPER_PROPERTIES=%MAVEN_PROJECTBASEDIR%.mvn\wrapper\maven-wrapper.properties

if defined JAVA_HOME (
    set JAVACMD=%JAVA_HOME%\bin\java.exe
) else (
    set JAVACMD=java.exe
)

if not exist "%MAVEN_WRAPPER_JAR%" (
    echo Downloading Maven Wrapper...
    for /f "tokens=2 delims==" %%A in ('findstr /i "wrapperUrl" "%MAVEN_WRAPPER_PROPERTIES%"') do (
        set DOWNLOAD_URL=%%A
    )
    powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%MAVEN_WRAPPER_JAR%'"
)

"%JAVACMD%" ^
  -classpath "%MAVEN_WRAPPER_JAR%" ^
  "-Dmaven.multiModuleProjectDirectory=%MAVEN_PROJECTBASEDIR%" ^
  org.apache.maven.wrapper.MavenWrapperMain ^
  %*

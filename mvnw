#!/bin/sh
# ----------------------------------------------------------------------------
# Maven Wrapper startup script — generado para AUTO_API_DEMOBLAZE
# ----------------------------------------------------------------------------

if [ -z "$JAVA_HOME" ] ; then
  JAVACMD=`which java`
else
  JAVACMD="$JAVA_HOME/bin/java"
fi

MAVEN_PROJECTBASEDIR="${BASH_SOURCE%/*}"
MAVEN_WRAPPER_JAR="$MAVEN_PROJECTBASEDIR/.mvn/wrapper/maven-wrapper.jar"
MAVEN_WRAPPER_PROPERTIES="$MAVEN_PROJECTBASEDIR/.mvn/wrapper/maven-wrapper.properties"

DOWNLOAD_URL=$(grep distributionUrl "$MAVEN_WRAPPER_PROPERTIES" | sed "s/distributionUrl=//")

if [ ! -f "$MAVEN_WRAPPER_JAR" ]; then
  echo "Downloading Maven Wrapper..."
  wrapperUrl=$(grep wrapperUrl "$MAVEN_WRAPPER_PROPERTIES" | sed "s/wrapperUrl=//")
  curl -o "$MAVEN_WRAPPER_JAR" "$wrapperUrl" 2>/dev/null || wget -O "$MAVEN_WRAPPER_JAR" "$wrapperUrl"
fi

exec "$JAVACMD" \
  -classpath "$MAVEN_WRAPPER_JAR" \
  "-Dmaven.multiModuleProjectDirectory=$MAVEN_PROJECTBASEDIR" \
  org.apache.maven.wrapper.MavenWrapperMain \
  "$@"

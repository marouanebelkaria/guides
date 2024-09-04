#!/bin/bash

# Variables pour les chemins
GRAILS_APP_DIR="/home/jenkins-slave/grails-app"
INSTALL_DIR="/applis/bin"
GRAILS_VERSION="2.2.0"
JDK7_HOME="$INSTALL_DIR/zulu7.56.0.11-ca-jdk7.0.352-linux_x64"
JDK11_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# Fonction pour basculer vers JDK 7
use_jdk7() {
    export JAVA_HOME=$JDK7_HOME
    export PATH=$JAVA_HOME/bin:$PATH
    echo "Bascule vers JDK 7: $JAVA_HOME"
}

# Fonction pour basculer vers JDK 11
use_jdk11() {
    export JAVA_HOME=$JDK11_HOME
    export PATH=$JAVA_HOME/bin:$PATH
    echo "Bascule vers JDK 11: $JAVA_HOME"
}

# Assurez-vous que JAVA_HOME et PATH sont définis correctement au départ
use_jdk7

# Créer l'application Grails
mkdir -p $GRAILS_APP_DIR
cd $GRAILS_APP_DIR
$INSTALL_DIR/grails-$GRAILS_VERSION/bin/grails create-app myApp

# Compiler et tester l'application
cd myApp
$INSTALL_DIR/grails-$GRAILS_VERSION/bin/grails test-app

# Générer le rapport Cobertura
$INSTALL_DIR/grails-$GRAILS_VERSION/bin/grails cobertura

# Bascule vers JDK 11 pour l'analyse SonarQube si nécessaire
use_jdk11

# Analyser avec SonarQube
$INSTALL_DIR/sonar-scanner-4.8.1.3023-linux/bin/sonar-scanner -Dsonar.projectKey=myApp -Dsonar.sources=. -Dsonar.java.binaries=build/classes -Dsonar.junit.reportsPath=build/test-results -Dsonar.cobertura.reportPath=build/reports/cobertura/coverage.xml

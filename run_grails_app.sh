#!/bin/bash

# Exécuter en tant que jenkins-slave
sudo -u jenkins-slave bash <<EOF

# Chemin de l'application Grails
GRAILS_APP_DIR="/home/jenkins-slave/grails-app"
INSTALL_DIR="/applis/bin"
GRAILS_VERSION="2.2.0"

# Créer l'application Grails
mkdir -p \$GRAILS_APP_DIR
cd \$GRAILS_APP_DIR
\$INSTALL_DIR/grails-\$GRAILS_VERSION/bin/grails create-app myApp

# Compiler et tester l'application
cd myApp
\$INSTALL_DIR/grails-\$GRAILS_VERSION/bin/grails test-app

# Générer le rapport Cobertura
\$INSTALL_DIR/grails-\$GRAILS_VERSION/bin/grails cobertura

# Analyser avec SonarQube
\$INSTALL_DIR/sonar-scanner-4.8.1.3023/bin/sonar-scanner -Dsonar.projectKey=myApp -Dsonar.sources=. -Dsonar.java.binaries=build/classes -Dsonar.junit.reportsPath=build/test-results -Dsonar.cobertura.reportPath=build/reports/cobertura/coverage.xml

EOF

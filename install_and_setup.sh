#!/bin/bash

# Mettre à jour la liste des paquets
echo "Mise à jour de la liste des paquets..."
sudo apt update

# Installer Ansible et les dépendances nécessaires
echo "Installation d'Ansible et des dépendances nécessaires..."
sudo apt install -y ansible unzip wget curl

# Créer l'utilisateur jenkins-slave s'il n'existe pas
if id "jenkins-slave" &>/dev/null; then
    echo "L'utilisateur jenkins-slave existe déjà."
else
    echo "Création de l'utilisateur jenkins-slave..."
    sudo useradd -m -s /bin/bash jenkins-slave
    echo "jenkins-slave ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/jenkins-slave
fi

# Créer le fichier d'inventaire
echo "Création du fichier d'inventaire..."
cat <<EOL > hosts.ini
[jenkins_agents]
localhost ansible_connection=local ansible_user=jenkins-slave
EOL

# Créer le playbook Ansible simplifié
echo "Création du playbook Ansible..."
cat <<EOL > playbook.yml
---
- name: Installer SonarQube, JDK, Grails, Maven, Sonar Scanner sur Ubuntu 24 avec jenkins-slave
  hosts: all
  become: yes
  vars:
    user: "jenkins-slave"
    install_dir: "/applis/bin"
    grails_app_dir: "/home/{{ user }}/grails-app"
    sonarqube_version: "9.9.3.79811"
    sonarqube_url: "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-{{ sonarqube_version }}.zip"
    jdk7_url: "https://cdn.azul.com/zulu/bin/zulu7.56.0.11-ca-jdk7.0.352-linux_x64.tar.gz"
    grails_version: "2.2.0"
    grails_url: "https://github.com/grails/grails-core/releases/download/v{{ grails_version }}/grails-{{ grails_version }}.zip"
    maven_version: "3.8.8"
    maven_url: "https://downloads.apache.org/maven/maven-3/{{ maven_version }}/binaries/apache-maven-{{ maven_version }}-bin.tar.gz"
    sonar_scanner_version: "4.8.1.3023"
    sonar_scanner_url: "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-{{ sonar_scanner_version }}-linux.zip"

  tasks:
    - name: Mettre à jour la liste des paquets
      apt:
        update_cache: yes

    - name: Créer le répertoire d'installation
      file:
        path: "{{ install_dir }}"
        state: directory
        owner: "{{ user }}"
        group: "{{ user }}"

    - name: Télécharger et extraire JDK 7
      become: yes
      become_user: "{{ user }}"
      block:
        - get_url:
            url: "{{ jdk7_url }}"
            dest: "/tmp/zulu7-jdk.tar.gz"

        - unarchive:
            src: "/tmp/zulu7-jdk.tar.gz"
            dest: "{{ install_dir }}"
            remote_src: yes
            owner: "{{ user }}"
            group: "{{ user }}"

    - name: Télécharger et extraire SonarQube
      become: yes
      become_user: "{{ user }}"
      block:
        - get_url:
            url: "{{ sonarqube_url }}"
            dest: "/tmp/sonarqube-{{ sonarqube_version }}.zip"

        - unarchive:
            src: "/tmp/sonarqube-{{ sonarqube_version }}.zip"
            dest: "{{ install_dir }}"
            remote_src: yes
            owner: "{{ user }}"
            group: "{{ user }}"

    - name: Démarrer SonarQube
      shell: "{{ install_dir }}/sonarqube-{{ sonarqube_version }}/bin/linux-x86-64/sonar.sh start"
      become: yes

    - name: Télécharger et extraire Grails
      become: yes
      become_user: "{{ user }}"
      block:
        - get_url:
            url: "{{ grails_url }}"
            dest: "/tmp/grails-{{ grails_version }}.zip"

        - unarchive:
            src: "/tmp/grails-{{ grails_version }}.zip"
            dest: "{{ install_dir }}"
            remote_src: yes
            owner: "{{ user }}"
            group: "{{ user }}"

    - name: Télécharger et extraire Maven
      become: yes
      become_user: "{{ user }}"
      block:
        - get_url:
            url: "{{ maven_url }}"
            dest: "/tmp/apache-maven-{{ maven_version }}.tar.gz"

        - unarchive:
            src: "/tmp/apache-maven-{{ maven_version }}.tar.gz"
            dest: "{{ install_dir }}"
            remote_src: yes
            owner: "{{ user }}"
            group: "{{ user }}"

    - name: Télécharger et extraire Sonar Scanner
      become: yes
      become_user: "{{ user }}"
      block:
        - get_url:
            url: "{{ sonar_scanner_url }}"
            dest: "/tmp/sonar-scanner-cli-{{ sonar_scanner_version }}.zip"

        - unarchive:
            src: "/tmp/sonar-scanner-cli-{{ sonar_scanner_version }}.zip"
            dest: "{{ install_dir }}"
            remote_src: yes
            owner: "{{ user }}"
            group: "{{ user }}"

    - name: Nettoyer les fichiers temporaires
      become: yes
      become_user: "{{ user }}"
      file:
        path: "{{ item }}"
        state: absent
      loop:
        - "/tmp/zulu7-jdk.tar.gz"
        - "/tmp/sonarqube-{{ sonarqube_version }}.zip"
        - "/tmp/grails-{{ grails_version }}.zip"
        - "/tmp/apache-maven-{{ maven_version }}.tar.gz"
        - "/tmp/sonar-scanner-cli-{{ sonar_scanner_version }}.zip"

    - name: Ajouter les chemins des logiciels à la variable d'environnement PATH
      become: yes
      become_user: "{{ user }}"
      lineinfile:
        path: "/home/{{ user }}/.bashrc"
        line: "export PATH=\$PATH:{{ install_dir }}/zulu7.56.0.11-ca-jdk7.0.352-linux_x64/bin:{{ install_dir }}/grails-{{ grails_version }}/bin:{{ install_dir }}/apache-maven-{{ maven_version }}/bin:{{ install_dir }}/sonar-scanner-{{ sonar_scanner_version }}/bin"
        state: present

    - name: Recharger le shell
      become: yes
      become_user: "{{ user }}"
      shell: "source /home/{{ user }}/.bashrc"

    - name: Créer le répertoire de l'application Grails
      file:
        path: "{{ grails_app_dir }}"
        state: directory
        owner: "{{ user }}"
        group: "{{ user }}"
    
    - name: Créer une nouvelle application Grails
      become: yes
      become_user: "{{ user }}"
      shell: "{{ install_dir }}/grails-{{ grails_version }}/bin/grails create-app myApp"
      args:
        chdir: "{{ grails_app_dir }}"

    - name: Compiler et tester l'application Grails
      become: yes
      become_user: "{{ user }}"
      shell: "{{ install_dir }}/grails-{{ grails_version }}/bin/grails test-app"
      args:
        chdir: "{{ grails_app_dir }}/myApp"

    - name: Générer le rapport Cobertura
      become: yes
      become_user: "{{ user }}"
      shell: "{{ install_dir }}/grails-{{ grails_version }}/bin/grails cobertura"
      args:
        chdir: "{{ grails_app_dir }}/myApp"

    - name: Analyser le code avec SonarQube
      become: yes
      become_user: "{{ user }}"
      shell: "{{ install_dir }}/sonar-scanner-{{ sonar_scanner_version }}/bin/sonar-scanner -Dsonar.projectKey=myApp -Dsonar.sources=. -Dsonar.java.binaries=build/classes -Dsonar.junit.reportsPath=build/test-results -Dsonar.cobertura.reportPath=build/reports/cobertura/coverage.xml"
      args:
        chdir: "{{ grails_app_dir }}/myApp"
EOL

# Exécuter le playbook Ansible
echo "Exécution du playbook Ansible..."
ansible-playbook -i hosts.ini playbook.yml

echo "Installation et configuration terminées."

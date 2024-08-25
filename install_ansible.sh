#!/bin/bash

# Script d'installation d'Ansible sur Ubuntu 22.04 ou 24

echo "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

if [ $? -ne 0 ]; then
  echo "Erreur lors de la mise à jour du système. Veuillez vérifier votre connexion réseau ou les paramètres de votre système."
  exit 1
fi

echo "Installation des dépendances nécessaires..."
sudo apt install -y python3 python3-pip software-properties-common

if [ $? -ne 0 ]; then
  echo "Erreur lors de l'installation des dépendances. Veuillez vérifier les paquets et réessayer."
  exit 1
fi

echo "Ajout du PPA officiel d'Ansible..."
sudo add-apt-repository --yes --update ppa:ansible/ansible

if [ $? -ne 0 ]; then
  echo "Erreur lors de l'ajout du dépôt Ansible. Veuillez vérifier la commande et réessayer."
  exit 1
fi

echo "Mise à jour de la liste des paquets..."
sudo apt update

if [ $? -ne 0 ]; then
  echo "Erreur lors de la mise à jour de la liste des paquets. Veuillez vérifier votre connexion réseau ou les paramètres de votre système."
  exit 1
fi

echo "Installation d'Ansible..."
sudo apt install ansible -y

if [ $? -ne 0 ]; then
  echo "Erreur lors de l'installation d'Ansible. Veuillez vérifier les paquets et réessayer."
  exit 1
fi

echo "Vérification de l'installation d'Ansible..."
ansible --version

if [ $? -ne 0 ]; then
  echo "Ansible n'a pas été installé correctement. Veuillez vérifier les étapes précédentes et réessayer."
  exit 1
fi

echo "Installation d'Ansible réussie !"

echo "Vous pouvez maintenant configurer votre fichier d'inventaire à /etc/ansible/hosts et ajuster les paramètres globaux dans /etc/ansible/ansible.cfg si nécessaire."

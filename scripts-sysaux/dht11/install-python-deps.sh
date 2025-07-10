#!/bin/bash
# Script pour gérer l'installation des dépendances Python dans un venv ou pour l'utilisateur courant
# Usage : ./install-python-deps.sh [requirements.txt]

REQ_FILE="${1:-./requirements.txt}"

if [ ! -f "$REQ_FILE" ]; then
    echo -e "\033[31;1m[ERROR]\033[0m Fichier requirements.txt introuvable !"
    exit 1
fi

# Détection d'un environnement virtuel Python
if [ -n "$VIRTUAL_ENV" ]; then
    echo -e "\033[32;1m[OK]\033[0m Environnement virtuel Python détecté : $VIRTUAL_ENV"
    pip install -r "$REQ_FILE"
    echo -e "\033[32;1m[OK]\033[0m Dépendances installées dans l'environnement virtuel actif."
else
    echo -e "\033[33;1m[INFO]\033[0m Aucun environnement virtuel Python détecté."
    read -p "Voulez-vous installer les dépendances dans un venv local [v] ou pour l'utilisateur courant [u] ? [v/u] : " choix
    if [ "$choix" = "v" ]; then
        python3 -m venv venv
        source venv/bin/activate
        pip install -r "$REQ_FILE"
        echo -e "\033[32;1m[OK]\033[0m Dépendances installées dans le venv local ./venv"
    else
        pip3 install --user -r "$REQ_FILE"
        echo -e "\033[32;1m[OK]\033[0m Dépendances installées pour l'utilisateur courant (--user)"
    fi
fi

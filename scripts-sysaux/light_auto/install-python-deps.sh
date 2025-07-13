#!/bin/bash
# Script pour installer les dépendances Python de light_auto
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
    read -p "Voulez-vous installer les dépendances dans un venv local [v], pour l'utilisateur courant [u], ou pour un autre utilisateur [o] ? [v/u/o] : " choix
    if [ "$choix" = "v" ]; then
        python3 -m venv venv
        source venv/bin/activate
        pip install -r "$REQ_FILE"
        echo -e "\033[32;1m[OK]\033[0m Dépendances installées dans le venv local ./venv"
    elif [ "$choix" = "u" ]; then
        pip3 install --user -r "$REQ_FILE"
        echo -e "\033[32;1m[OK]\033[0m Dépendances installées pour l'utilisateur courant (--user)"
    elif [ "$choix" = "o" ]; then
        read -p "Nom de l'utilisateur cible : " cible
        if id "$cible" &>/dev/null; then
            echo -e "\033[33;1m[INFO]\033[0m Installation pour l'utilisateur $cible..."
            cible_home=$(eval echo "~$cible")
            sudo cp "$REQ_FILE" "$cible_home/requirements.txt"
            sudo chown "$cible":"$cible" "$cible_home/requirements.txt"
            sudo -u "$cible" -H bash -c "pip3 install --user -r '$cible_home/requirements.txt'"
            sudo rm -f "$cible_home/requirements.txt"
            if [ $? -eq 0 ]; then
                echo -e "\033[32;1m[OK]\033[0m Dépendances installées pour l'utilisateur $cible (--user)"
            else
                echo -e "\033[31;1m[ERROR]\033[0m Échec de l'installation pour l'utilisateur $cible. Vérifiez les droits et l'environnement Python."
            fi
        else
            echo -e "\033[31;1m[ERROR]\033[0m L'utilisateur $cible n'existe pas. Abandon."
            exit 2
        fi
    else
        echo -e "\033[31;1m[ERROR]\033[0m Choix invalide. Abandon."
        exit 3
    fi
fi

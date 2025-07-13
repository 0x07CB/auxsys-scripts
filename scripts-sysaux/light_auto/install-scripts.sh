#!/bin/bash

# check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo or switch to the root user."
    exit 1
fi


# Détermine le dossier source (argument ou dossier du script)
if [ -n "$1" ]; then
    SRC_DIR="$1"
else
    SRC_DIR="$(dirname "$(realpath "$0")")"
fi

# check if user 'gpiouser' exists, if not create it
if ! id -u gpiouser &>/dev/null; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m User 'gpiouser' does not exist. Creating it now..."
    sudo useradd -U -m -s /bin/bash gpiouser
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m User 'gpiouser' already exists."
fi

# check if user 'gpiouser' is in 'gpio' group, if not add it
if ! groups gpiouser | grep "gpio"; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Adding user 'gpiouser' to 'gpio' group..."
    sudo usermod -aG gpio gpiouser
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m User 'gpiouser' is already in 'gpio' group."
fi

# check if user 'gpiouser' is in 'audio' group, if not add it
if ! groups gpiouser | grep "audio"; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Adding user 'gpiouser' to 'audio' group..."
    sudo usermod -aG audio gpiouser
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m User 'gpiouser' is already in 'audio' group."
fi



# Copie le service systemd
if [ ! -f /etc/systemd/system/light-auto.service ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m The service file /etc/systemd/system/light-auto.service does not exist. It will be created during the installation process."
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m The service file /etc/systemd/system/light-auto.service already exists. It will be overwritten with the new version."
fi
sudo cp "$SRC_DIR/service/light-auto.service" /etc/systemd/system/light-auto.service

# reload daemon and disable now light-auto.service
sudo systemctl daemon-reload \
    && sudo systemctl disable --now light-auto.service


# check if /opt/light_auto exists, if not create it
if [ ! -d /opt/light_auto ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Creating directory /opt/light_auto..."
    sudo mkdir -p /opt/light_auto
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Directory /opt/light_auto already exists."
fi


# Copie light_auto.py
if [ ! -f /opt/light_auto/light_auto.py ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Copying light_auto.py to /opt/light_auto/light_auto.py..."
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m light_auto.py already exists in /opt/light_auto. Backing up the existing file... and copying the new one."
    sudo rm -f /opt/light_auto/light_auto.py
fi
sudo cp "$SRC_DIR/light_auto.py" /opt/light_auto/light_auto.py
sudo chmod +x /opt/light_auto/light_auto.py



# Copie le dossier sounds
if [ ! -d /opt/light_auto/sounds ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Copying sounds to /opt/light_auto/sounds..."
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Sounds directory already exists in /opt/light_auto. Backing up the existing directory... and copying the new one."
    sudo rm -rf /opt/light_auto/sounds
fi
sudo cp -r "$SRC_DIR/sounds" /opt/light_auto/sounds


# Copie requirements.txt
if [ ! -f /opt/light_auto/requirements.txt ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Copying requirements.txt to /opt/light_auto/requirements.txt..."
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m requirements.txt already exists in /opt/light_auto. Backing up the existing file... and copying the new one."
    sudo rm -f /opt/light_auto/requirements.txt
fi
sudo cp "$SRC_DIR/requirements.txt" /opt/light_auto/requirements.txt



sudo chown -R gpiouser:gpiouser /opt/light_auto
sudo chmod -R 755 /opt/light_auto
sudo chmod +x /opt/light_auto/light_auto.py


# Installation des dépendances Python (via script dédié)
if [ -f "$SRC_DIR/install-python-deps.sh" ]; then
    bash "$SRC_DIR/install-python-deps.sh" "$SRC_DIR/requirements.txt"
else
    echo -e "\033[33;1m[INFO]\033[0m Script install-python-deps.sh non trouvé, installation des dépendances Python non effectuée."
fi


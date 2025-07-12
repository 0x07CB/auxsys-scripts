#!/bin/bash

# check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo or switch to the root user."
    exit 1
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


# check if /etc/systemd/system/light-auto.service exists
if [ ! -f /etc/systemd/system/light-auto.service ]; then
    # error messages an blinking red "ERROR" between whites brackets (ANSI COLORS)
    # info messages an blinking yellow "INFO" between whites brackets (ANSI COLORS)
    
    # info message about the missing service file, because it is not installed yet so we will create it
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m The service file /etc/systemd/system/light-auto.service does not exist. It will be created during the installation process."
    sudo cp ./service/light-auto.service /etc/systemd/system/light-auto.service
else
    # info message about the existing service file, because it is already installed
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m The service file /etc/systemd/system/light-auto.service already exists. It will be overwritten with the new version."
    sudo cp ./service/light-auto.service /etc/systemd/system/light-auto.service
fi

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

# copy light_auto.py to /opt/light_auto/light_auto.py
if [ ! -f /opt/light_auto/light_auto.py ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Copying light_auto.py to /opt/light_auto/light_auto.py..."
    sudo cp ./light_auto.py /opt/light_auto/light_auto.py
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m light_auto.py already exists in /opt/light_auto. Backing up the existing file... and copying the new one."
    sudo rm -f /opt/light_auto/light_auto.py
    sudo cp ./light_auto.py /opt/light_auto/light_auto.py
    sudo chmod +x /opt/light_auto/light_auto.py
fi


# copy ./sounds to /opt/light_auto/sounds
if [ ! -d /opt/light_auto/sounds ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Copying sounds to /opt/light_auto/sounds..."
    sudo cp -r ./sounds /opt/light_auto/sounds
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Sounds directory already exists in /opt/light_auto. Backing up the existing directory... and copying the new one."
    sudo rm -rf /opt/light_auto/sounds
    sudo cp -r ./sounds /opt/light_auto/sounds
fi

# copy ./requirements.txt to /opt/light_auto/requirements.txt
if [ ! -f /opt/light_auto/requirements.txt ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Copying requirements.txt to /opt/light_auto/requirements.txt..."
    sudo cp ./requirements.txt /opt/light_auto/requirements.txt
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m requirements.txt already exists in /opt/light_auto. Backing up the existing file... and copying the new one."
    sudo rm -f /opt/light_auto/requirements.txt
    sudo cp ./requirements.txt /opt/light_auto/requirements.txt
fi



sudo chown -R gpiouser:gpiouser /opt/light_auto \
    && sudo chmod -R 755 /opt/light_auto \
    && sudo chmod +x /opt/light_auto/light_auto.py

# Installation des dépendances Python (via script dédié)
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/install-python-deps.sh" ]; then
    bash "$SCRIPT_DIR/install-python-deps.sh" "$SCRIPT_DIR/requirements.txt"
else
    echo -e "\033[33;1m[INFO]\033[0m Script install-python-deps.sh non trouvé, installation des dépendances Python non effectuée."
fi


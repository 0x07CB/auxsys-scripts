#!/bin/bash

# check if user is root (necessary for installing packages)
if [ "$(id -u)" -ne 0 ]; then
    # error messages an blinking red "ERROR" between whites brackets (ANSI COLORS)
    echo -e "\033[31;1m[\033[0m\033[31;5mERROR\033[0m\033[31;1m]\033[0m You must run this script as root or with sudo."
    exit 1
fi

# if 'espeak-ng' is not installed, install it
if ! command -v espeak-ng &> /dev/null; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m espeak-ng is not installed. Installing it now..."
    sudo apt-get update \
        && sudo apt install -y espeak-ng
fi

# if 'sox' is not installed, install it
if ! command -v sox &> /dev/null; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m sox is not installed. Installing it now..."
    sudo apt-get update \
        && sudo apt install -y sox libsox-fmt-all
fi

# copy dht.py to /opt/scripts/DHT11/bin/dht.py
if [ ! -d "/opt/scripts/DHT11/bin" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Creating directory /opt/scripts/DHT11/bin..."
    sudo mkdir -p /opt/scripts/DHT11/bin
fi
if [ ! -f "/opt/scripts/DHT11/bin/dht.py" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Copying dht.py to /opt/scripts/DHT11/bin..."
    sudo cp ./dht.py /opt/scripts/DHT11/bin/
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m dht.py already exists in /opt/scripts/DHT11/bin. Backing up the existing file... and copying the new one."
    sudo cp /opt/scripts/DHT11/bin/dht.py /opt/scripts/DHT11/bin/dht.py.bak
    sudo cp ./dht.py /opt/scripts/DHT11/bin/
fi

# check if /opt/scripts/DHT11/bin/dht.py is executable, if not make it executable
if [ ! -x "/opt/scripts/DHT11/bin/dht.py" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Making /opt/scripts/DHT11/bin/dht.py executable..."
    sudo chmod +x /opt/scripts/DHT11/bin/dht.py
fi

# check if /usr/local/bin/dht11.py symlink exists, if not create it to /opt/scripts/DHT11/bin/dht.py
if [ ! -L "/usr/local/bin/dht11.py" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Creating symlink /usr/local/bin/dht11.py to /opt/scripts/DHT11/bin/dht.py..."
    sudo ln -s /opt/scripts/DHT11/bin/dht.py /usr/local/bin/dht11.py
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Symlink /usr/local/bin/dht11.py already exists."
fi

# check if user is in 'audio' group, if not add user to 'audio' group
if ! groups | grep "audio"; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Adding user to 'audio' group..."
    sudo usermod -aG audio "$(whoami)"
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m You need to log out and log back in for the changes to take effect."
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m User is already in 'audio' group."
fi


# check and copy espeak-dht11-humidity.sh to /opt/scripts/DHT11/bin/espeak-dht11-humidity.sh
if [ ! -d "/opt/scripts/DHT11/bin" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Creating directory /opt/scripts/DHT11/bin..."
    sudo mkdir -p /opt/scripts/DHT11/bin
fi
if [ ! -f "/opt/scripts/DHT11/bin/espeak-dht11-humidity.sh" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Copying espeak-dht11-humidity.sh to /opt/scripts/DHT11/bin..."
    sudo cp ./espeak-dht11-humidity.sh /opt/scripts/DHT11/bin/
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m espeak-dht11-humidity.sh already exists in /opt/scripts/DHT11/bin. Backing up the existing file... and copying the new one."
    sudo cp /opt/scripts/DHT11/bin/espeak-dht11-humidity.sh /opt/scripts/DHT11/bin/espeak-dht11-humidity.sh.bak
    sudo cp ./espeak-dht11-humidity.sh /opt/scripts/DHT11/bin/
fi

# check if /opt/scripts/DHT11/bin/espeak-dht11-humidity.sh is executable, if not make it executable
if [ ! -x "/opt/scripts/DHT11/bin/espeak-dht11-humidity.sh" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Making /opt/scripts/DHT11/bin/espeak-dht11-humidity.sh executable..."
    sudo chmod +x /opt/scripts/DHT11/bin/espeak-dht11-humidity.sh
fi

# check if /usr/local/bin/espeak-dht11-humidity.sh symlink exists, if not create it to /opt/scripts/DHT11/bin/espeak-dht11-humidity.sh
if [ ! -L "/usr/local/bin/espeak-dht11-humidity.sh" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Creating symlink /usr/local/bin/espeak-dht11-humidity.sh to /opt/scripts/DHT11/bin/espeak-dht11-humidity.sh..."
    sudo ln -s /opt/scripts/DHT11/bin/espeak-dht11-humidity.sh /usr/local/bin/espeak-dht11-humidity.sh
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Symlink /usr/local/bin/espeak-dht11-humidity.sh already exists."
fi

# check and copy espeak-dht11-temperature.sh to /opt/scripts/DHT11/bin/espeak-dht11-temperature.sh
if [ ! -d "/opt/scripts/DHT11/bin" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Creating directory /opt/scripts/DHT11/bin..."
    sudo mkdir -p /opt/scripts/DHT11/bin
fi

# check if espeak-dht11-temperature.sh exists in /opt/scripts/DHT11/bin
if [ ! -f "/opt/scripts/DHT11/bin/espeak-dht11-temperature.sh" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Copying espeak-dht11-temperature.sh to /opt/scripts/DHT11/bin..."
    sudo cp ./espeak-dht11-temperature.sh /opt/scripts/DHT11/bin/
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m espeak-dht11-temperature.sh already exists in /opt/scripts/DHT11/bin. Backing up the existing file... and copying the new one."
    sudo cp /opt/scripts/DHT11/bin/espeak-dht11-temperature.sh /opt/scripts/DHT11/bin/espeak-dht11-temperature.sh.bak
    sudo cp ./espeak-dht11-temperature.sh /opt/scripts/DHT11/bin/
fi

# check if /opt/scripts/DHT11/bin/espeak-dht11-temperature.sh is executable, if not make it executable
if [ ! -x "/opt/scripts/DHT11/bin/espeak-dht11-temperature.sh" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Making /opt/scripts/DHT11/bin/espeak-dht11-temperature.sh executable..."
    sudo chmod +x /opt/scripts/DHT11/bin/espeak-dht11-temperature.sh
fi


# check if /usr/local/bin/espeak-dht11-temperature.sh symlink exists, if not create it to /opt/scripts/DHT11/bin/espeak-dht11-temperature.sh
if [ ! -L "/usr/local/bin/espeak-dht11-temperature.sh" ]; then
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Creating symlink /usr/local/bin/espeak-dht11-temperature.sh to /opt/scripts/DHT11/bin/espeak-dht11-temperature.sh..."
    sudo ln -s /opt/scripts/DHT11/bin/espeak-dht11-temperature.sh /usr/local/bin/espeak-dht11-temperature.sh
else
    echo -e "\033[33;1m[\033[0m\033[33;5mINFO\033[0m\033[33;1m]\033[0m Symlink /usr/local/bin/espeak-dht11-temperature.sh already exists."
fi

# Installation des dépendances Python (via script dédié)
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/install-python-deps.sh" ]; then
    bash "$SCRIPT_DIR/install-python-deps.sh" "$SCRIPT_DIR/requirements.txt"
else
    echo -e "\033[33;1m[INFO]\033[0m Script install-python-deps.sh non trouvé, installation des dépendances Python non effectuée."
fi



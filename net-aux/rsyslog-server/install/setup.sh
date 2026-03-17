#!/bin/bash

sudo apt update \
    && sudo apt install rsyslog -y

#execute ufw configuration script
bash "$(dirname "$0")/ufw-configure.sh"

# check no errors occurred during installation
if [ $? -ne 0 ]; then
    echo "Error occurred during rsyslog installation or ufw configuration. Please check the output above for details."
    exit 1
else
    echo "rsyslog installation and ufw configuration completed successfully."
fi

echo -e "Restarting rsyslog service to apply changes..."
sudo systemctl restart rsyslog



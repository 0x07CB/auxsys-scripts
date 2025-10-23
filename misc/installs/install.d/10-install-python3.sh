#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
# Print commands and their arguments as they are executed
set -x

# Update package lists
apt-get update || true

# Install Python 3 and pip
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify installation
VERSION_PY_VERBOSE="$(python3 --version)"

# that :echo "Python 3 version: $VERSION_PY_VERBOSE"
# but use echo -e , and ANSI colors for better visibility
# Green color for 'Python 3 version:' text, and yellow for the version number
echo -e "\e[32mPython 3 version:\e[0m \e[33m$VERSION_PY_VERBOSE\e[0m"


# Upgrade pip to the latest version
#python3 -m pip install --upgrade pip

# Verify pip installation
#VERSION_PIP_VERBOSE="$(pip3 --version)"
#echo -e "\e[32mpip version:\e[0m \e[33m$VERSION_PIP_VERBOSE\e[0m"
# End of script
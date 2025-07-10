#!/bin/bash

function echo_error_message_with_ansi_colors() {
    # check if the argument is empty
    if [ -z "$1" ]; then
        echo "No message provided to echo_error_message_with_ansi_colors function."
        return 1
    fi
    # This function prints an error message: brackets in white, 'ERROR' in blinking red
    echo -e "\033[37;1m[\033[0m\033[31;5mERROR\033[0m\033[37;1m]\033[0m $1"
    return 0
}

function echo_info_message_with_ansi_colors() {
    # check if the argument is empty
    if [ -z "$1" ]; then
        echo_error_message_with_ansi_colors "No message provided to echo_info_message_with_ansi_colors function."
        return 1
    fi
    # This function prints an info message: brackets in white, 'INFO' in yellow
    echo -e "\033[37;1m[\033[0m\033[33;1mINFO\033[0m\033[37;1m]\033[0m $1"
    return 0
}


# START OF THE SCRIPT
# FIRST CHECK IF THE SCRIPT IS RUN AS ROOT
# ############################

# check if this script is run as root, if not, exit with an error message
if [ "$(id -u)" -ne 0 ]; then
    # error messages an blinking red "ERROR" between whites brackets (ANSI COLORS)
    # info messages are in yellow, and success messages are in green
    ERROR_MESSAGE="This script must be run as root. Please use sudo or run as root."
    # use 'echo_error_message_with_ansi_colors' function to print the error message, the function will return 1 if the message is empty (failure) and 0 if the message is printed (success).
    # So please check and manage the return code of the function
    echo_error_message_with_ansi_colors "$ERROR_MESSAGE"
    if [ $? -ne 0 ]; then
        echo "Failed to print error message. Exiting."
        exit 1
    fi
    
    # exit with a non-zero code to indicate failure ( non-root user )
    exit 1
fi


# define array list of packages needed ( to be installed if not installed after this array definition)
# ############################
REQUIRED_PACKAGES=('pigpiod' 'pigpio' 'libpigpio1' 'python3' 'python3-venv' 'python3-pip' 'python3-pigpio')
MISSING_PACKAGES_LIST=()
#
# Iterate over the array and check if each package is installed
# ############################
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! apt list --installed 2>/dev/null | grep -E "^${pkg}/" >/dev/null; then
        echo_error_message_with_ansi_colors "Package '$pkg' is not installed."
        MISSING_PACKAGES_LIST+=("$pkg")
    else
        echo_info_message_with_ansi_colors "Package '$pkg' is already installed."
    fi
done

if [ ${#MISSING_PACKAGES_LIST[@]} -ne 0 ]; then
    echo_error_message_with_ansi_colors "Les paquets suivants sont manquants : ${MISSING_PACKAGES_LIST[*]}"
    echo -e "\033[33;1mVoulez-vous que le script tente de les installer automatiquement ? (o/n)\033[0m"
    read -r USER_CHOICE
    if [[ "$USER_CHOICE" =~ ^[oOyY]$ ]]; then
        apt update
        apt install -y "${MISSING_PACKAGES_LIST[@]}"
        if [ $? -eq 0 ]; then
            echo_info_message_with_ansi_colors "Installation réussie des paquets manquants."
        else
            echo_error_message_with_ansi_colors "L'installation automatique a échoué. Veuillez installer les paquets manuellement."
            exit 1
        fi
    else
        echo_error_message_with_ansi_colors "Veuillez installer les paquets manquants puis relancer le script."
        exit 1
    fi
fi

# ############################

# ############################




# ############################

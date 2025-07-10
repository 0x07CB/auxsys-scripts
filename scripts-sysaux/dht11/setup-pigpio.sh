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

# Enable and start the pigpiod service
# ############################
# Enable the pigpiod service to start at boot
if ! systemctl is-enabled pigpiod >/dev/null 2>&1; then
    echo_info_message_with_ansi_colors "Enabling pigpiod service..."
    systemctl enable pigpiod
    if [ $? -ne 0 ]; then
        echo_error_message_with_ansi_colors "Failed to enable pigpiod service."
        exit 1
    fi
else
    echo_info_message_with_ansi_colors "pigpiod service is already enabled."
fi

# Start the pigpiod service or restart it if it's already running
if systemctl is-active --quiet pigpiod; then
    echo_info_message_with_ansi_colors "Restarting pigpiod service..."
    systemctl restart pigpiod
    if [ $? -ne 0 ]; then
        echo_error_message_with_ansi_colors "Failed to restart pigpiod service."
        exit 1
    fi
else
    echo_info_message_with_ansi_colors "Starting pigpiod service..."
    systemctl start pigpiod
    if [ $? -ne 0 ]; then
        echo_error_message_with_ansi_colors "Failed to start pigpiod service."
        exit 1
    fi
fi


# Fonction pour ajouter des utilisateurs au groupe gpio avec gestion des erreurs
function add_users_to_gpio_group() {
    local ALL_USERS_VALID=true

    echo -e "\033[33;1mVeuillez indiquer le ou les utilisateurs à ajouter au groupe 'gpio' (séparés par des espaces ou des virgules).\033[0m"
    echo -e "\033[33;1mLaissez vide pour ajouter uniquement l'utilisateur courant : $SUDO_USER (ou $USER si non lancé avec sudo).\033[0m"
    read -r USER_INPUT

    # Détermination de la liste d'utilisateurs à ajouter
    if [ -z "$USER_INPUT" ]; then
        if [ -n "$SUDO_USER" ]; then
            USERS_TO_ADD=("$SUDO_USER")
        else
            USERS_TO_ADD=("$USER")
        fi
    else
        USER_INPUT_CLEANED=$(echo "$USER_INPUT" | tr ',' ' ')
        USERS_TO_ADD=($USER_INPUT_CLEANED)
    fi

    for TARGET_USER in "${USERS_TO_ADD[@]}"; do
        if id "$TARGET_USER" &>/dev/null; then
            if groups "$TARGET_USER" | grep -qw "gpio"; then
                echo_info_message_with_ansi_colors "L'utilisateur '$TARGET_USER' est déjà membre du groupe gpio."
            else
                echo_info_message_with_ansi_colors "L'utilisateur '$TARGET_USER' n'est pas membre du groupe gpio."
                echo_info_message_with_ansi_colors "Ajout de '$TARGET_USER' au groupe gpio..."
                usermod -aG gpio "$TARGET_USER"
                if [ $? -eq 0 ]; then
                    echo_info_message_with_ansi_colors "Ajout de '$TARGET_USER' au groupe gpio réussi. (Déconnexion/reconnexion nécessaire pour prise en compte)"
                else
                    echo_error_message_with_ansi_colors "Échec de l'ajout de '$TARGET_USER' au groupe gpio."
                    ALL_USERS_VALID=false
                fi
            fi
        else
            echo_error_message_with_ansi_colors "L'utilisateur '$TARGET_USER' n'existe pas."
            echo_error_message_with_ansi_colors "Veuillez vérifier le nom d'utilisateur."
            ALL_USERS_VALID=false
        fi
        sleep 0.2
    done

    $ALL_USERS_VALID && return 0 || return 1
}

# Appel de la fonction avec gestion de l'échec et possibilité de réessayer
while true; do
    add_users_to_gpio_group
    if [ $? -eq 0 ]; then
        break
    else
        echo -e "\033[33;1mVoulez-vous réessayer d'ajouter les utilisateurs ? (o/n)\033[0m"
        read -r RETRY_CHOICE
        if ! [[ "$RETRY_CHOICE" =~ ^[oOyY]$ ]]; then
            echo_info_message_with_ansi_colors "Abandon de l'ajout d'utilisateurs au groupe gpio."
            break
        fi
    fi
done


# ############################




# ############################

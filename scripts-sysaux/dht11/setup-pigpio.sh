#!/bin/bash

function echo_error_message_with_ansi_colors() {
    # check if the argument is empty
    if [ -z "$1" ]; then
        echo "No message provided to echo_error_message_with_ansi_colors function."
        return 1
    fi
    # This function take a env var in argument ( a text string , this is the message to print )
    # This function prints an error message in red with blinking effect
    echo -e "\033[31;1m[\033[0m\033[31;5mERROR\033[0m\033[31;1m]\033[0m $1"
    return 0
}

function echo_info_message_with_ansi_colors() {
    # check if the argument is empty
    if [ -z "$1" ]; then
        echo_error_message_with_ansi_colors "No message provided to echo_info_message_with_ansi_colors function."
        return 1
    fi
    # This function take a env var in argument ( a text string , this is the message to print )
    # This function prints an info message in yellow
    echo -e "\033[33;1m[\033[0m\033[33;1mINFO\033[0m\033[33;1m]\033[0m $1"
    return 0
}




# check if this script is run as root, if not, exit with an error message
if [ "$(id -u)" -ne 0 ]; then
    # error messages an blinking red "ERROR" between whites brackets (ANSI COLORS)
    # info messages are in yellow, and success messages are in green
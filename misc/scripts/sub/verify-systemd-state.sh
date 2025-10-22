#!/bin/bash


# https://www.man7.org/linux/man-pages/man1/systemctl.1.html#COMMANDS

function check_initializing_system {
    # Vérifie l'état système
    SYSTEM_STATE="$(systemctl is-system-running || true)"

    if [ "$SYSTEM_STATE" = "initializing" ]; then
        return 0
    else
        return 1
    fi
}

function check_starting_system {
    # Vérifie l'état système
    SYSTEM_STATE="$(systemctl is-system-running || true)"

    if [ "$SYSTEM_STATE" = "starting" ]; then
        return 0
    else
        return 1
    fi
}

function check_running_system {
    # Vérifie l'état système
    SYSTEM_STATE="$(systemctl is-system-running || true)"

    if [ "$SYSTEM_STATE" = "running" ]; then
        return 0
    else
        return 1
    fi
}

function check_degraded_system {
    # Vérifie l'état système
    SYSTEM_STATE="$(systemctl is-system-running || true)"

    if [ "$SYSTEM_STATE" = "degraded" ]; then
        return 0
    else
        return 1
    fi
}

function check_maintenance_system {
    # Vérifie l'état système
    SYSTEM_STATE="$(systemctl is-system-running || true)"

    if [ "$SYSTEM_STATE" = "maintenance" ]; then
        return 0
    else
        return 1
    fi
}

function check_stopping_system {
    # Vérifie l'état système
    SYSTEM_STATE="$(systemctl is-system-running || true)"

    if [ "$SYSTEM_STATE" = "stopping" ]; then
        return 0
    else
        return 1
    fi
}

function check_offline_system {
    # Vérifie l'état système
    SYSTEM_STATE="$(systemctl is-system-running || true)"

    if [ "$SYSTEM_STATE" = "offline" ]; then
        return 0
    else
        return 1
    fi
}

function check_unknown_system {
    # Vérifie l'état système
    SYSTEM_STATE="$(systemctl is-system-running || true)"

    if [ "$SYSTEM_STATE" = "unknown" ]; then
        return 0
    else
        return 1
    fi
}
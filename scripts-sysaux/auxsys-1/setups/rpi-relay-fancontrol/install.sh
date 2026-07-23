#!/bin/bash
set -e

function install_fancontrol() {
sudo tee /usr/local/bin/rpi-relay-fancontrol.sh >/dev/null <<'FINALEOF'
#!/bin/bash
#
# rpi-relay-fancontrol.sh
#
# Contrôle un ventilateur Raspberry Pi via deux relais :
#   - relais 1 (GPIO_VOLTAGE) : sélectionne 3,3 V (NC) ou 5 V (NO)
#   - relais 2 (GPIO_POWER)   : coupe/active l'alimentation du ventilateur
#
# Les relais sont actifs à LOW.
#
# Seuils avec hysteresis :
#   OFF  -> LOW  à TEMP_LOW_ON
#   LOW  -> OFF  à TEMP_LOW_OFF
#   LOW  -> HIGH à TEMP_HIGH_ON
#   HIGH -> LOW  à TEMP_HIGH_OFF
#
# Plages mortes intentionnelles :
#   45-50 °C : selon historique, OFF ou LOW
#   60-65 °C : selon historique, LOW ou HIGH
#

set -Eeuo pipefail

# Variables par défaut, surchargeables par /etc/default/rpi-relay-fancontrol
# ou par un autre fichier passé avec --config.
CONFIG_FILE="/etc/default/rpi-relay-fancontrol"
# shellcheck source=/dev/null
[[ -r "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

GPIO_VOLTAGE=${GPIO_VOLTAGE:-21}
GPIO_POWER=${GPIO_POWER:-20}
TEMP_FILE=${TEMP_FILE:-"/sys/class/thermal/thermal_zone0/temp"}

TEMP_LOW_ON=${TEMP_LOW_ON:-50}
TEMP_LOW_OFF=${TEMP_LOW_OFF:-45}
TEMP_HIGH_ON=${TEMP_HIGH_ON:-65}
TEMP_HIGH_OFF=${TEMP_HIGH_OFF:-60}

POLL_INTERVAL=${POLL_INTERVAL:-5}
SWITCH_DELAY=${SWITCH_DELAY:-0.30}

LOG_TO_SYSLOG=${LOG_TO_SYSLOG:-0}
LOG_FILE=${LOG_FILE:-""}

# Modules relais actifs à LOW :
# 0 = relais activé
# 1 = relais désactivé
readonly RELAY_ON=0
readonly RELAY_OFF=1

DRY_RUN=0
CURRENT_MODE="unknown"
GPIO_TOOL="pinctrl"

log()
{
    local msg
    msg="$(date '+%Y-%m-%d %H:%M:%S') [rpi-relay-fancontrol] $*"
    printf '%s\n' "$msg"

    if [[ "$LOG_TO_SYSLOG" -eq 1 ]] && command -v logger >/dev/null 2>&1; then
        logger -t rpi-relay-fancontrol "$*"
    fi

    if [[ -n "$LOG_FILE" ]]; then
        printf '%s\n' "$msg" >> "$LOG_FILE" || true
    fi
}

detect_gpio_tool()
{
    if command -v pinctrl >/dev/null 2>&1; then
        GPIO_TOOL="pinctrl"
    elif command -v raspi-gpio >/dev/null 2>&1; then
        GPIO_TOOL="raspi-gpio"
    else
        log "ERREUR : ni pinctrl ni raspi-gpio n'est disponible."
        exit 1
    fi
}

gpio_write()
{
    local gpio="$1"
    local value="$2"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "[DRY-RUN] gpio_write($gpio, $value)"
        return 0
    fi

    case "$GPIO_TOOL" in
        pinctrl)
            if [[ "$value" -eq 1 ]]; then
                pinctrl set "$gpio" op dh
            else
                pinctrl set "$gpio" op dl
            fi
            ;;

        raspi-gpio)
            raspi-gpio set "$gpio" op
            if [[ "$value" -eq 1 ]]; then
                raspi-gpio set "$gpio" dh
            else
                raspi-gpio set "$gpio" dl
            fi
            ;;
    esac
}

initialize_gpio()
{
    # État sûr :
    # relais 2 coupé, puis relais 1 placé sur son contact NC 3,3 V.
    gpio_write "$GPIO_POWER" "$RELAY_OFF"
    gpio_write "$GPIO_VOLTAGE" "$RELAY_OFF"

    CURRENT_MODE="off"
    log "GPIO initialisés : ventilateur arrêté."
}

fan_off()
{
    [[ "$CURRENT_MODE" == "off" ]] && return 0

    # Coupure générale avant toute commutation de tension.
    gpio_write "$GPIO_POWER" "$RELAY_OFF"

    CURRENT_MODE="off"
    log "Mode OFF : alimentation du ventilateur coupée."
}

fan_low()
{
    [[ "$CURRENT_MODE" == "low" ]] && return 0

    # Coupure avant changement du sélecteur.
    gpio_write "$GPIO_POWER" "$RELAY_OFF"
    sleep "$SWITCH_DELAY"

    # Relais 1 au repos : COM relié au NC 3,3 V.
    gpio_write "$GPIO_VOLTAGE" "$RELAY_OFF"
    sleep "$SWITCH_DELAY"

    # Relais 2 activé : alimentation transmise.
    gpio_write "$GPIO_POWER" "$RELAY_ON"

    CURRENT_MODE="low"
    log "Mode LOW : ventilateur alimenté en 3,3 V."
}

fan_high()
{
    [[ "$CURRENT_MODE" == "high" ]] && return 0

    # Coupure avant changement du sélecteur.
    gpio_write "$GPIO_POWER" "$RELAY_OFF"
    sleep "$SWITCH_DELAY"

    # Relais 1 activé : COM relié au NO 5 V.
    gpio_write "$GPIO_VOLTAGE" "$RELAY_ON"
    sleep "$SWITCH_DELAY"

    # Relais 2 activé : alimentation transmise.
    gpio_write "$GPIO_POWER" "$RELAY_ON"

    CURRENT_MODE="high"
    log "Mode HIGH : ventilateur alimenté en 5 V."
}

shutdown()
{
    # Désactiver le trap EXIT pour éviter un double appel.
    trap - EXIT

    log "Arrêt demandé : coupure du ventilateur."

    # Priorité absolue à la coupure générale.
    gpio_write "$GPIO_POWER" "$RELAY_OFF" 2>/dev/null || true
    gpio_write "$GPIO_VOLTAGE" "$RELAY_OFF" 2>/dev/null || true

    exit 0
}

read_temperature()
{
    local raw_temperature

    [[ -r "$TEMP_FILE" ]] || {
        log "ERREUR : température CPU inaccessible : $TEMP_FILE"
        return 1
    }

    read -r raw_temperature < "$TEMP_FILE"

    [[ "$raw_temperature" =~ ^[0-9]+$ ]] || {
        log "ERREUR : valeur de température invalide."
        return 1
    }

    printf '%d\n' "$((raw_temperature / 1000))"
}

select_mode()
{
    local temperature="$1"

    # Hystérésis : les seuils d'activation et de désactivation diffèrent
    # pour éviter les commutations rapides autour d'une température seuil.
    # Plages mortes :
    #   45-50 °C -> selon l'historique, le ventilateur est OFF ou LOW
    #   60-65 °C -> selon l'historique, le ventilateur est LOW ou HIGH
    case "$CURRENT_MODE" in
        off)
            if (( temperature >= TEMP_HIGH_ON )); then
                fan_high
            elif (( temperature >= TEMP_LOW_ON )); then
                fan_low
            fi
            ;;

        low)
            if (( temperature >= TEMP_HIGH_ON )); then
                fan_high
            elif (( temperature <= TEMP_LOW_OFF )); then
                fan_off
            fi
            ;;

        high)
            if (( temperature <= TEMP_LOW_OFF )); then
                fan_off
            elif (( temperature <= TEMP_HIGH_OFF )); then
                fan_low
            fi
            ;;

        *)
            fan_off
            ;;
    esac
}

usage()
{
    cat <<EOF
Usage: ${0##*/} [OPTIONS]

Options :
--dry-run       Simuler les commandes GPIO sans toucher au matériel
--config FILE   Utiliser FILE comme fichier de configuration
-h, --help      Afficher cette aide
EOF
}

parse_args()
{
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log "ERREUR : option inconnue : $1"
                usage
                exit 1
                ;;
        esac
    done
}

main()
{
    parse_args "$@"

    # Relecture de la config si spécifiée via --config.
    # shellcheck source=/dev/null
    [[ -r "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

    # Geler la configuration avant la boucle principale.
    readonly GPIO_VOLTAGE GPIO_POWER TEMP_FILE \
        TEMP_LOW_ON TEMP_LOW_OFF TEMP_HIGH_ON TEMP_HIGH_OFF \
        POLL_INTERVAL SWITCH_DELAY LOG_TO_SYSLOG LOG_FILE CONFIG_FILE

    if [[ "$DRY_RUN" -eq 0 ]]; then
        [[ "$EUID" -eq 0 ]] || {
            log "ERREUR : ce programme doit être exécuté par root."
            exit 1
        }

        detect_gpio_tool
    else
        GPIO_TOOL="dry-run"
    fi

    initialize_gpio

    trap shutdown SIGINT SIGTERM SIGHUP EXIT

    log "Contrôle autonome démarré avec $GPIO_TOOL."
    [[ "$DRY_RUN" -eq 1 ]] && log "Mode DRY-RUN activé : aucune commande GPIO ne sera exécutée."
    log "Seuils : OFF<=${TEMP_LOW_OFF}°C, LOW>=${TEMP_LOW_ON}°C, HIGH>=${TEMP_HIGH_ON}°C."

    while true; do
        if temperature="$(read_temperature)"; then
            select_mode "$temperature"
            log "CPU=${temperature}°C ; mode=${CURRENT_MODE}"
        else
            # En cas d'erreur de mesure, ventilation maximale par sécurité.
            log "Mesure impossible : activation du mode HIGH de sécurité."
            fan_high
        fi

        sleep "$POLL_INTERVAL"
    done
}

main "$@"
FINALEOF

sudo chmod 755 /usr/local/bin/rpi-relay-fancontrol.sh
sudo ln -sfn /usr/local/bin/rpi-relay-fancontrol.sh /usr/bin/rpi-relay-fancontrol

}

function install_service() {
sudo tee /etc/systemd/system/rpi-relay-fancontrol.service >/dev/null <<'EOF'
[Unit]
Description=Contrôle autonome du ventilateur CPU par deux relais GPIO
# Description=Contrôle ventilateur Raspberry Pi par relais
After=multi-user.target
# After=local-fs.target
ConditionPathExists=/sys/class/thermal/thermal_zone0/temp

[Service]
Type=simple
# ExecStartPre=/usr/bin/sleep 20s
# ExecStart=/usr/local/bin/rpi-relay-fancontrol.sh
ExecStart=/usr/local/bin/rpi-relay-fancontrol.sh --config /etc/default/rpi-relay-fancontrol.default
Restart=always
RestartSec=15
TimeoutStopSec=10

# Le service doit accéder aux GPIO et fonctionne donc comme root.
User=root
Group=root

StandardOutput=journal
StandardError=journal
SyslogIdentifier=rpi-relay-fancontrol

[Install]
WantedBy=multi-user.target

EOF
}

function remove_old_timer(){
sudo rm -f /etc/systemd/system/rpi-relay-fancontrol.timer

# sudo tee /etc/systemd/system/rpi-relay-fancontrol.timer >/dev/null <<'EOF'
# [Unit]
# Description=Lancement différé du contrôle du ventilateur CPU

# [Timer]
#OnBootSec=20s
# AccuracySec=1s
# Unit=rpi-relay-fancontrol.service
#
# [Install]
# WantedBy=timers.target
# EOF

}


function define_default_config() {
if [ ! -e /etc/default/rpi-relay-fancontrol.default ]; then

sudo tee /etc/default/rpi-relay-fancontrol.default >/dev/null <<'EOF'
# Configuration pour rpi-relay-fancontrol.sh
# A copier vers /etc/default/rpi-relay-fancontrol

# GPIOs utilisés par le script.
# GPIO_VOLTAGE : relais de sélection de tension (3,3 V / 5 V)
# GPIO_POWER   : relais d'alimentation générale du ventilateur
GPIO_VOLTAGE=21
GPIO_POWER=20

# Fichier de température du CPU.
TEMP_FILE="/sys/class/thermal/thermal_zone0/temp"

# Seuils avec hysteresis (en degrés Celsius).
# Les relais changent d'état aux seuils d'activation.
# Ils reviennent à l'état précédent aux seuils de désactivation.
TEMP_LOW_ON=50
TEMP_LOW_OFF=45
TEMP_HIGH_ON=65
TEMP_HIGH_OFF=60

# Intervalle entre deux mesures de température (en secondes).
POLL_INTERVAL=5

# Délai entre deux commutations de relais (en secondes).
SWITCH_DELAY=0.30

# Logging.
# 1 = envoyer les messages vers syslog, 0 = désactivé.
LOG_TO_SYSLOG=0

# Chemin vers un fichier de log (laissez vide pour stdout uniquement).
LOG_FILE=""
EOF

fi
}

function stop_timer() {
sudo systemctl stop rpi-relay-fancontrol.timer
sudo systemctl disable rpi-relay-fancontrol.timer
}

function reload_systemd(){
sudo systemctl daemon-reload
}

function enable_now_service(){
sudo systemctl enable --now rpi-relay-fancontrol.service
}

function restart_service() {
sudo systemctl restart rpi-relay-fancontrol.service
}


function main(){

    define_default_config
    install_fancontrol

    # check if exists :  /etc/systemd/system/rpi-relay-fancontrol.timer
    # if yes call stop_timer and remove_old_timer functions
    if [ -e /etc/systemd/system/rpi-relay-fancontrol.timer ]; then
        stop_timer
        remove_old_timer
    fi
    install_service

    reload_systemd && enable_now_service 
    sleep 5s && restart_service


    systemctl status rpi-relay-fancontrol.service
    journalctl -u rpi-relay-fancontrol.service -f

}

# # Logs en direct :
# journalctl -u rpi-relay-fancontrol.service -f


main






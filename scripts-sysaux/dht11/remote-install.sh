#!/bin/bash
# remote-install.sh : Installation automatisée du module DHT11 (température & humidité) pour Raspberry Pi
# Usage : bash <(curl -sSL https://github.com/0x07CB/auxsys-scripts/raw/0x07cb-patch-4/scripts-sysaux/dht11/remote-install.sh)

set -e

# Couleurs pour affichage
RED="\033[31;1m"; GREEN="\033[32;1m"; YELLOW="\033[33;1m"; NC="\033[0m"

function info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
function ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
function err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# Vérification root
if [ "$(id -u)" -ne 0 ]; then
    err "Ce script doit être lancé en tant que root (sudo)."
    exit 1
fi

# Création dossier temporaire
TMPDIR="$(mktemp -d)"
info "Clonage du dépôt dans $TMPDIR ..."
git clone --depth 1 https://github.com/0x07CB/auxsys-scripts.git "$TMPDIR/auxsys-scripts"

DHT11_DIR="$TMPDIR/auxsys-scripts/scripts-sysaux/dht11"
if [ ! -d "$DHT11_DIR" ]; then
    err "Le dossier dht11 n'a pas été trouvé dans le dépôt. Abandon."
    exit 2
fi

cd "$DHT11_DIR"

info "Installation et configuration du module DHT11 ..."

# Lancement du setup pigpio
if [ -f "setup-pigpio.sh" ]; then
    bash setup-pigpio.sh
else
    err "setup-pigpio.sh introuvable."
    exit 3
fi

# Installation des scripts et dépendances
if [ -f "install-scripts.sh" ]; then
    bash install-scripts.sh
else
    err "install-scripts.sh introuvable."
    exit 4
fi

ok "Installation terminée. Vous pouvez utiliser les scripts DHT11."

# Nettoyage
info "Suppression du dossier temporaire ..."
rm -rf "$TMPDIR"

exit 0

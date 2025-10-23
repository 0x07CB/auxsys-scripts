#!/bin/bash
set -euo pipefail

# --- Config via variables d’environnement ---
G="${GPIO_LED_GREEN:-18}"      # Vert   -> BCM18 (pin 12)
Y="${GPIO_LED_YELLOW:-23}"     # Jaune  -> BCM23 (pin 16)
R="${GPIO_LED_RED:-24}"        # Rouge  -> BCM24 (pin 18)
LOW="${LED_ACTIVE_LOW:-0}"     # 1 si LED active au niveau bas
POLL="${LED_POLL_INTERVAL:-2}" # période de scrutation en secondes

# --- Primitives GPIO ---
on()  { local p="$1"; if [ "$LOW" = 1 ]; then pinctrl set "$p" op dl; else pinctrl set "$p" op dh; fi; }
off() { local p="$1"; if [ "$LOW" = 1 ]; then pinctrl set "$p" op dh; else pinctrl set "$p" op dl; fi; }

# --- Gestion du clignotement ---
declare -A BLINK_PIDS=()
start_blink() {                # start_blink <pin> <period>
  local p="$1" per="${2:-0.5}"
  ( while :; do on "$p"; sleep "$per"; off "$p"; sleep "$per"; done ) & 
  BLINK_PIDS["$p"]=$!
}
stop_blinks() {
  for pid in "${BLINK_PIDS[@]:-}"; do kill "$pid" 2>/dev/null || true; done
  BLINK_PIDS=()
}

# --- Appliquer un motif en fonction de l’état ---
apply_pattern() {
  local st="$1"
  stop_blinks
  off "$G"; off "$Y"; off "$R"

  case "$st" in
    running)      on "$G" ;;
    degraded)     on "$Y" ;;
    maintenance)  on "$R" ;;
    stopping)     start_blink "$Y" 1.0 ;;
    initializing) start_blink "$Y" 0.25 ;;
    starting)     start_blink "$Y" 0.5 ;;
    offline)      start_blink "$R" 1.0 ;;
    unknown|*)    start_blink "$R" 0.25 ;;
  esac
}

# --- Lecture de l’état (avec override dynamique) ---
get_state() {
  # Override optionnel: `sudo systemctl set-environment LED_STATE=running|degraded|...`
  local o
  o="$(systemctl show-environment 2>/dev/null | awk -F= '/^LED_STATE=/{print $2}' || true)"
  if [ -n "$o" ]; then echo "$o"; return; fi

  systemctl is-system-running 2>/dev/null || echo unknown
}

cleanup() { stop_blinks; off "$G"; off "$Y"; off "$R"; }
trap cleanup EXIT INT TERM

# Sécurité au démarrage
apply_pattern unknown

prev=""
while :; do
  st="$(get_state)"
  if [ "$st" != "$prev" ]; then
    apply_pattern "$st"
    prev="$st"
  fi
  sleep "$POLL"
done

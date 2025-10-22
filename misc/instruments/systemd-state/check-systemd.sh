#!/bin/bash
set -euo pipefail

G="${GPIO_LED_GREEN:-18}"
Y="${GPIO_LED_YELLOW:-23}"
R="${GPIO_LED_RED:-24}"
LOW="${LED_ACTIVE_LOW:-0}"

on()  { pin=$1; if [ "$LOW" = 1 ]; then pinctrl set "$pin" op dl; else pinctrl set "$pin" op dh; fi; }
off() { pin=$1; if [ "$LOW" = 1 ]; then pinctrl set "$pin" op dh; else pinctrl set "$pin" op dl; fi; }

# blink <pin> <period_seconds>
blink() { pin=$1; per="${2:-0.5}"; while :; do on "$pin"; sleep "$per"; off "$pin"; sleep "$per"; done & }

# remise à zéro
off "$G"; off "$Y"; off "$R"
# tuer d'anciens clignotements éventuels
kill $(jobs -p) 2>/dev/null || true

state="$(systemctl is-system-running --wait 2>/dev/null || echo unknown)"

case "$state" in
  running)      on "$G" ;;
  degraded)     on "$Y" ;;
  maintenance)  on "$R" ;;
  stopping)     blink "$Y" 1.0 ;;
  initializing) blink "$Y" 0.25 ;;
  starting)     blink "$Y" 0.5 ;;
  offline)      blink "$R" 1.0 ;;
  unknown|*)    blink "$R" 0.25 ;;
esac
wait

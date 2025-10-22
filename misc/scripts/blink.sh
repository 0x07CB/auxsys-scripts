#!/usr/bin/env bash
# blink.sh — fait clignoter une LED via pinctrl, en BACKGROUND

# Paramètres (surchargables par variables d'env)
PIN="${LED_PIN:-24}"
ITER="${ITER:-10}"          # nombre d'itérations
PERIOD="${PERIOD:-0.5}"     # secondes entre bascules
FORCE_START="${FORCE_START:-}" # "high" | "low" | vide (auto via pinctrl get)

# Assure le mode "output"
pinctrl set "$PIN" op >/dev/null 2>&1

blink() {
  local state=""
  # Détermine l'état de départ
  if [[ "$FORCE_START" == "high" ]]; then
    pinctrl set "$PIN" op dh
    state="high"
  elif [[ "$FORCE_START" == "low" ]]; then
    pinctrl set "$PIN" op dl
    state="low"
  else
    # Auto : lit l'état actuel
    if pinctrl get "$PIN" | grep -qE '\b(dh|high)\b'; then
      state="high"
    else
      state="low"
    fi
  fi

  for ((i=1; i<=ITER; i++)); do
    if [[ "$state" == "high" ]]; then
      pinctrl set "$PIN" op dl
      state="low"
    else
      pinctrl set "$PIN" op dh
      state="high"
    fi
    sleep "$PERIOD"
  done
}

# Lance la boucle FOR en arrière-plan pour que "le reste du programme continue"
blink &

# --- Le reste de ton programme continue ici ---
echo "[main] La boucle clignote en arrière-plan (PID=$!)."
# ... tes autres commandes ...
# Si tu veux attendre la fin du clignotement à un moment :
# wait %1

Conforme. Matrice tri-LED pour `systemctl is-system-running`.
Hypothèses :

* Vert = BCM18 (pin physique 12), Jaune = BCM23 (pin 16), Rouge = BCM24 (pin 18).
* LED actives au niveau haut (inverse via variable si nécessaire).

| État `is-system-running` | Vert (18)   | Jaune (23)       | Rouge (24)       | Sémantique / usage opératoire                                               |
| ------------------------ | ----------- | ---------------- | ---------------- | --------------------------------------------------------------------------- |
| `initializing`           | OFF         | **BLINK rapide** | OFF              | Boot très précoce. Attendre la stabilisation.                               |
| `starting`               | OFF         | **BLINK normal** | OFF              | Démarrage en cours. Ne pas prendre de décision irréversible.                |
| `running`                | **ON fixe** | OFF              | OFF              | Système opérationnel. Chemin nominal.                                       |
| `degraded`               | OFF         | **ON fixe**      | OFF              | Opérationnel avec échecs d’unités. Alerte *warning*, collecte des journaux. |
| `maintenance`            | OFF         | OFF              | **ON fixe**      | Mode rescue/emergency. Interventions manuelles uniquement.                  |
| `stopping`               | OFF         | **BLINK lent**   | OFF              | Arrêt en cours. Cesser les traitements.                                     |
| `offline`                | OFF         | OFF              | **BLINK lent**   | PID1 non-systemd / gestionnaire inactif. Fallback sûr.                      |
| `unknown`                | OFF         | OFF              | **BLINK rapide** | État indéterminé. Fallback et diagnostics.                                  |

Définitions de cadence (indicatif) :

* rapide ≈ 0,25 s ON / 0,25 s OFF
* normal ≈ 0,5 s / 0,5 s
* lent ≈ 1,0 s / 1,0 s

### Variables d’environnement

```
GPIO_LED_GREEN=18
GPIO_LED_YELLOW=23
GPIO_LED_RED=24
LED_ACTIVE_LOW=0   # mettre 1 si vos LED sont à anode commune (ON niveau bas)
```

### Script Bash (pinctrl)

```bash
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
```

### Rappel des correspondances broches (confirmation)

* BCM18 → **pin 12**
* BCM23 → **pin 16**
* BCM24 → **pin 18**

Efficience optimale.

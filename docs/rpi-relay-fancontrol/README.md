# rpi-relay-fancontrol

Contrôle autonome d'un ventilateur Raspberry Pi via deux relais, avec sélection de tension (3,3 V ou 5 V) et coupure générale.

## Principe

Le script utilise deux GPIOs :

- `GPIO_VOLTAGE` : relais SPDT qui commute le ventilateur entre le contact **NC 3,3 V** et le contact **NO 5 V**.
- `GPIO_POWER` : relais SPST qui active ou coupe l'alimentation du ventilateur.

Les relais sont actifs à **LOW** (niveau bas).

## Modes de fonctionnement

| Mode | GPIO_VOLTAGE | GPIO_POWER | Ventilateur |
|------|--------------|------------|-------------|
| OFF  | HIGH (désactivé, NC 3,3 V) | HIGH (désactivé) | Arrêté |
| LOW  | HIGH (désactivé, NC 3,3 V) | LOW (activé)     | 3,3 V |
| HIGH | LOW (activé, NO 5 V)       | LOW (activé)     | 5 V |

## Seuils et hysteresis

Les seuils sont exprimés en degrés Celsius :

- `TEMP_LOW_ON`  (défaut 50) : passage OFF → LOW
- `TEMP_LOW_OFF` (défaut 45) : passage LOW → OFF
- `TEMP_HIGH_ON` (défaut 65) : passage LOW → HIGH
- `TEMP_HIGH_OFF`(défaut 60) : passage HIGH → LOW

L'hysteresis évite les commutations rapides autour d'un seuil. Elle crée deux plages mortes :

- **45–50 °C** : le ventilateur reste dans l'état précédent (OFF ou LOW).
- **60–65 °C** : le ventilateur reste dans l'état précédent (LOW ou HIGH).

## Fichiers

- `scripts/rpi-relay-fancontrol.sh` : script principal.
- `scripts/rpi-relay-fancontrol.default` : exemple de fichier de configuration.
- `scripts/rpi-relay-fancontrol.service` : fichier d'unité systemd.

## Installation

1. Copier le script et le rendre exécutable :

   ```bash
   sudo cp scripts/rpi-relay-fancontrol.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/rpi-relay-fancontrol.sh
   ```

2. Installer le fichier de configuration :

   ```bash
   sudo cp scripts/rpi-relay-fancontrol.default /etc/default/rpi-relay-fancontrol
   ```

   Modifier les valeurs si nécessaire.

3. Installer et activer le service systemd :

   ```bash
   sudo cp scripts/rpi-relay-fancontrol.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now rpi-relay-fancontrol.service
   ```

## Utilisation en ligne de commande

```bash
sudo /usr/local/bin/rpi-relay-fancontrol.sh
```

Options :

- `--dry-run` : simuler les commandes GPIO sans agir sur le matériel.
- `--config FILE` : utiliser un autre fichier de configuration.
- `-h, --help` : afficher l'aide.

### Test sans matériel

```bash
sudo /usr/local/bin/rpi-relay-fancontrol.sh --dry-run
```

Le mode `--dry-run` logue les actions sans exécuter `pinctrl` ni `raspi-gpio`.

## Configuration

Le fichier `/etc/default/rpi-relay-fancontrol` peut surcharger toutes les variables :

```bash
GPIO_VOLTAGE=20
GPIO_POWER=21
TEMP_LOW_ON=50
TEMP_LOW_OFF=45
TEMP_HIGH_ON=65
TEMP_HIGH_OFF=60
POLL_INTERVAL=5
SWITCH_DELAY=0.30
LOG_TO_SYSLOG=0
LOG_FILE=""
```

## Logging

- Par défaut, les messages sont envoyés sur `stdout`.
- `LOG_TO_SYSLOG=1` envoie également les messages à syslog via `logger`.
- `LOG_FILE="/var/log/rpi-relay-fancontrol.log"` ajoute les messages dans un fichier.

## Compatibilité GPIO

Le script détecte automatiquement l'outil disponible :

- `pinctrl` (Raspberry Pi OS récent)
- `raspi-gpio` (anciennes versions)

Si aucun outil n'est trouvé, le script s'arrête.

## Câblage (exemple)

- GPIO 20 → bobine du relais de sélection de tension (3,3 V / 5 V).
- GPIO 21 → bobine du relais d'alimentation générale.
- Relais de tension : contact **NC** relié à l'alimentation 3,3 V, contact **NO** relié à 5 V, **COM** au ventilateur (via le relais d'alimentation).
- Relais d'alimentation : une borne du ventilateur au **COM**, l'autre à la masse (ou inverse selon le type).

## Validation

Lancer un stress test et observer les logs :

```bash
sudo stress --cpu 4 --timeout 120
```

Vérifier que les transitions OFF → LOW → HIGH se produisent dans l'ordre attendu et que le relais d'alimentation n'est coupé que brièvement lors des changements de tension.

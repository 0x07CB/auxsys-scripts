## Note — [rpi-relay-fancontrol.sh](cci:7://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:0:0-0:0)

### Ce que fait le script

Contrôle autonome d'un ventilateur Raspberry Pi à l'aide de deux relais :
- **Relais 1 (`GPIO_VOLTAGE`)** : sélectionne 3,3 V (contact NC) ou 5 V (contact NO).
- **Relais 2 (`GPIO_POWER`)** : coupe ou active l'alimentation du ventilateur.

Trois modes : `OFF`, `LOW` (3,3 V), `HIGH` (5 V). Les relais sont actifs à LOW.

### Seuils de température (hystérésis)

| Transition | Seuil |
|---|---|
| OFF → LOW | 50 °C |
| LOW → OFF | 45 °C |
| LOW → HIGH | 65 °C |
| HIGH → LOW | 60 °C |

Les plages mortes 45–50 °C et 60–65 °C évitent les commutations rapides.

### Modifications apportées

- **Configuration externe** via `/etc/default/rpi-relay-fancontrol` ou `--config`.
- **Mode `--dry-run`** : simule les actions GPIO sans matériel.
- **Logging** : stdout, syslog (`LOG_TO_SYSLOG=1`) et fichier (`LOG_FILE`).
- **Compatibilité GPIO** : `pinctrl` ou `raspi-gpio` corrigé.
- **Arrêt propre** : [shutdown](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:171:0-183:1) ne se déclenche plus deux fois sur signal.
- **Fichiers ajoutés** : fichier de config d'exemple, service systemd, [README.md](cci:7://file:///home/rds/Bureau/WORK/README.md:0:0-0:0).

### Usage

```bash
sudo /usr/local/bin/rpi-relay-fancontrol.sh
sudo /usr/local/bin/rpi-relay-fancontrol.sh --dry-run
sudo /usr/local/bin/rpi-relay-fancontrol.sh --config /chemin/vers/config
```

### Fonctions principales

- [detect_gpio_tool()](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:68:0-78:1) : détecte `pinctrl` ou `raspi-gpio`.
- [gpio_write()](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:80:0-108:1) : écrit l'état d'un GPIO (ou logue en dry-run).
- [initialize_gpio()](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:111:0-120:1) : met les relais en état sûr OFF.
- [fan_off()](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:122:0-131:1) / [fan_low()](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:133:0-150:1) / [fan_high()](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:151:0-168:1) : commutent les relais dans l'ordre de sécurité.
- [read_temperature()](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:181:0-198:1) : lit `/sys/class/thermal/thermal_zone0/temp`.
- [select_mode()](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:201:0-239:1) : choisit le mode selon la température et l'hystérésis.
- [shutdown()](cci:1://file:///home/rds/Bureau/WORK/scripts/rpi-relay-fancontrol.sh:171:0-183:1) : coupure des relais à l'arrêt.

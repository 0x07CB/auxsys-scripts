# auxsys-scripts
Rpi3 custom personnals scripts and automations

## Structure du projet

```
scripts-sysaux/
├── dht11/
│   ├── dht.py
│   ├── espeak-dht11-humidity.sh
│   ├── espeak-dht11-temperature.sh
│   ├── install-scripts.sh
│   └── requirements.txt
├── light_auto/
│   ├── install-scripts.sh
│   ├── light_auto.py
│   ├── requirements.txt
│   ├── services/
│   │   └── light-auto.service
│   └── sounds/
│       ├── alert07.wav
│       └── alert08.wav
```

## 1. dht11 : Lecture du capteur DHT11 (température & humidité)

- **dht.py** : Script Python pour lire les données du capteur DHT11 via pigpio.
- **espeak-dht11-humidity.sh** / **espeak-dht11-temperature.sh** : Scripts shell pour vocaliser la température ou l'humidité via espeak-ng.
- **install-scripts.sh** : Installe les scripts, dépendances et crée les liens symboliques nécessaires.
- **requirements.txt** : Dépendances Python nécessaires (pigpio, gpiozero, etc).

### Installation (dht11)
```bash
cd scripts-sysaux/dht11
sudo ./install-scripts.sh
```

### Utilisation
- Pour lire la température :
  ```bash
  dht11.py --temperature
  ```
- Pour lire l'humidité :
  ```bash
  dht11.py --humidity
  ```
- Pour vocaliser la température :
  ```bash
  espeak-dht11-temperature.sh
  ```
- Pour vocaliser l'humidité :
  ```bash
  espeak-dht11-humidity.sh
  ```

## 2. light_auto : Veilleuse automatique selon la luminosité

- **light_auto.py** : Script Python pour contrôler une LED selon la luminosité ambiante (capteur + GPIO).
- **install-scripts.sh** : Installe le service systemd, les sons, le script et les dépendances.
- **services/light-auto.service** : Fichier de service systemd pour lancer le script au démarrage.
- **sounds/** : Sons d'alerte joués lors des changements d'état.
- **requirements.txt** : Dépendances Python nécessaires (pygame, RPi.GPIO).

### Installation (light_auto)
```bash
cd scripts-sysaux/light_auto
sudo ./install-scripts.sh
```

### Utilisation
- Le service `light-auto` peut être activé/désactivé via systemd :
  ```bash
  sudo systemctl enable --now light-auto.service
  sudo systemctl status light-auto.service
  ```

## Dépendances générales
- Python 3
- pigpio, gpiozero, RPi.GPIO, pygame
- espeak-ng, sox
- Un Raspberry Pi avec accès aux GPIO

## Licence
MIT License

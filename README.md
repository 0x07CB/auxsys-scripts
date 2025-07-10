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
│   ├── install-python-deps.sh
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
- **install-python-deps.sh** : Installe les dépendances Python avec options d'installation interactive.
- **requirements.txt** : Dépendances Python nécessaires (pigpio, gpiozero, etc).

### Installation (dht11)
```bash
cd scripts-sysaux/dht11
sudo ./install-scripts.sh
```

### Installation des dépendances Python (DHT11)

Le script `install-python-deps.sh` vous propose plusieurs modes d'installation :
- **venv local** : crée un environnement virtuel Python dans le dossier courant.
- **utilisateur courant** : installe les paquets pour l'utilisateur actuel.
- **autre utilisateur** : installe pour un utilisateur système spécifique.

Lancez :
```bash
cd scripts-sysaux/dht11
./install-python-deps.sh
```
et suivez les instructions.

> **Note** : L'installation complète (`install-scripts.sh`) gère aussi la copie des scripts, la création des liens symboliques, et l'ajout au groupe `audio` si besoin.

### Mise à jour des scripts

Pour mettre à jour les scripts, relancez simplement le script d'installation :
```bash
sudo ./install-scripts.sh
```
Les anciens fichiers sont sauvegardés avec l'extension `.bak` si besoin.

### Instructions pour connecter le capteur DHT11

Le capteur DHT11 possède trois broches principales :
- **VCC** : à connecter à une source d'alimentation 5V ou 3.3V sur le Raspberry Pi.
- **DATA** : à connecter à une broche GPIO du Raspberry Pi (par défaut GPIO 4).
- **GND** : à connecter à une broche de masse (GND) sur le Raspberry Pi.

#### Étapes pour connecter le capteur DHT11 :
1. Identifiez les broches du capteur DHT11 (VCC, DATA, GND).
2. Connectez la broche **VCC** à une broche d'alimentation 5V ou 3.3V du Raspberry Pi.
3. Connectez la broche **DATA** à la broche GPIO 4 (ou une autre broche GPIO si spécifiée dans le script).
4. Connectez la broche **GND** à une broche de masse (GND) du Raspberry Pi.
5. Assurez-vous que le démon pigpio est actif sur le Raspberry Pi :
   ```bash
   sudo pigpiod
   ```
6. Testez la connexion en exécutant le script :
   ```bash
   dht11.py --temperature --humidity
   ```

> **Note** : Ce script est compatible avec les Raspberry Pi 2, 3 et 4. Il n'a pas encore été testé sur le Raspberry Pi 5, mais une adaptation est prévue pour cette plateforme dans le futur.

### Utilisation
- Pour lire la température :
  ```bash
  dht11.py --temperature
  ```
- Pour lire l'humidité :
  ```bash
  dht11.py --humidity
  ```
- Pour lire température et humidité (par défaut si aucune option n’est précisée) :
  ```bash
  dht11.py
  ```
- Pour afficher la température en Fahrenheit :
  ```bash
  dht11.py --temperature --fahrenheit
  ```
- Pour personnaliser le symbole d’unité (exemple pour Celsius) :
  ```bash
  dht11.py --temperature --custom-celsius-unit="Degrés Celsius"
  ```
- Pour personnaliser le symbole d’unité pour Fahrenheit :
  ```bash
  dht11.py --temperature --fahrenheit --custom-fahrenheit-unit="Degrés Fahrenheit"
  ```
- Pour personnaliser le symbole d’unité pour l’humidité :
  ```bash
  dht11.py --humidity --custom-humidity-unit="Pourcents"
  ```
- Pour personnaliser le préfixe d’affichage :
  ```bash
  dht11.py --temperature --prefix-temperature="La température est de"
  dht11.py --humidity --prefix-humidity="Le taux d\'humidité est de"
  ```
- Pour utiliser la sortie standard (stdout) (par défaut) :
  ```bash
  dht11.py --temperature --use-stdout
  ```
- Pour supprimer le retour à la ligne à la fin de la sortie (utile pour l’intégration dans d’autres scripts) :
  ```bash
  dht11.py --temperature --no-line-return
  ```
- Pour spécifier la broche GPIO utilisée :
  ```bash
  dht11.py --gpio 17
  ```
- Pour spécifier l’adresse IP et le port du démon pigpio (par défaut : 127.0.0.1:8888) :
  ```bash
  dht11.py --host 192.168.1.10 --port 8888
  ```
- Pour afficher la version du script :
  ```bash
  dht11.py --version
  ```
- Pour vocaliser la température :
  ```bash
  espeak-dht11-temperature.sh
  ```
- Pour vocaliser l'humidité :
  ```bash
  espeak-dht11-humidity.sh
  ```

#### Résumé des options disponibles

| Option                        | Description                                                      | Valeur par défaut      |
|-------------------------------|------------------------------------------------------------------|------------------------|
| `--gpio`                      | Numéro de la broche GPIO                                         | 4                      |
| `--host`                      | Adresse IP du démon pigpio                                       | 127.0.0.1              |
| `--port`                      | Port du démon pigpio                                             | 8888                   |
| `--humidity`                  | Afficher l’humidité                                              | -                      |
| `--temperature`               | Afficher la température                                          | -                      |
| `--fahrenheit`                | Convertir la température en Fahrenheit                           | -                      |
| `--use-stdout`                | Utiliser la sortie standard                                      | True                   |
| `--no-line-return`            | Ne pas ajouter de retour à la ligne                              | False                  |
| `--custom-celsius-unit`       | Symbole de l’unité Celsius                                       | °C                     |
| `--custom-fahrenheit-unit`    | Symbole de l’unité Fahrenheit                                    | °F                     |
| `--custom-humidity-unit`      | Symbole de l’unité d’humidité                                    | %                      |
| `--prefix-temperature`        | Préfixe pour l’affichage de la température                       | "temperature: "        |
| `--prefix-humidity`           | Préfixe pour l’affichage de l’humidité                           | "humidity: "           |
| `--version`                   | Afficher la version du script                                    | -                      |

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

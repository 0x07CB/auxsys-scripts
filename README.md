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
3. Connectez la broche **DATA** à la broche GPIO 4 (ou une autre broche GPIO compatible, voir encadré ci-dessous).
4. Connectez la broche **GND** à une broche de masse (GND) du Raspberry Pi.
5. Assurez-vous que le démon pigpio est actif sur le Raspberry Pi :
   ```bash
   sudo pigpiod
   ```
6. Testez la connexion en exécutant le script :
   ```bash
   dht11.py --temperature --humidity
   ```

> **Important : Choix de la broche GPIO**
>
> - Le DHT11 peut être connecté à n'importe quelle broche GPIO numérique du Raspberry Pi (modèles 2, 3, 4), à condition qu'elle ne soit pas déjà utilisée par un autre périphérique ou une fonction spéciale (I2C, SPI, UART, etc.).
> - Par convention, la broche GPIO 4 (numérotation BCM) est souvent utilisée, mais ce n'est pas une obligation.
> - **Numérotation recommandée :** Toutes les instructions et scripts de ce projet utilisent la numérotation BCM (Broadcom), qui est la plus courante dans la documentation Raspberry Pi et dans les bibliothèques Python (pigpio, gpiozero, etc.).
> - **À éviter :** N'utilisez pas les broches réservées à l'alimentation (5V/3.3V), à la masse (GND), ni les broches déjà utilisées pour I2C (GPIO 2/3), UART (GPIO 14/15), SPI (GPIO 10/9/11), sauf si vous savez ce que vous faites.
> - **Exemples de GPIO compatibles (numérotation BCM) :**
>   - GPIO 4 (par défaut)
>   - GPIO 17
>   - GPIO 18
>   - GPIO 27
>   - GPIO 22
>   - GPIO 23
>   - GPIO 24
>   - GPIO 25
> - **Astuce :** Pour éviter toute confusion, vérifiez toujours que vous utilisez la numérotation BCM (et non la numérotation physique BOARD) dans vos scripts et branchements. La plupart des bibliothèques Python utilisent BCM par défaut.

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

## Configuration GPIO dans /boot/firmware/config.txt

Pour garantir le bon fonctionnement des scripts d'automatisation (capteur DHT11, capteur de luminosité, éclairage LED), il est nécessaire de configurer les broches GPIO au niveau du système. Depuis les dernières versions de Raspberry Pi OS et distributions similaires, cette configuration se fait dans le fichier `/boot/firmware/config.txt`.

### Où modifier ?

- Le fichier se trouve à l'emplacement : `/boot/firmware/config.txt`
- Il est accessible depuis le système principal (avec les droits root) ou en montant la carte SD sur un autre ordinateur.

### Bloc de configuration à ajouter ou vérifier

Ajoutez ou vérifiez la présence du bloc suivant à la fin du fichier (après toute configuration existante) :

```ini
[all]
# ECLAIRAGE LED
gpio=23=op,dl

# DHT11 SENSOR
gpio=4=ip

# capteur de luminosite
gpio=27=ip
```

### Détail par fonctionnalité

#### 1. Capteur DHT11 (Température & Humidité)
- **Ligne concernée :**
  ```ini
  gpio=4=ip
  ```
- **Explication :**
  - Configure la broche GPIO 4 en entrée (input) pour le capteur DHT11.
  - Si vous utilisez une autre broche (option `--gpio` dans les scripts), adaptez le numéro ici.

#### 2. Éclairage automatique (LED)
- **Ligne concernée :**
  ```ini
  gpio=23=op,dl
  ```
- **Explication :**
  - Configure la broche GPIO 23 en sortie (output) et à l'état bas par défaut (dl = drive low) pour piloter la LED d'éclairage.
  - Si vous changez la broche dans le script d'automatisation, adaptez ici aussi.

#### 3. Capteur de luminosité
- **Ligne concernée :**
  ```ini
  gpio=27=ip
  ```
- **Explication :**
  - Configure la broche GPIO 27 en entrée pour le capteur de luminosité.
  - À adapter si vous branchez le capteur sur une autre broche.

### Procédure

1. Ouvrez le fichier `/boot/firmware/config.txt` avec les droits administrateur :
   ```bash
   sudo nano /boot/firmware/config.txt
   ```
2. Ajoutez ou modifiez le bloc ci-dessus selon vos besoins matériels.
3. Enregistrez et quittez l'éditeur.
4. Redémarrez le Raspberry Pi pour que la configuration soit prise en compte :
   ```bash
   sudo reboot
   ```

> **Remarque :**
> - Si vous utilisez d'autres broches que celles par défaut dans les scripts, pensez à adapter à la fois la configuration dans ce fichier et les options de lancement des scripts (`--gpio`).
> - Cette configuration est indispensable pour garantir l'accès correct aux GPIO par les scripts Python et shell du projet.

## Licence
MIT License

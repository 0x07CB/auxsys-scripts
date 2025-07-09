#!/usr/bin/env python3
#coding: utf-8


from __future__ import absolute_import, division, print_function, unicode_literals

import time
import pigpio
import argparse
import sys

__version__ = '1.0.2'

def convert_celsius_to_fahrenheit(celsius: int):
    """
    Convertit une température en degrés Celsius en degrés Fahrenheit.

    Args:
        celsius (int): La température en degrés Celsius.

    Returns:
        float: La température convertie en degrés Fahrenheit.
    """
    return (celsius * 9/5) + 32


class DHT11(object):
    """
    La classe DHT11 est une version simplifiée du code du capteur DHT22 de joan2937.
    Vous pouvez trouver l'implémentation initiale ici :
    - https://github.com/srounet/pigpio/tree/master/EXAMPLES/Python/DHT22_AM2302_SENSOR

    Exemple d'utilisation :
    >>> pi = pigpio.pi()
    >>> sensor = DHT11(pi, 4)  # 4 est la broche GPIO de données connectée à votre capteur
    >>> for response in sensor:
    ...     print("Température : {}".format(response['temperature']))
    ...     print("Humidité : {}".format(response['humidity']))
    """

    def __init__(self, pi, gpio):
        """
        Args:
            pi (pigpio.pi): Une instance de la classe pigpio.pi pour contrôler les GPIO.
            gpio (int): Le numéro de la broche GPIO à laquelle le capteur DHT11 est connecté.
        """
        self.pi = pi
        self.gpio = gpio
        self.high_tick = 0
        self.bit = 40
        self.temperature = 0
        self.humidity = 0
        self.either_edge_cb = None
        self.setup()

    def setup(self):
        """
        Efface la résistance pull-up/down interne de la broche GPIO.
        Désactive tout watchdog actif sur cette broche.
        """
        self.pi.set_pull_up_down(self.gpio, pigpio.PUD_OFF)
        self.pi.set_watchdog(self.gpio, 0)
        self.register_callbacks()

    def register_callbacks(self):
        """
        Surveille les changements sur les fronts montants et descendants (EITHER_EDGE) en utilisant une fonction de rappel (callback).
        """
        self.either_edge_cb = self.pi.callback(
            self.gpio,
            pigpio.EITHER_EDGE,
            self.either_edge_callback
        )

    def either_edge_callback(self, gpio, level, tick):
        """
        Fonction de rappel pour les changements d'état (fronts montants ou descendants) sur la broche GPIO.
        Elle est appelée à chaque changement d'état de la broche GPIO.
        Accumule les 40 bits de données provenant du capteur DHT11.
        """
        level_handlers = {
            pigpio.FALLING_EDGE: self._edge_FALL,
            pigpio.RISING_EDGE: self._edge_RISE,
            pigpio.EITHER_EDGE: self._edge_EITHER
        }
        handler = level_handlers[level]
        diff = pigpio.tickDiff(self.high_tick, tick)
        handler(tick, diff)

    def _edge_RISE(self, tick, diff):
        """
        Gère le signal montant (front montant).

        Cette méthode est appelée lorsqu'un front montant est détecté sur la broche GPIO.
        Elle détermine si le front montant représente un bit de donnée (0 ou 1) en fonction de la durée de l'état haut précédent (diff).
        Elle accumule les bits pour former les valeurs d'humidité, de température et de checksum.
        Elle vérifie également l'intégrité des données reçues en comparant le checksum calculé avec le checksum reçu.
        """
        val = 0
        if diff >= 50:
            val = 1

        if self.bit >= 40: # Message complete
            self.bit = 40
        elif self.bit >= 32: # In checksum byte
            self.checksum = (self.checksum << 1) + val
            if self.bit == 39:
                # 40th bit received
                self.pi.set_watchdog(self.gpio, 0)
                total = self.humidity + self.temperature
                # is checksum ok ?
                if not (total & 255) == self.checksum:
                    # "Erreur de checksum ignorée : attendu", (total & 255), "obtenu", self.checksum
                    error_message = f"Erreur de checksum ignorée : attendu {total & 255} obtenu {self.checksum}"
                    sys.stderr.write(f"{error_message}\n")
                    sys.stderr.flush()
        elif 16 <= self.bit < 24: # in temperature byte
            self.temperature = (self.temperature << 1) + val
        elif 0 <= self.bit < 8: # in humidity byte
            self.humidity = (self.humidity << 1) + val
        else: # skip header bits
            pass
        self.bit += 1

    def _edge_FALL(self, tick, diff):
        """
        Gère le signal de descente (front descendant).

        Cette méthode est appelée lorsqu'un front descendant est détecté sur la broche GPIO.
        Elle réinitialise les variables de bit, de checksum, de température et d'humidité
        si la durée de l'état haut précédent est suffisamment longue, indiquant le début
        d'une nouvelle transmission de données.
        """
        self.high_tick = tick
        if diff <= 250000:
            return
        self.bit = -2
        self.checksum = 0
        self.temperature = 0
        self.humidity = 0

    def _edge_EITHER(self, tick, diff):
        """
        Gère les signaux indéterminés (front montant ou descendant).

        Cette méthode est appelée lorsqu'un front montant ou descendant est détecté sur la broche GPIO.
        Elle désactive le watchdog timer sur la broche GPIO.
        """
        self.pi.set_watchdog(self.gpio, 0)

    def read(self):
        """
        Démarre la lecture des données du capteur DHT11.
        """
        self.pi.write(self.gpio, pigpio.LOW)
        time.sleep(0.017) # 17 ms
        self.pi.set_mode(self.gpio, pigpio.INPUT)
        self.pi.set_watchdog(self.gpio, 200)
        time.sleep(0.2)

    def close(self):
        """
        Arrête la lecture du capteur et supprime les callbacks.
        """
        self.pi.set_watchdog(self.gpio, 0)
        if self.either_edge_cb:
            self.either_edge_cb.cancel()
            self.either_edge_cb = None

    def __iter__(self):
        """
        Permet d'utiliser l'objet DHT11 comme un itérateur.
        """
        return self

    def __next__(self):
        """
        Exécute une lecture du capteur DHT11 et retourne un dictionnaire contenant la température et l'humidité.
        """
        self.read()
        response = {
            'humidity': self.humidity,
            'temperature': self.temperature
        }
        return response


def argparsing():
    parser = argparse.ArgumentParser(
        description="Lire les données du capteur DHT11 via pigpio."
    )
    
    parser.add_argument('--gpio', type=int, 
                        default=4, 
                        help='Numéro de la broche GPIO (par défaut: 4)')
    
    parser.add_argument('--host', type=str, 
                        default='127.0.0.1', 
                        help='Adresse IP du démon pigpio (par défaut: 127.0.0.1)')
    
    parser.add_argument('--port', type=int, 
                        default=8888, 
                        help='Port du démon pigpio (par défaut: 8888)')
    
    parser.add_argument('--humidity',
                        action='store_true',
                        help='Afficher l\'humidité mesurée par le capteur')
    
    parser.add_argument('--temperature',
                        action='store_true',
                        help='Afficher la température mesurée par le capteur')
    
    parser.add_argument('--fahrenheit',
                        action='store_true',
                        help='Convertir la température en Fahrenheit')
    
    parser.add_argument('--use-stdout',
                        action='store_true',
                        help='Utiliser la sortie standard pour afficher les résultats (par défaut: True)')
    
    parser.add_argument('--no-line-return',
                        action='store_true',
                        help='Ne pas ajouter de retour à la ligne à la fin de la sortie.')
    
    parser.add_argument('--custom-celsius-unit',
                        type=str,
                        default='°C',
                        help='Symbole de l\'unité de température en Celsius (par défaut: °C)')
    
    parser.add_argument('--custom-fahrenheit-unit',
                        type=str,
                        default='°F',
                        help='Symbole de l\'unité de température en Fahrenheit (par défaut: °F)')
    
    parser.add_argument('--custom-humidity-unit',
                        type=str,
                        default='%',
                        help='Symbole de l\'unité d\'humidité (par défaut: %%)')

    parser.add_argument('--prefix-temperature',
                        type=str,
                        default='temperature: ',
                        help="Préfixe pour l'affichage de la température (par défaut: \"temperature: \" )"
                        )
    
    parser.add_argument('--prefix-humidity',
                        type=str,
                        default='humidity: ',
                        help="Préfixe pour l'affichage de l'humidité (par défaut: \"humidity: \" )"
                        )

    parser.add_argument('--version', 
                        action='version',
                        version=f'%(prog)s {__version__}',
                        help='Afficher la version du script et quitter')
    

    args = parser.parse_args()
    return args


def display_temperature(d,
                        prefix='temperature: ',
                        farenheit=False,
                        use_stdout=True,
                        no_line_return=False,
                        custom_celsius_unit='°C',
                        custom_fahrenheit_unit='°F'
                        ):
    if farenheit:
        temp = convert_celsius_to_fahrenheit(d['temperature'])
        unit_symbol = custom_fahrenheit_unit
    else:
        temp = d['temperature']
        unit_symbol = custom_celsius_unit


    if not use_stdout:
        if not no_line_return:
            print("{} {:.2f} {unit_symbol}".format(
                prefix,
                temp, 
                unit_symbol=unit_symbol
                )
            )
        else:
            print("{} {:.2f} {unit_symbol}".format(
                prefix,
                temp, 
                unit_symbol=unit_symbol
                ),
                end=''
            )
    else:
        if not no_line_return:
            sys.stdout.write(
                "{} {:.2f} {unit_symbol}\n".format(
                    prefix,
                    temp, 
                    unit_symbol=unit_symbol
                )
            )
            sys.stdout.flush()
        else:
            sys.stdout.write(
                "{} {:.2f} {unit_symbol}".format(
                    prefix,
                    temp, 
                    unit_symbol=unit_symbol
                )
            )
            sys.stdout.flush()

def display_humidity(d,
                     prefix='humidity: ', 
                     use_stdout=True,
                     no_line_return=False,
                     custom_humidity_unit='%'
                     ):
    if not use_stdout:
        if not no_line_return:
            print("{} {} {}".format(
                prefix,
                d['humidity'],
                custom_humidity_unit
                )
            )
        else:
            print("{} {} {}".format(
                prefix,
                d['humidity'],
                custom_humidity_unit
                ),
                end=''
            )
    else:
        if not no_line_return:
            sys.stdout.write("{} {} {}\n".format(
                prefix,
                d['humidity'],
                custom_humidity_unit
                )
            )
            sys.stdout.flush()
        else:
            sys.stdout.write("{} {} {}".format(
                prefix,
                d['humidity'],
                custom_humidity_unit
                )
            )
            sys.stdout.flush()


if __name__ == '__main__':
    args = argparsing()
    display={
        'temperature': False,
        'humidity': False,
        'fahrenheit': False,
        'use_stdout': args.use_stdout,
        'no_line_return': args.no_line_return
    }
    if (not args.humidity) and (not args.temperature):
        display["humidity"] = True
        display["temperature"] = True
    else:
        if args.humidity:
            display["humidity"] = True
        if args.temperature:
            display["temperature"] = True

    if args.fahrenheit:
        display["fahrenheit"] = True
        

    pi = pigpio.pi(host=f'{args.host}', port=args.port)
    if not pi.connected:
        print(f"Impossible de se connecter au démon pigpio sur {args.host}:{args.port}")
        exit(1)

    sensor = DHT11(pi, args.gpio)
    for d in sensor:
        try:
            if display['temperature']:
                display_temperature(d, 
                                   farenheit=display['fahrenheit'],
                                   use_stdout=display['use_stdout'],
                                   no_line_return=display['no_line_return'],
                                   custom_celsius_unit=args.custom_celsius_unit,
                                   custom_fahrenheit_unit=args.custom_fahrenheit_unit,
                                   prefix=args.prefix_temperature)
                                   
            if display['humidity']:
                display_humidity(d, 
                                 use_stdout=display['use_stdout'],
                                 no_line_return=display['no_line_return'],
                                 custom_humidity_unit=args.custom_humidity_unit,
                                 prefix=args.prefix_humidity)
            break
        except Exception as e:
            print(f"[{e}]")
            continue
        finally:
            time.sleep(1)
    
    sensor.close()


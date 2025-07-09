#!/usr/bin/env python3
#coding: utf-8

import pygame
from os import path
import RPi.GPIO as GPIO
import time
from datetime import datetime

LIGHT_SENSOR_PIN = 27
LED_PIN = 23

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
# Configuration des broches
GPIO.setup(LIGHT_SENSOR_PIN, GPIO.IN)
GPIO.setup(LED_PIN, GPIO.OUT)

# Plage horaire de nuit (modifiable)
NIGHT_START = 22  # 22h
NIGHT_END = 7     # 7h
LAST_NIGHT_LIGHT_STATUS = False

# Fonction pour savoir si on est dans la plage de nuit
def is_night():
    now = datetime.now()
    hour = now.hour
    if NIGHT_START > NIGHT_END:
        # Plage nuit sur deux jours (ex: 22h-7h)
        return hour >= NIGHT_START or hour < NIGHT_END
    else:
        return NIGHT_START <= hour < NIGHT_END

def play_night_light_alert_sound():
    sound_file = path.join(path.dirname(path.abspath(__file__)), "sounds", "alert07.wav")
    try:
        pygame.mixer.init()
        pygame.mixer.music.load(sound_file)
        pygame.mixer.music.play()
        while pygame.mixer.music.get_busy():
            time.sleep(0.1)
        pygame.mixer.quit()
    except Exception as e:
        print(f"Erreur lors de la lecture du son : {e}")

def play_day_light_alert_sound():
    sound_file = path.join(path.dirname(path.abspath(__file__)), "sounds", "alert08.wav")
    try:
        pygame.mixer.init()
        pygame.mixer.music.load(sound_file)
        pygame.mixer.music.play()
        while pygame.mixer.music.get_busy():
            time.sleep(0.1)
        pygame.mixer.quit()
    except Exception as e:
        print(f"Erreur lors de la lecture du son : {e}")


try:
    led_on = False
    last_dark_time = None
    DARK_DELAY = 5  # secondes d'obscurité continue avant d'allumer la LED en journée
    while True:
        if is_night():
            if GPIO.input(LIGHT_SENSOR_PIN) == GPIO.HIGH:
                # Il fait sombre, on allume la LED
                if not led_on:
                    if LAST_NIGHT_LIGHT_STATUS == False:
                        play_night_light_alert_sound()
                    GPIO.output(LED_PIN, GPIO.HIGH)
                    led_on = True
                    LAST_NIGHT_LIGHT_STATUS = True
                time.sleep(5)
        
        else:
            # Journée : LED allumée seulement s'il fait sombre
            if GPIO.input(LIGHT_SENSOR_PIN) == GPIO.HIGH:
                # Il fait sombre
                if not led_on:
                    if last_dark_time is None:
                        last_dark_time = time.time()
                    elif time.time() - last_dark_time > DARK_DELAY:
                        GPIO.output(LED_PIN, GPIO.HIGH)
                        led_on = True
                else:
                    last_dark_time = None
            else:
                # Il fait lumineux
                if led_on:
                    if LAST_NIGHT_LIGHT_STATUS == True:
                        play_day_light_alert_sound()
                    GPIO.output(LED_PIN, GPIO.LOW)
                    led_on = False
                    LAST_NIGHT_LIGHT_STATUS = False
                last_dark_time = None
            time.sleep(1)
        time.sleep(1)

except KeyboardInterrupt:
    GPIO.cleanup()
    print("Arrêt du programme")
finally:
    GPIO.output(LED_PIN, GPIO.LOW)
    GPIO.cleanup()


#!/bin/bash


function tell_humidity(){
    # Use the dht.py script to get the humidity and speak it using espeak-ng
    # The output is piped to play for audio playback
    # Custom units can be specified for better understanding
    # Redirect stderr to /dev/null to suppress error messages
    # The output is spoken in French with a specific speed and volume
    # The output is played through the default audio device
    # The script uses the --use-stdout option to output the humidity directly to stdout
    # The custom units for humidity are specified for clarity

  dht11.py --humidity --prefix-humidity="Le taux d\'humidité est de" --custom-humidity-unit="Pourcents" --use-stdout 2>/dev/null | espeak-ng -v fr -a 100 -s 175 --stdout | play -
  
}


tell_humidity

#!/bin/bash

tail -F /var/log/tplink.log | while read line; do

    # Détection WAN down
    if echo "$line" | grep -q "WAN down"; then
        echo "ALERTE WAN DOWN"
        
        # TTS
        espeak-ng "Attention. Le lien WAN est coupé." \
        -s 160 -p 40

    fi

    # Détection IP suspecte
    if echo "$line" | grep -q "attack"; then
        espeak-ng "Activité suspecte détectée"
    fi

done
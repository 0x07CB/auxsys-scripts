

# Activer la réception réseau
# le fichier /etc/rsyslog.conf doit être modifié pour activer la réception réseau
# en décommentant les lignes suivantes :

#module(load="imudp")
#input(type="imudp" port="514")
#module(load="imtcp")
#input(type="imtcp" port="514")
sudo sed -i 's/^#\s*module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf
sudo sed -i 's/^#\s*input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf
sudo sed -i 's/^#\s*module(load="imtcp")/module(load="imtcp")/' /etc/rsyslog.conf
sudo sed -i 's/^#\s*input(type="imtcp" port="514")/input(type="imtcp" port="514")/' /etc/rsyslog.conf


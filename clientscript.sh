#!/bin/bash

sudo apt update && sudo apt upgrade -y

sudo nano /etc/hosts
echo " PUT SERVER IP AND "core-auth.zoo.local" in /etc/hosts file"

ping 10.10.18.198

sudo apt install libnss-ldap libpam-ldap ldap-utils nscd -y

echo " compat systemd ldap x2 then compat"
sudo nano /etc/nsswitch.conf
sudo nano /etc/pam.d/common-password
echo "add this at the end of the file:
      session optional pam_mkhomedir.so skel=/etc/skel umask=077"
sudo nano /etc/pam.d/common-session
sudo systemctl restart nscd
sudo systemctl enable nscd
ldapsearch -x -H ldap://10.10.18.198 -b "dc=core-auth,dc=zoo,dc=local"
sudo login
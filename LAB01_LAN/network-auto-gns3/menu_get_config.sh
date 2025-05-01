#!/bin/bash

# Menu per selezionare il router
ROUTER=$(whiptail --title "Seleziona Router" --menu "Quale router vuoi interrogare?" 15 60 4 \
"R1" "192.168.217.1" \
"R2" "192.168.218.1" \
3>&1 1>&2 2>&3)

# Esce se annullato
[ $? -ne 0 ] && echo "Annullato." && exit 1

# Richiesta username
USERNAME=$(whiptail --title "Utente SSH" --inputbox "Inserisci username SSH:" 8 40 "admin" 3>&1 1>&2 2>&3) || exit 1

# Richiesta password (mascherata)
PASSWORD=$(whiptail --title "Password SSH" --passwordbox "Inserisci password SSH:" 8 40 3>&1 1>&2 2>&3) || exit 1

# Mappa router a IP
case "$ROUTER" in
  R1) HOST="192.168.217.1" ;;
  R2) HOST="192.168.218.1" ;;
esac

# Avvia lo script Python con i parametri inseriti
python3 get_configs.py "$HOST" "$USERNAME" "$PASSWORD"

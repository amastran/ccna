#!/bin/bash

# Rimozione container già esistenti
echo "[*] Rimuovo eventuali container esistenti..."
docker rm -f alpine-node ubuntu-node fedora-node 2>/dev/null

# Percorso file inventory
INVENTORY_PATH=./inventory.ini
> "$INVENTORY_PATH"
echo "[targets]" >> "$INVENTORY_PATH"

# === ALPINE ===
echo "[*] Avvio Alpine..."
docker run -d --name alpine-node --hostname alpine-node --network bridge alpine sleep infinity

echo "[*] Configuro SSH su Alpine..."
docker exec alpine-node sh -c '
  apk update &&
  apk add openssh &&
  ssh-keygen -A &&
  echo "root:root" | chpasswd &&
  mkdir -p /var/run/sshd &&
  echo "PermitRootLogin yes" >> /etc/ssh/sshd_config &&
  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config &&
  /usr/sbin/sshd
'

# === UBUNTU ===
echo "[*] Avvio Ubuntu..."
docker run -d --name ubuntu-node --hostname ubuntu-node --network bridge ubuntu:24.04 sleep infinity

echo "[*] Configuro SSH su Ubuntu..."
docker exec ubuntu-node bash -c '
  apt-get update &&
  apt-get install -y openssh-server &&
  ssh-keygen -A &&
  echo "root:root" | chpasswd &&
  mkdir -p /var/run/sshd &&
  sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config &&
  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config &&
  service ssh start
'

# === FEDORA ===
echo "[*] Avvio Fedora..."
docker run -d --name fedora-node --hostname fedora-node --network bridge fedora sleep infinity

echo "[*] Configuro SSH su Fedora..."
docker exec fedora-node sh -c '
  dnf install -y openssh-server passwd &&
  ssh-keygen -A &&
  echo "root:root" | chpasswd &&
  mkdir -p /var/run/sshd &&
  echo "PermitRootLogin yes" >> /etc/ssh/sshd_config &&
  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config &&
  /usr/sbin/sshd
'

# === GENERAZIONE INVENTORY ===
for name in alpine-node ubuntu-node fedora-node; do
  ip=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' "$name")
  echo "$name ansible_host=$ip ansible_user=root ansible_password=root" >> "$INVENTORY_PATH"
done

echo "[✓] Tutti i container sono attivi. Inventory scritto in $INVENTORY_PATH"

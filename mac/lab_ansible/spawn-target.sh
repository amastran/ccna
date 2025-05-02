#!/bin/bash

# -- Script per creare container Docker (Alpine, Ubuntu, Fedora) come target per Ansible --

echo "[*] Rimuovo eventuali container Docker precedenti..."
docker rm -f alpine-node ubuntu-node fedora-node 2>/dev/null

# --- Configurazione Chiave SSH ---
# Percorso della tua chiave pubblica SSH (modifica se necessario)
PUBKEY_PATH="$HOME/.ssh/id_ed25519.pub"

# Verifica che la chiave pubblica esista
if [ ! -f "$PUBKEY_PATH" ]; then
  echo "[ERRORE] Chiave pubblica non trovata in '$PUBKEY_PATH'"
  echo "         Assicurati che il percorso sia corretto o genera una chiave con 'ssh-keygen -t ed25519'"
  exit 1
fi

# Leggi il contenuto della chiave pubblica
PUBKEY_CONTENT=$(cat "$PUBKEY_PATH")
echo "[*] Uso la chiave pubblica: $PUBKEY_PATH"

# --- Creazione Container ---

echo "[*] Creo container Alpine (alpine-node)..."
# Usiamo doppie virgolette per sh -c per permettere l'espansione di $PUBKEY_CONTENT dall'host
docker run -d \
  --name alpine-node \
  --hostname alpine-node \
  alpine:latest sh -c "
    echo '>>> Aggiorno e installo pacchetti (openssh, python3)...' && \
    apk update && apk add --no-cache openssh python3 && \
    echo '>>> Configuro SSH per root...' && \
    mkdir -p /root/.ssh && \
    echo '$PUBKEY_CONTENT' > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    chmod 700 /root/.ssh && \
    echo '>>> Genero chiavi host SSH...' && \
    ssh-keygen -A && \
    echo '>>> Avvio sshd in background e mantengo il container attivo...' && \
    /usr/sbin/sshd && sleep infinity"

echo "[*] Creo container Ubuntu (ubuntu-node)..."
docker run -d \
  --name ubuntu-node \
  --hostname ubuntu-node \
  ubuntu:24.04 bash -c "\
    export DEBIAN_FRONTEND=noninteractive && \
    echo '>>> Aggiorno e installo pacchetti (openssh-server, python3)...' && \
    apt-get update && apt-get install -y openssh-server python3 && \
    echo '>>> Configuro SSH per root...' && \
    mkdir -p /root/.ssh && \
    echo '$PUBKEY_CONTENT' > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    echo '>>> Avvio servizio SSH e mantengo il container attivo...' && \
    service ssh start && sleep infinity"

echo "[*] Creo container Fedora (fedora-node)..."
docker run -d \
  --name fedora-node \
  --hostname fedora-node \
  fedora:latest sh -c "\
    echo '>>> Installo pacchetti (openssh-server, python3)...' && \
    dnf install -y openssh-server python3 && \
    echo '>>> Configuro SSH per root...' && \
    mkdir -p /root/.ssh && \
    echo '$PUBKEY_CONTENT' > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    chmod 700 /root/.ssh && \
    echo '>>> Genero chiavi host SSH...' && \
    ssh-keygen -A && \
    echo '>>> Avvio sshd in background e mantengo il container attivo...' && \
    /usr/sbin/sshd && sleep infinity"

echo "[*] Attendo brevemente l'avvio dei container e dei servizi SSH..."
sleep 5

# --- Generazione Inventario Ansible ---

echo "[*] Controllo stato container e ottengo indirizzi IP..."
# Ottieni gli IP (con gestione errore se il container non è attivo)
ALPINE_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' alpine-node 2>/dev/null || echo "N/A")
UBUNTU_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ubuntu-node 2>/dev/null || echo "N/A")
FEDORA_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' fedora-node 2>/dev/null || echo "N/A")

# Verifica che i container siano in esecuzione
ERR_FLAG=0
for container in alpine-node ubuntu-node fedora-node; do
  if ! docker ps -f name="^/${container}$" --format '{{.Names}}' | grep -q "${container}"; then
    echo "[ATTENZIONE] Il container ${container} non sembra essere in esecuzione!"
    echo "           Controlla i log con: docker logs ${container}"
    ERR_FLAG=1
  fi
done

if [ "$ERR_FLAG" -ne 0 ]; then
    echo "[ERRORE] Uno o più container non sono partiti correttamente. L'inventario potrebbe essere incompleto."
    # Non usciamo, ma l'inventario potrebbe avere IP "N/A"
fi

# Opzionale: Rimuovere vecchie chiavi host SSH per evitare conflitti.
# Alternativa all'uso di ANSIBLE_HOST_KEY_CHECKING=False
# Se decommenti queste righe, assicurati che le variabili IP siano valide.
 echo "[*] Rimuovo vecchie chiavi SSH da known_hosts (ignora errori se non presenti)..."
 "$ALPINE_IP" != "N/A" ] && ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$ALPINE_IP" 2>/dev/null || true
[ "$UBUNTU_IP" != "N/A" ] && ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$UBUNTU_IP" 2>/dev/null || true
[ "$FEDORA_IP" != "N/A" ] && ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$FEDORA_IP" 2>/dev/null || true

echo "[*] Genero file inventory.ini per Ansible..."
cat <<EOF > inventory.ini
[targets]
alpine-node ansible_host=$ALPINE_IP ansible_user=root
ubuntu-node ansible_host=$UBUNTU_IP ansible_user=root
fedora-node ansible_host=$FEDORA_IP ansible_user=root

[targets:vars]
# Specifica esplicitamente il percorso dell'interprete Python3
# Questo è generalmente più affidabile di 'auto_silent' nei container minimali
ansible_python_interpreter=/usr/bin/python3

[all:vars]
# Puoi aggiungere qui altre variabili valide per tutti gli host

EOF

echo "[OK] Script completato."
echo "     File 'inventory.ini' generato."
echo "     Container attivi (verifica con 'docker ps'): alpine-node, ubuntu-node, fedora-node"
echo "     Puoi testare la connessione con:"
echo "     ANSIBLE_HOST_KEY_CHECKING=False ansible -i inventory.ini targets -m ping"

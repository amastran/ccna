from netmiko import ConnectHandler
import sys

# Verifica numero di argomenti
if len(sys.argv) != 5:
    print("Uso: push_config.py <host> <username> <password> <file_config>")
    sys.exit(1)

# Parametri
host = sys.argv[1]
username = sys.argv[2]
password = sys.argv[3]
file_config = sys.argv[4]

# Parametri di connessione per Netmiko
device = {
    "device_type": "cisco_ios",
    "host": host,
    "username": username,
    "password": password,
    "secret": password
}

try:
    print(f"Connettendo a {host} come {username}...")
    net_connect = ConnectHandler(**device)
    net_connect.enable()

    # Legge le righe del file di configurazione
    with open(file_config, "r") as f:
        config_lines = f.read().splitlines()

    # Invia i comandi in modalità config terminal
    output = net_connect.send_config_set(config_lines)

    print("Configurazione inviata con successo:")
    print(output)

    net_connect.disconnect()

except Exception as e:
    print(f"Errore: {e}")

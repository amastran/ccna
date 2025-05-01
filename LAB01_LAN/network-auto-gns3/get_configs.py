from netmiko import ConnectHandler
from datetime import datetime
import sys

# Verifica il numero di argomenti
if len(sys.argv) != 4:
    print("Uso: get_configs.py <host> <username> <password>")
    sys.exit(1)

# Parametri da riga di comando
host = sys.argv[1]
username = sys.argv[2]
password = sys.argv[3]

# Parametri Netmiko
device = {
    "device_type": "cisco_ios",
    "host": host,
    "username": username,
    "password": password,
    "secret": password
}

print(f"Connettendo a {host} come {username}...")

try:
    net_connect = ConnectHandler(**device)
    net_connect.enable()

    output = net_connect.send_command("show running-config")

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{host}_running-config_{timestamp}.txt"

    with open(filename, "w") as f:
        f.write(output)

    print(f"Configurazione salvata in {filename}")
    net_connect.disconnect()

except Exception as e:
    print(f"Errore: {e}")

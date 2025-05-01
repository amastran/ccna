from netmiko import ConnectHandler
from datetime import datetime

# Parametri di connessione per il router R2
r2 = {
    "device_type": "cisco_ios",
    "host": "192.168.218.1",
    "username": "admin",
    "password": "55405540",
    "secret": "55405540"  # Password per entrare in modalità enable
}

print(f"Connettendo a R2 ({r2['host']})...")

try:
    # Connessione SSH a R2
    net_connect = ConnectHandler(**r2)
    net_connect.enable()  # Entra in modalità privilegiata (enable)

    # Esecuzione comando show running-config
    output = net_connect.send_command("show running-config")

    # Salvataggio su file con timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"R2_running-config_{timestamp}.txt"
    with open(filename, "w") as f:
        f.write(output)

    print(f"Configurazione salvata in {filename}")
    net_connect.disconnect()

except Exception as e:
    print(f"Errore su R2: {e}")

FROM python:3.11-slim

LABEL maintainer="a.mastrangelo@ads.it"
LABEL description="Container GNS3 con SSH, bash, strumenti rete, automazione e utente andrea"

# Installa pacchetti base, rete, diagnostica, locali, ecc.
RUN apt-get update && apt-get install -y \
    ssh sudo curl wget vim mlocate \
    mtr tcpdump tshark nmap ncat iperf3 \
    expect traceroute iputils-ping iproute2 net-tools \
    dnsutils telnet socat whois htop iftop iotop lsof strace gnupg \
    git build-essential python3-dev locales tzdata \
    tldr w3m lynx tree ncdu ethtool bridge-utils \
    fzf fd-find bat exa zoxide openssh-server \
    && ln -fs /usr/share/zoneinfo/Europe/Rome /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && sed -i 's/# it_IT.UTF-8 UTF-8/it_IT.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen && update-locale LANG=it_IT.UTF-8 \
    && mkdir -p /var/run/sshd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Localizzazione italiana
ENV LANG=it_IT.UTF-8
ENV LANGUAGE=it_IT:it
ENV LC_ALL=it_IT.UTF-8

# Installa strumenti Python
RUN pip install --no-cache-dir \
    ansible netmiko napalm nornir paramiko \
    pyats genie httpx httpie textfsm ciscoconfparse \
    jmespath rich click

# Crea utente andrea
RUN useradd -m -s /bin/bash andrea \
    && echo "andrea:andrea" | chpasswd \
    && usermod -aG sudo andrea \
    && mkdir -p /home/andrea/.ssh

# Copia chiave SSH pubblica
COPY id_ed25519.pub /tmp/id_ed25519.pub
RUN cat /tmp/id_ed25519.pub >> /home/andrea/.ssh/authorized_keys \
    && chmod 600 /home/andrea/.ssh/authorized_keys \
    && chmod 700 /home/andrea/.ssh \
    && chown -R andrea:andrea /home/andrea/.ssh \
    && rm /tmp/id_ed25519.pub

# Configura sshd
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config \
    && echo "AllowUsers andrea" >> /etc/ssh/sshd_config

# Oh My Bash
RUN git clone https://github.com/ohmybash/oh-my-bash.git /home/andrea/.oh-my-bash \
    && cp /home/andrea/.oh-my-bash/templates/bashrc.osh-template /home/andrea/.bashrc \
    && echo 'OSH_THEME="agnoster"' >> /home/andrea/.bashrc \
    && echo 'plugins=(git sudo aliases common)' >> /home/andrea/.bashrc \
    && chown -R andrea:andrea /home/andrea/.oh-my-bash /home/andrea/.bashrc

# Script GitHub
COPY send-to-github.sh /usr/local/bin/send-to-github.sh
RUN chmod +x /usr/local/bin/send-to-github.sh

# Variabile token GitHub
ENV GITHUB_TOKEN=""

# Copia entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Esegui updatedb alla fine
RUN updatedb

# Espone porta SSH
EXPOSE 22

# Avvia entrypoint (sshd + bash)
ENTRYPOINT ["/entrypoint.sh"]

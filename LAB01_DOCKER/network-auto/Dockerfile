FROM python:3.11-slim

LABEL maintainer="a.mastrangelo@ads.it"
LABEL description="Container GNS3 per automazione rete con utente andrea, strumenti CLI, SSH per VSCode, Oh My Bash e localizzazione italiana"

# Installa pacchetti di sistema, strumenti CLI e diagnostici
RUN apt-get update && apt-get install -y \
    ssh \
    sudo \
    curl \
    wget \
    vim \
    mlocate \
    mtr \
    tcpdump \
    tshark \
    nmap \
    ncat \
    iperf3 \
    expect \
    traceroute \
    iputils-ping \
    iproute2 \
    net-tools \
    dnsutils \
    telnet \
    socat \
    whois \
    htop \
    iftop \
    iotop \
    lsof \
    strace \
    gnupg \
    git \
    build-essential \
    python3-dev \
    locales \
    tzdata \
    tldr \
    w3m \
    lynx \
    tree \
    ncdu \
    ethtool \
    bridge-utils \
    fzf \
    fd-find \
    bat \
    exa \
    zoxide \
    openssh-server \
    && ln -fs /usr/share/zoneinfo/Europe/Rome /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && sed -i 's/# it_IT.UTF-8 UTF-8/it_IT.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=it_IT.UTF-8 \
    && mkdir -p /var/run/sshd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configura locale italiano
ENV LANG=it_IT.UTF-8
ENV LANGUAGE=it_IT:it
ENV LC_ALL=it_IT.UTF-8

# Installa librerie Python per automazione di rete
RUN pip install --no-cache-dir \
    ansible \
    netmiko \
    napalm \
    nornir \
    paramiko \
    pyats \
    genie \
    httpx \
    httpie \
    textfsm \
    ciscoconfparse \
    jmespath \
    rich \
    click

# Crea utente andrea con accesso SSH
RUN useradd -m -s /bin/bash andrea \
    && echo "andrea:andrea" | chpasswd \
    && usermod -aG sudo andrea \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "AllowUsers andrea" >> /etc/ssh/sshd_config

# Installa Oh My Bash per andrea
RUN git clone https://github.com/ohmybash/oh-my-bash.git /home/andrea/.oh-my-bash \
    && cp /home/andrea/.oh-my-bash/templates/bashrc.osh-template /home/andrea/.bashrc \
    && echo 'OSH_THEME="agnoster"' >> /home/andrea/.bashrc \
    && echo 'plugins=(git sudo aliases common)' >> /home/andrea/.bashrc \
    && chown -R andrea:andrea /home/andrea/.oh-my-bash /home/andrea/.bashrc

# Copia lo script GitHub e rendilo eseguibile
COPY send-to-github.sh /usr/local/bin/send-to-github.sh
RUN chmod +x /usr/local/bin/send-to-github.sh

# Token GitHub (da passare via -e o ENV)
ENV GITHUB_TOKEN=""

# ✅ Esegui updatedb alla fine
RUN updatedb

# Espone la porta SSH per VSCode
EXPOSE 22

# Entry point: avvia SSH per connessione da remoto
CMD ["/usr/sbin/sshd", "-D"]

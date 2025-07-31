[Unit]
Description=CMAN SII-BASTION01
After=network-online.target

[Service]
User=oracle
Group=oinstall
LimitNOFILE=10240
MemoryLimit=8G
RestartSec=30s
StartLimitInterval=1800s
StartLimitBurst=20
ExecStart=/base/app/oracle/scripts/cman_service.sh -c cman-test -a start -o /base/app/oracle/product/cman1930
ExecReload=/base/app/oracle/scripts/cman_service.sh -c cman-test -a reload -o /base/app/oracle/product/cman1930
ExecStop=/base/app/oracle/scripts/cman_service.sh -c cman-test -a stop -o /base/app/oracle/product/cman1930
KillMode=control-group
Restart=on-failure
Type=forking
#Environment="ORACLE_HOME=/base/app/oracle/product/cman1930"
#Environment="PATH=/usr/bin:/bin:/base/app/oracle/product/cman1930/bin"

[Install]
WantedBy=multi-user.target
Alias=service-cman-test.service
#!/bin/bash
clear
echo -e "Downloading Asset Service"
aset_service() {

    cd
    wget -O /usr/local/bin/ws-dropbear https://raw.githubusercontent.com/vermiliion/Xray-Only/main/ssh/dropbear-ws.py
    wget -O /usr/local/bin/ws-stunnel https://raw.githubusercontent.com/vermiliion/Xray-Only/main/ssh/ws-stunnel

    
    chmod +x /usr/local/bin/ws-dropbear
    chmod +x /usr/local/bin/ws-stunnel


    
    wget -O /etc/systemd/system/ws-dropbear.service https://raw.githubusercontent.com/vermiliion/Xray-Only/main/ssh/service-wsdropbear && chmod +x /etc/systemd/system/ws-dropbear.service

    #System SSL/TLS Websocket-SSH Python
    wget -O /etc/systemd/system/ws-stunnel.service https://raw.githubusercontent.com/vermiliion/Xray-Only/main/ssh/ws-stunnel.service && chmod +x /etc/systemd/system/ws-stunnel.service

    #restart service
    systemctl daemon-reload
    
    systemctl enable ws-dropbear.service
    systemctl start ws-dropbear.service
    systemctl restart ws-dropbear.service

    #Enable & Start & Restart ws-openssh service
    systemctl enable ws-stunnel.service
    systemctl start ws-stunnel.service
    systemctl restart ws-stunnel.service

}

aset_service
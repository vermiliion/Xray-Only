#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
BIYellow='\033[1;93m'
NC='\e[0m'
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y
apt -y install jq
apt -y install shc
apt -y install wget curl
apt-get install figlet -y
apt-get install ruby -y
gem install lolcat
wget -q https://raw.githubusercontent.com/vermiliion/Xray-Only/main/ssh/insshws.sh && chmod +x insshws.sh && ./insshws.sh
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/ssh/newudpgw"
chmod +x /usr/bin/badvpn-udpgw
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500' /etc/rc.local
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7600 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7700 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7800 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7900 --max-clients 500
cd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 500' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 40000' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 51443' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 58080' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 200' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 22' /etc/ssh/sshd_config
systemctl restart ssh
echo "=== Install Dropbear ==="
# Instalasi Dropbear
apt -y install dropbear
# Aktifkan Dropbear pada start up
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 50000 -p 109 -p 110 -p 69"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
systemctl daemon-reload
systemctl restart dropbear
echo "=== Dropbear Installation and Configuration Completed ==="
echo -e "[ ${BIYellow}INFO$NC ] Settings banner"
wget -q -O /etc/issue.net "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/ssh/issue.net"
chmod +x /etc/issue.net
echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear
clear
sleep 1
echo -e "[ ${BIYellow}INFO${NC} ] Restart All service"
systemctl restart nginx >/dev/null 2>&1
sleep 1
echo -e "[ ${BIYellow}OK${NC} ] Restarting cron "
systemctl restart cron >/dev/null 2>&1
sleep 1
echo -e "[ ${BIYellow}OK${NC} ] Restarting ssh "
systemctl restart ssh >/dev/null 2>&1
sleep 1
echo -e "[ ${BIYellow}OK${NC} ] Restarting dropbear "
systemctl restart dropbear >/dev/null 2>&1
sleep 1
echo -e "[ ${BIYellow}OK${NC} ] Restarting fail2ban "
systemctl restart fail2ban >/dev/null 2>&1
sleep 1
echo -e "[ ${BIYellow}OK${NC} ] Restarting Vnstat "
systemctl restart vnstat >/dev/null 2>&1
sleep 1
echo -e "[ ${BIYellow}OK${NC} ] Restarting Squid"
systemctl restart squid >/dev/null 2>&1
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7600 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7700 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7800 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7900 --max-clients 500
history -c
echo "unset HISTFILE" >> /etc/profile
rm -f /root/key.pem
rm -f /root/cert.pem
rm -f /root/ssh-vpn.sh
clear
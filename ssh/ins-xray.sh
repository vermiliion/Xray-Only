#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
green='\e[1;32m'
red='\e[1;31m'
yellow='\e[1;33m'
NC='\e[0m'
domain=$(cat /root/domain)
clear
mkdir -p /etc/xray
# Fungsi instalasi dan konfigurasi dasar
res_file() {
    apt-get install -y iptables iptables-persistent || { echo -e "[ ${red}ERROR${NC} ] Failed to install iptables!"; return; }

    # Sinkronisasi waktu
    apt-get install -y ntpdate || { echo -e "[ ${red}ERROR${NC} ] Failed to install ntpdate!"; return; }
    ntpdate pool.ntp.org
    timedatectl set-ntp true

    # Konfigurasi Chrony
    if systemctl list-unit-files | grep -q chronyd; then
        systemctl enable chronyd
        systemctl restart chronyd
    else
        apt-get install -y chrony || { echo -e "[ ${red}ERROR${NC} ] Failed to install chrony!"; return; }
        systemctl enable chrony
        systemctl restart chrony
    fi

    # Set zona waktu
    timedatectl set-timezone Asia/Jakarta

    # Cek tracking Chrony
    echo -e "[ ${yellow}INFO${NC} ] ${green}Checking chrony tracking...${NC}"
    chronyc sourcestats -v
    chronyc tracking -v

    # Update paket dan instal dependensi
    apt-get clean
    apt-get update -y
    apt-get install -y curl socat xz-utils wget apt-transport-https gnupg dnsutils lsb-release \
        bash-completion zip pwgen openssl netcat cron || { echo -e "[ ${red}ERROR${NC} ] Failed to install dependencies!"; return; }
    
    apt-get autoremove -y
}

res_file

clear
echo -e "[ ${yellow}INFO${NC} ] ${green}Iptables has been installed${NC}"
sleep 1
echo -e "[ ${yellow}INFO${NC} ] ${green}The NTP date has been set${NC}"
sleep 1
echo -e "[ ${yellow}INFO${NC} ] ${green}Chronyd has been activated${NC}"
sleep 1
echo -e "[ ${yellow}INFO${NC} ] ${green}The time zone for Asia/Jakarta has been set${NC}"
sleep 1
echo -e "[ ${yellow}INFO${NC} ] ${green}Dependencies have been installed${NC}"
sleep 1
echo -e "[ ${yellow}INFO${NC} ] ${green}Time has been synchronized${NC}"
sleep 1
echo -e "[ ${yellow}INFO${NC} ] ${green}Script execution completed successfully${NC}"
sleep 1
echo -e "[ ${yellow}INFO$NC ] ${green}Downloading & Installing xray core${NC}"
domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir  $domainSock_dir
chown www-data.www-data $domainSock_dir
# Make Folder XRay
# Hapus file database lama
rm -rf /etc/user_locks.db
rm -rf /etc/ssh/.ssh.db
rm -rf /etc/vmess/.vmess.db
rm -rf /etc/vless/.vless.db
rm -rf /etc/trojan/.trojan.db
rm -rf /etc/shadowsocks/.shadowsocks.db
rm -rf /etc/bot/.bot.db
rm -rf /etc/user-create/user.log
mkdir -p /etc/bot
mkdir -p /etc/xray
mkdir -p /etc/ssh
mkdir -p /etc/vmess
mkdir -p /etc/vless
mkdir -p /etc/trojan
mkdir -p /etc/shadowsocks
mkdir -p /usr/bin/xray/
mkdir -p /var/log/xray/
mkdir -p /var/www/html
mkdir -p /etc/limit/ssh/ip
mkdir -p /etc/limit/vmess/ip
mkdir -p /etc/limit/vless/ip
mkdir -p /etc/limit/trojan/ip
mkdir -p /etc/limit/shadowsocks/ip
mkdir -p /etc/limit/ssh
mkdir -p /etc/limit/vmess
mkdir -p /etc/limit/vless
mkdir -p /etc/limit/trojan
mkdir -p /etc/limit/shadowsocks
mkdir -p /etc/user-create
chmod +x /var/log/xray
touch /etc/xray/domain
touch /etc/user_locks.db
touch /var/log/xray/access.log
touch /var/log/xray/error.log
touch /etc/ssh/.ssh.db
touch /etc/vmess/.vmess.db
touch /etc/vless/.vless.db
touch /etc/trojan/.trojan.db
touch /etc/shadowsocks/.shadowsocks.db
touch /etc/bot/.bot.db
chmod 644 /etc/user_locks.db
echo "& plughin Account" >>/etc/ssh/.ssh.db
echo "& plughin Account" >>/etc/vmess/.vmess.db
echo "& plughin Account" >>/etc/vless/.vless.db
echo "& plughin Account" >>/etc/trojan/.trojan.db
echo "& plughin Account" >>/etc/shadowsocks/.shadowsocks.db
echo "echo -e 'Vps Config User Account'" >> /etc/user-create/user.log


# Atur izin dan buat file tambahan untuk log
chown www-data:www-data /var/log/xray
touch /var/log/xray/access2.log
touch /var/log/xray/error2.log
# / / Ambil Xray Core Version Terbaru
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version 1.8.4
## crt xray
systemctl stop nginx
mkdir /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

# set uuid
uuid=$(cat /proc/sys/kernel/random/uuid)
# xray config
cat > /etc/xray/config.json << END
{
  "log" : {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
      {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
   {
     "listen": "127.0.0.1",
     "port": "14016",
     "protocol": "vless",
      "settings": {
          "decryption":"none",
            "clients": [
               {
                 "id": "${uuid}"                 
#vless
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vless"
          }
        }
     },
     {
     "listen": "127.0.0.1",
     "port": "23456",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmess
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vmess"
          }
        }
     },
    {
      "listen": "127.0.0.1",
      "port": "25432",
      "protocol": "trojan",
      "settings": {
          "decryption":"none",		
           "clients": [
              {
                 "password": "${uuid}"
#trojanws
              }
          ],
         "udp": true
       },
       "streamSettings":{
           "network": "ws",
           "wsSettings": {
               "path": "/trojan-ws"
            }
         }
     },
    {
         "listen": "127.0.0.1",
        "port": "30300",
        "protocol": "shadowsocks",
        "settings": {
           "clients": [
           {
           "method": "aes-128-gcm",
          "password": "${uuid}"
#ssws
           }
          ],
          "network": "tcp,udp"
       },
       "streamSettings":{
          "network": "ws",
             "wsSettings": {
               "path": "/ss-ws"
           }
        }
     },	
      {
        "listen": "127.0.0.1",
     "port": "24456",
        "protocol": "vless",
        "settings": {
         "decryption":"none",
           "clients": [
             {
               "id": "${uuid}"
#vlessgrpc
             }
          ]
       },
          "streamSettings":{
             "network": "grpc",
             "grpcSettings": {
                "serviceName": "vless-grpc"
           }
        }
     },
     {
      "listen": "127.0.0.1",
     "port": "31234",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmessgrpc
             }
          ]
       },
       "streamSettings":{
         "network": "grpc",
            "grpcSettings": {
                "serviceName": "vmess-grpc"
          }
        }
     },
     {
        "listen": "127.0.0.1",
     "port": "33456",
        "protocol": "trojan",
        "settings": {
          "decryption":"none",
             "clients": [
               {
                 "password": "${uuid}"
#trojangrpc
               }
           ]
        },
         "streamSettings":{
         "network": "grpc",
           "grpcSettings": {
               "serviceName": "trojan-grpc"
         }
      }
   },
   {
    "listen": "127.0.0.1",
    "port": "30310",
    "protocol": "shadowsocks",
    "settings": {
        "clients": [
          {
             "method": "aes-128-gcm",
             "password": "${uuid}"
#ssgrpc
           }
         ],
           "network": "tcp,udp"
      },
    "streamSettings":{
     "network": "grpc",
        "grpcSettings": {
           "serviceName": "ss-grpc"
          }
       }
    }	
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END
rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service
cat <<EOF> /etc/systemd/system/xray.service
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

EOF
cat > /etc/systemd/system/runn.service <<EOF
[Unit]
Description=Mantap-Sayang
After=network.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/mkdir -p /var/run/xray
ExecStart=/usr/bin/chown www-data:www-data /var/run/xray
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
#nginx config
cat >/etc/nginx/conf.d/xray.conf <<EOF
    server {
             listen 80;
             listen [::]:80;
             listen 8880;
             listen [::]:8880;
             listen 8080;
             listen [::]:8080;
             listen 8443 ssl http2 reuseport;
             listen [::]:8443 ssl http2 reuseport;
             listen 443 ssl http2 reuseport;
             listen [::]:443 ssl http2 reuseport;
             server_name $domain;
             ssl_certificate /etc/xray/xray.crt;
             ssl_certificate_key /etc/xray/xray.key;
             ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
             ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
        }
EOF
sed -i '$ ilocation = /vless' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_pass http://127.0.0.1:14016;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_http_version 1.1;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Upgrade \$http_upgrade;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Connection "upgrade";' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation = /vmess' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_pass http://127.0.0.1:23456;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_http_version 1.1;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Upgrade \$http_upgrade;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Connection "upgrade";' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation = /trojan-ws' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_pass http://127.0.0.1:25432;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_http_version 1.1;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Upgrade \$http_upgrade;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Connection "upgrade";' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation = /trojango' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_pass http://127.0.0.1:2087;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_http_version 1.1;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Upgrade \$http_upgrade;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Connection "upgrade";' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation = /ss-ws' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_pass http://127.0.0.1:30300;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_http_version 1.1;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Upgrade \$http_upgrade;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Connection "upgrade";' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation /' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_pass http://127.0.0.1:700;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_http_version 1.1;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Upgrade \$http_upgrade;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Connection "upgrade";' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation ^~ /vless-grpc' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_pass grpc://127.0.0.1:24456;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation ^~ /vmess-grpc' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_pass grpc://127.0.0.1:31234;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation ^~ /trojan-grpc' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ igrpc_pass grpc://127.0.0.1:33456;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf
clear
interface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
cat >/etc/iptables/rules.v4 <<-END
*filter
:INPUT ACCEPT [1423:15108189]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [1407:131528]
-A INPUT -p tcp -m tcp --dport 10015 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10012 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10011 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10008 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10007 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10006 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10005 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10004 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10003 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10002 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10001 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10000 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 2082 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 2083 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 3128 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 1194 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 109 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 169 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 88 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 68 -j ACCEPT
-A INPUT -p udp -m udp --dport 53 -j ACCEPT
-A INPUT -p udp -m udp --dport 2200 -j ACCEPT
-A INPUT -p udp -m udp --dport 2100 -j ACCEPT
-A INPUT -p udp -m udp --dport 5300 -j ACCEPT
-A INPUT -p udp -m udp --dport 7100 -j ACCEPT
-A INPUT -p udp -m udp --dport 7200 -j ACCEPT
-A INPUT -p udp -m udp --dport 7300 -j ACCEPT
-A FORWARD -m string --string "BitTorrent" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string "BitTorrent protocol" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string "peer_id=" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string ".torrent" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string "announce.php?passkey=" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string "torrent" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string "announce" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string "info_hash" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string "/default.ida?" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string ".exe?/c+dir" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string ".exe?/c_tftp" --algo bm --to 65535 -j DROP
-A FORWARD -m string --string "peer_id" --algo kmp --to 65535 -j DROP
-A FORWARD -m string --string "BitTorrent" --algo kmp --to 65535 -j DROP
-A FORWARD -m string --string "BitTorrent protocol" --algo kmp --to 65535 -j DROP
-A FORWARD -m string --string "bittorrent-announce" --algo kmp --to 65535 -j DROP
-A FORWARD -m string --string "announce.php?passkey=" --algo kmp --to 65535 -j DROP
-A FORWARD -m string --string "find_node" --algo kmp --to 65535 -j DROP
-A FORWARD -m string --string "info_hash" --algo kmp --to 65535 -j DROP
-A FORWARD -m string --string "get_peers" --algo kmp --to 65535 -j DROP
-A FORWARD -m string --string "announce" --algo kmp --to 65535 -j DROP
-A FORWARD -m string --string "announce_peers" --algo kmp --to 65535 -j DROP
COMMIT

*nat
:PREROUTING ACCEPT [18:1004]
:INPUT ACCEPT [18:1004]
:POSTROUTING ACCEPT [79:4815]
:OUTPUT ACCEPT [79:4815]
-A PREROUTING -i $interface -p udp -m udp --dport 53 -j REDIRECT --to-ports 5300
-A POSTROUTING -s 10.8.0.0/24 -o $interface -j MASQUERADE
-A POSTROUTING -s 20.8.0.0/24 -o $interface -j MASQUERADE
COMMIT


END

cat >/etc/iptables/rules.v6 <<-END

*filter
:INPUT ACCEPT [1:48]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [2:96]
COMMIT

END

netfilter-persistent reload
systemctl restart netfilter-persistent
clear
echo -e "$yell[SERVICE]$NC Restart All service"
systemctl daemon-reload
sleep 1
echo -e "[ ${yellow}ok${NC} ] Enable & restart xray "
systemctl daemon-reload
systemctl enable xray
systemctl restart xray
systemctl restart nginx
systemctl enable runn
systemctl restart runn

clear
sleep 1
mv /root/domain /etc/xray/ 
if [ -f /root/scdomain ];then
rm /root/scdomain > /dev/null 2>&1
fi
clear
rm -f ins-xray.sh  

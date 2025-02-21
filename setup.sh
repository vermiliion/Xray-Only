#!/bin/bash
clear
FONT='\033[0m'
Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
GREENBG="\033[42;37m"
REDBG="\033[41;37m"
IGreen="\033[0;92m"
OK="${lime}--->${FONT}"
EROR="${RED}[ERROR]${FONT}"
BIYellow="\033[1;93m"
BICyan="\033[1;96m"
BIWhite="\033[1;97m"
GRAY="\e[1;30m"
lime="\e[38;5;155m"
REPO="https://raw.githubusercontent.com/vermiliion/Xray-Only/main/"
clear

# Cek apakah script dijalankan sebagai root
if [ "${EUID}" -ne 0 ]; then
    echo -e "${EROR} You need to run this script as root"
    return
fi

# Cek apakah virtualisasi OpenVZ digunakan
if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo -e "${EROR} OpenVZ is not supported"
    return
fi

# Update IP
IP=$(curl -sS icanhazip.com)
if [[ -z $IP ]]; then
    echo -e "${EROR} IP Address (${YELLOW}Not Detected${FONT})"
else
    echo -e "${OK} IP Address (${lime}${IP}${FONT})"
fi

# Cek arsitektur sistem
ARCH=$(uname -m)
if [[ $ARCH == "x86_64" ]]; then
    echo -e "${OK} Your Architecture Is Supported (${lime}${ARCH}${FONT})"
else
    echo -e "${EROR} Your Architecture Is Not Supported (${YELLOW}${ARCH}${FONT})"
    return
fi

# Cek sistem operasi
OS_ID=$(grep -w ^ID /etc/os-release | cut -d= -f2 | tr -d '"')
OS_NAME=$(grep -w ^PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
if [[ $OS_ID == "ubuntu" || $OS_ID == "debian" ]]; then
    echo -e "${OK} Your OS Is Supported (${lime}${OS_NAME}${FONT})"
else
    echo -e "${EROR} Your OS Is Not Supported (${YELLOW}${OS_NAME}${FONT})"
    return
fi

# Fungsi untuk mengonversi waktu instalasi
start=$(date +%s)
secs_to_human() {
    echo "Installation time : $((${1} / 3600)) hours $(((${1} / 60) % 60)) minute's $((${1} % 60)) seconds"
}

# Fungsi–fungsi tampilan status
function print_ok() {
    echo -e "${OK}${BLUE}$1${FONT}"
}
function print_install() {
    echo -e "${BIYellow}$1${FONT}"
    sleep 1
}
function print_error() {
    echo -e "${EROR}${REDBG}$1${FONT}"
}
function print_success() {
    if [[ 0 -eq $? ]]; then  
        echo -e "${lime}$1 Installed Successfully${FONT}"
        sleep 2
    fi
}
function is_root() {
    if [[ 0 == "$UID" ]]; then
        print_ok "Root user: Starting installation process"
    else
        print_error "The current user is not the root user. Please switch to root and run the script again."
        return
    fi
}

# Buat direktori xray dan set permission
print_install "Creating xray directory and log files"
mkdir -p /etc/xray
curl -s ifconfig.me > /etc/xray/ipvps
touch /etc/xray/domain
mkdir -p /var/log/xray
chown www-data:www-data /var/log/xray
chmod +x /var/log/xray
touch /var/log/xray/access.log
touch /var/log/xray/error.log
mkdir -p /var/lib >/dev/null 2>&1

# Informasi RAM
while IFS=":" read -r a b; do
    case $a in
        "MemTotal") ((mem_used+=${b/kB})); mem_total="${b/kB}" ;;
        "Shmem") ((mem_used+=${b/kB}))  ;;
        "MemFree" | "Buffers" | "Cached" | "SReclaimable")
            mem_used="$((mem_used-=${b/kB}))"
        ;;
    esac
done < /proc/meminfo
Ram_Usage="$((mem_used / 1024))"
Ram_Total="$((mem_total / 1024))"
export tanggal=$(date -d "0 days" +"%d-%m-%Y - %X")
export OS_Name=$(grep -w PRETTY_NAME /etc/os-release | head -n1 | cut -d= -f2 | tr -d '"')
export Kernel=$(uname -r)
export Arch=$(uname -m)
export IP=$(curl -s https://ipinfo.io/ip/)

# Ubah pengaturan sistem
function first_setup() {
    print_install "Changing system environment settings"
    timedatectl set-timezone Asia/Makassar
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

}


# Fungsi instalasi Nginx
function nginx_install() {
    local os_id
    os_id=$(grep -w ID /etc/os-release | head -n1 | cut -d= -f2 | tr -d '"')

    if [[ $os_id == "ubuntu" ]]; then
        print_install "Setting up nginx for $(grep -w PRETTY_NAME /etc/os-release | head -n1 | cut -d= -f2 | tr -d '\"')"
        apt-get install nginx -y
    elif [[ $os_id == "debian" ]]; then
        print_success "Setting up nginx for $(grep -w PRETTY_NAME /etc/os-release | head -n1 | cut -d= -f2 | tr -d '\"')"
        apt install nginx -y
    else
        echo -e "Your OS is not supported (${YELLOW}$(grep -w PRETTY_NAME /etc/os-release | head -n1 | cut -d= -f2 | tr -d '\"')${FONT})"
        return
    fi
    # Membuat dan menambahkan file mime.types
    cat <<EOL | sudo tee /etc/nginx/mime.types > /dev/null
types {
    text/html                             html htm shtml;
    text/css                              css;
    text/xml                              xml;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    application/javascript                js;
    application/atom+xml                  atom;
    application/rss+xml                   rss;

    # Custom MIME types
    application/vnd.ms-fontobject         eot;
    font/ttf                              ttf;
    font/opentype                         otf;
    font/woff                             woff;
    font/woff2                            woff2;
    application/octet-stream              bin exe dll;
    application/x-shockwave-flash         swf;
    application/pdf                       pdf;
    application/json                      json;
    application/zip                       zip;
    application/x-7z-compressed           7z;
}
EOL

    # Verifikasi konfigurasi NGINX
    sudo nginx -t
    sudo systemctl restart nginx
    echo "NGINX dan mime.types telah terinstall dan terkonfigurasi!"
}


end=$(date +%s)
secs_to_human $((end-start))


# Update and remove packages
function base_package() {
    clear
    print_install "Menginstall Paket Yang Dibutuhkan"
    
    # Update sistem dan upgrade paket
    apt update -y
    apt upgrade -y
    apt dist-upgrade -y

    # Instalasi paket dasar yang dibutuhkan oleh Xray
    apt install -y zip pwgen openssl netcat-openbsd socat cron bash-completion figlet ruby wondershaper
    gem install lolcat
    apt install -y iptables iptables-persistent
    apt install -y ntpdate chrony

    # Sinkronisasi waktu dengan NTP
    ntpdate pool.ntp.org

    # Konfigurasi dan restart service terkait
    systemctl enable netfilter-persistent
    systemctl restart netfilter-persistent
    systemctl enable --now chrony
    systemctl restart chrony
    chronyc sourcestats -v
    chronyc tracking -v

    # Instalasi dependensi utama untuk Xray
    apt install -y --no-install-recommends software-properties-common

    # Set konfigurasi non-interaktif untuk iptables-persistent
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

    apt install -y \
      speedtest-cli vnstat libnss3-dev libnspr4-dev pkg-config libpam0g-dev \
      libcap-ng-dev libcap-ng-utils libselinux1-dev libcurl4-nss-dev flex bison make libnss3-tools \
      libevent-dev bc rsyslog dos2unix zlib1g-dev libssl-dev libsqlite3-dev sed dirmngr \
      libxml-parser-perl build-essential gcc g++ python3 htop lsof tar wget curl git \
      unzip p7zip-full libc6 util-linux msmtp-mta ca-certificates bsd-mailx \
      netfilter-persistent net-tools gnupg lsb-release cmake screen xz-utils apt-transport-https dnsutils jq easy-rsa

    # Pembersihan sistem
    apt clean
    apt autoremove -y

    # Penghapusan paket yang tidak diperlukan
    apt remove --purge -y exim4 ufw firewalld
    print_success "Required Packages Installed"
}


clear
function pasang_domain() {
    clear
    echo -e "${BIWhite}---------------------------------------------------${FONT}"
    echo -e "${BIYellow}SETUP DOMAIN${FONT}"
    echo -e "${BIWhite}---------------------------------------------------${FONT}"
    echo -e "${lime}[${BIWhite}01${lime}] ${FONT}${BIWhite}Choose Your Own Domain / Gunakan Domain Sendiri${FONT}"
    echo -e "${BIWhite}---------------------------------------------------${FONT}"
    
    while true; do
        read -p " Please select number 1: " host
        echo ""
        
        if [[ $host == "1" ]]; then
            echo -e "Please Input Your Subdomain:"
            read -p "Silahkan Masukan Subdomain mu: " host1
            echo "IP=" >> /var/lib/ipvps.conf
            echo $host1 > /etc/xray/domain
            echo $host1 > /root/domain
            echo -e "\e[1;32m   Subdomain successfully set to: $host1\e[0m"
            echo ""
            break
        else
            echo -e "\e[1;31m   Invalid choice! Please select only 1.\e[0m"
            echo -e "\e[1;33m-------------------------------------------------\e[0m"
        fi
    done
}


function pasang_ssl() {
clear
print_install "Inclusion of SSL on the Domain"
    rm -rf /etc/xray/xray.key
    rm -rf /etc/xray/xray.crt
    domain=$(cat /root/domain)
    STOPWEBSERVER=$(lsof -i:80 | cut -d' ' -f1 | awk 'NR==2 {print $1}')
    rm -rf /root/.acme.sh
    mkdir /root/.acme.sh
    systemctl stop $STOPWEBSERVER
    systemctl stop nginx
    curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
    chmod 777 /etc/xray/xray.key
    print_success "SSL Certificate"
}

function make_folder_xray() {
    rm -rf /etc/user_locks.db
    rm -rf /etc/vmess/.vmess.db
    rm -rf /etc/vless/.vless.db
    rm -rf /etc/trojan/.trojan.db
    rm -rf /etc/shadowsocks/.shadowsocks.db
    rm -rf /etc/bot/.bot.db
    rm -rf /etc/user-create/user.log
    mkdir -p /etc/bot
    mkdir -p /etc/xray
    mkdir -p /etc/vmess
    mkdir -p /etc/vless
    mkdir -p /etc/trojan
    mkdir -p /etc/shadowsocks
    mkdir -p /usr/bin/xray/
    mkdir -p /var/log/xray/
    mkdir -p /var/www/html
    mkdir -p /etc/limit/vmess/ip
    mkdir -p /etc/limit/vless/ip
    mkdir -p /etc/limit/trojan/ip
    mkdir -p /etc/limit/shadowsocks/ip
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
    touch /etc/vmess/.vmess.db
    touch /etc/vless/.vless.db
    touch /etc/trojan/.trojan.db
    touch /etc/shadowsocks/.shadowsocks.db
    touch /etc/bot/.bot.db
    chmod 644 /etc/user_locks.db
    echo "& plughin Account" >>/etc/vmess/.vmess.db
    echo "& plughin Account" >>/etc/vless/.vless.db
    echo "& plughin Account" >>/etc/trojan/.trojan.db
    echo "& plughin Account" >>/etc/shadowsocks/.shadowsocks.db
    echo "echo -e 'Vps Config User Account'" >> /etc/user-create/user.log
    }
#Instal Xray
function install_xray() {
    clear
    print_install "Installing Xray Core v1.8.4"

    domainSock_dir="/run/xray"
    ! [ -d $domainSock_dir ] && mkdir -p $domainSock_dir
    chown www-data.www-data $domainSock_dir

    # Install Xray Core v1.8.4 secara manual
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version 1.8.4

    # Ambil Config Server
    wget -O /etc/xray/config.json "${REPO}config/config.json" >/dev/null 2>&1
    wget -O /etc/systemd/system/runn.service "${REPO}files/runn.service" >/dev/null 2>&1

    domain=$(cat /etc/xray/domain)
    IPVS=$(cat /etc/xray/ipvps)
    print_success "Xray Core v1.8.4 Installed"

    # Konfigurasi Nginx
    clear
    curl -s ipinfo.io/city >> /etc/xray/city
    curl -s ipinfo.io/org | cut -d " " -f 2-10 >> /etc/xray/isp
    print_install "Installing Packet Configuration"

    wget -O /etc/nginx/conf.d/xray.conf "${REPO}config/xray.conf" >/dev/null 2>&1
    sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/xray.conf
    curl -s ${REPO}config/nginx.conf > /etc/nginx/nginx.conf

    # Set Permission
    chmod +x /etc/systemd/system/runn.service

    # Create Xray Service
    rm -rf /etc/systemd/system/xray.service.d
    cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.com
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

    print_success "Xray Core v1.8.4 Installed and Configured"
}



function ins_pw(){
clear
print_install "Setting an SSH Password"
    wget -O /etc/pam.d/common-password "${REPO}files/password"
chmod +x /etc/pam.d/common-password

    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure keyboard-configuration
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/altgr select The default for the keyboard layout"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/compose select No compose key"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/ctrl_alt_bksp boolean false"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/layoutcode string de"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/layout select English"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/modelcode string pc105"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/model select Generic 105-key (Intl) PC"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/optionscode string "
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/store_defaults_in_debconf_db boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/switch select No temporary switch"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/toggle select No toggling"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/unsupported_config_layout boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/unsupported_config_options boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/unsupported_layout boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/unsupported_options boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/variantcode string "
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/variant select English"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/xkb-keymap select "

# go to root
cd

# Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#update
# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Makassar /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
print_success "Password SSH"
}

function ins_limiter(){
clear
print_install "Install Service Limit IP & Quota"
wget -q ${REPO}config/quote && chmod +x quote && ./quote
wget -q ${REPO}config/my-limiter.sh && chmod +x my-limiter.sh && ./my-limiter.sh

print_success "Limit IP Service"
}

clear
function ins_SSHD(){
clear
print_install "Installing SSHD"
wget -q -O /etc/ssh/sshd_config "${REPO}files/sshd" >/dev/null 2>&1
chmod 700 /etc/ssh/sshd_config
systemctl restart ssh
print_success "SSHD"
}

clear
function ins_vnstat(){
clear
print_install "Installing Vnstat"
# Installing Vnstat
apt -y install vnstat > /dev/null 2>&1
apt -y install libsqlite3-dev > /dev/null 2>&1
wget -q https://humdi.net/vnstat/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc >/dev/null 2>&1 && make >/dev/null 2>&1 && make install >/dev/null 2>&1
cd
vnstat -u -i $NET
sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz >/dev/null 2>&1
rm -rf /root/vnstat-2.6 >/dev/null 2>&1
print_success "Vnstat"
}


function ins_backup(){
clear
print_install "Installing Backup Server"
apt install rclone -y
printf "q\n" | rclone config
wget -O /root/.config/rclone/rclone.conf "${REPO}config/rclone.conf"
cd /bin
git clone  https://github.com/magnific0/wondershaper.git
cd wondershaper
sudo make install
cd
rm -rf wondershaper
echo > /home/limit
apt install msmtp-mta ca-certificates bsd-mailx -y
cat<<EOF>>/etc/msmtprc
defaults
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account default
host smtp.gmail.com
port 587
auth on
user xiaolitekyt@gmail.com
from xiaolitekyt@gmail.com
password cwmbmtnushnfrlup
logfile ~/.msmtp.log
EOF
chown -R www-data:www-data /etc/msmtprc
wget -q -O /etc/ipserver "${REPO}files/ipserver" && bash /etc/ipserver
print_success "Backup Server"
}

clear
function ins_swab(){
clear
print_install "Installing Swap 1 G"
# Install Gotop
gotop_latest="$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
gotop_link="https://github.com/xxxserxxx/gotop/releases/download/v$gotop_latest/gotop_v"$gotop_latest"_linux_amd64.deb"
curl -sL "$gotop_link" -o /tmp/gotop.deb
dpkg -i /tmp/gotop.deb >/dev/null 2>&1

# Create swap of 1G
dd if=/dev/zero of=/swapfile bs=1024 count=1048576
mkswap /swapfile
chown root:root /swapfile
chmod 0600 /swapfile >/dev/null 2>&1
swapon /swapfile >/dev/null 2>&1
sed -i '$ i\/swapfile      swap swap   defaults    0 0' /etc/fstab

# Sync time
chronyd -q 'server 0.id.pool.ntp.org iburst'
chronyc sourcestats -v
chronyc tracking -v

wget -q ${REPO}files/bbr.sh && chmod +x bbr.sh && ./bbr.sh
print_success "Swap 1 G"
}

function ins_Fail2ban(){
    clear
    print_install "Installing Fail2ban"

    # Update repo dan install Fail2ban
    apt update -y && apt install -y fail2ban > /dev/null 2>&1

    # Cek apakah direktori DDOS sudah ada
    if [ -d "/usr/local/ddos" ]; then
        echo -e "\nUninstalling The Previous Version First..."
        rm -rf /usr/local/ddos
    fi

    # Buat direktori baru
    mkdir -p /usr/local/ddos

    # Unduh file yang diperlukan
    for file in ddos.conf LICENSE ignore.ip.list ddos.sh; do
        wget -q -O "/usr/local/ddos/$file" "http://www.inetbase.com/scripts/ddos/$file" || \
        curl -s -o "/usr/local/ddos/$file" "http://www.inetbase.com/scripts/ddos/$file"
        echo -n '.'
    done
    echo ""

    # Atur izin eksekusi
    chmod +x /usr/local/ddos/ddos.sh
    ln -sf /usr/local/ddos/ddos.sh /usr/local/sbin/ddos

    # Jalankan skrip DDOS dengan cron
    /usr/local/ddos/ddos.sh --cron > /dev/null 2>&1

    # Aktifkan dan restart Fail2ban
    systemctl enable --now fail2ban
    systemctl restart fail2ban

    print_success "Fail2ban"
}

function ins_netfilter(){
clear

wget -q -O /usr/local/share/xray/geosite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" >/dev/null 2>&1
wget -q -O /usr/local/share/xray/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" >/dev/null 2>&1

iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# Clean up unnecessary files
cd
apt autoclean -y >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1
print_success "Netfilter & IPtables"
}

function ins_restart(){
clear
print_install "Restarting All Services"
systemctl restart nginx
systemctl restart ssh
systemctl restart fail2ban
systemctl restart vnstat
systemctl restart cron
systemctl daemon-reload
systemctl enable --now nginx
systemctl enable --now xray
systemctl enable --now rc-local
systemctl enable --now cron
systemctl enable --now netfilter-persistent
systemctl enable --now fail2ban
history -c
echo "unset HISTFILE" >> /etc/profile

cd
rm -f /root/openvpn
rm -f /root/key.pem
rm -f /root/cert.pem
print_success "All Services Restarted"
}

# Install Menu
function menu(){
    clear
    print_install "Installing Menu"
    wget -q ${REPO}menu/menu.zip
    unzip -P supportlite menu.zip
    chmod +x menu/*
    mv menu/* /usr/local/sbin
    sleep 2
    sudo dos2unix /usr/local/sbin/*
 
    sleep 2
    rm -rf menu
    rm -rf menu.zip
}

# Membuat Default Menu 
function profile(){
clear
    cat >/root/.profile <<EOF
# ~/.profile: executed by Bourne-compatible login shells.
if [ "$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi
mesg n || true
menu
EOF

cat >/etc/cron.d/xp_all <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		2 0 * * * root /usr/local/sbin/xp
	END

	cat >/etc/cron.d/logclean <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		*/20 * * * * root /usr/local/sbin/clearlog
		END

    chmod 644 /root/.profile
	
    cat >/etc/cron.d/daily_reboot <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		0 5 * * * root /sbin/reboot
	END

    cat >/etc/cron.d/limit_ip <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		*/2 * * * * root /usr/local/sbin/limit-ip
	END

    cat >/etc/cron.d/limit_ip2 <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		*/2 * * * * root /usr/bin/limit-ip
	END

    echo "*/1 * * * * root echo -n > /var/log/nginx/access.log" >/etc/cron.d/log.nginx
    echo "*/1 * * * * root echo -n > /var/log/xray/access.log" >>/etc/cron.d/log.xray
    systemctl restart cron
    cat >/home/daily_reboot <<-END
		5
	END

cat >/etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
EOF

echo "/bin/false" >>/etc/shells
echo "/usr/sbin/nologin" >>/etc/shells
cat >/etc/rc.local <<EOF
#!/bin/sh -e
# rc.local
# By default this script does nothing.
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
systemctl restart netfilter-persistent
exit 0
EOF

    chmod +x /etc/rc.local
    
    AUTOREB=$(cat /home/daily_reboot)
    SETT=11
    if [ $AUTOREB -gt $SETT ]; then
        TIME_DATE="PM"
    else
        TIME_DATE="AM"
    fi
print_success "Menu Installed"
}

# Restart services after install
function enable_services(){
clear
print_install "Enabling Services"
    systemctl daemon-reload
    systemctl start netfilter-persistent
    systemctl enable --now rc-local
    systemctl enable --now cron
    systemctl enable --now netfilter-persistent
    systemctl restart nginx
    systemctl restart xray
    systemctl restart cron
    print_success "Services Enabled"
    clear
}

# Main Install function
function mulai_penginstallan(){
    clear
    is_root
    base_package
    first_setup
    nginx_install
    make_folder_xray
    pasang_domain
    pasang_ssl
    install_xray
    ins_pw
    ins_limiter
    ins_SSHD
    ins_vnstat
    ins_backup
    ins_swab
    ins_Fail2ban
    ins_netfilter
    ins_restart
    menu
    profile
    enable_services
    
}

mulai_penginstallan
echo ""
history -c
rm -rf /root/menu
rm -rf /root/*.zip
rm -rf /root/*.sh
rm -rf /root/LICENSE
rm -rf /root/README.md
rm -rf /root/domain
#secs_to_human "$(($(date +%s) - ${start}))"
#sudo hostnamectl set-hostname $username
echo -e "${lime}Script Successfully Installed"
read -p "$( echo -e "Press ${YELLOW}[ ${FONT}${YELLOW}Enter${FONT} ${YELLOW}]${FONT} For reboot") "
reboot

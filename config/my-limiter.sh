#!/bin/bash
remove_existing() {
    local service_name="$1"
    local bin_file="$2"

    if systemctl list-units --full -all | grep -q "$service_name"; then
        systemctl stop "$service_name"
        systemctl disable "$service_name"
    fi

    if [[ -f "/etc/systemd/system/$service_name" ]]; then
        rm -f "/etc/systemd/system/$service_name"
    fi

    if [[ -f "$bin_file" ]]; then
        rm -f "$bin_file"
    fi
}

# Hapus layanan dan file lama
remove_existing "limiter-vm.service" "/usr/local/bin/notif-limit-vm"
remove_existing "limiter-vl.service" "/usr/local/bin/notif-limit-vl"
remove_existing "limiter-trj.service" "/usr/local/bin/notif-limit-trj"
remove_existing "limiter-shd.service" "/usr/local/bin/notif-limit-shd"
remove_existing "limiter-ssh.service" "/usr/local/bin/notif-limit-ssh"

# Download dan simpan script ke /usr/local/bin
wget -q -O "/usr/local/bin/notif-limit-vm" "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/files/lite-vm" >/dev/null 2>&1
wget -q -O "/usr/local/bin/notif-limit-vl" "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/files/lite-vl" >/dev/null 2>&1
wget -q -O "/usr/local/bin/notif-limit-trj" "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/files/lite-trj" >/dev/null 2>&1
wget -q -O "/usr/local/bin/notif-limit-shd" "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/files/lite-shd" >/dev/null 2>&1


# Download file layanan sistem
wget -q -O /etc/systemd/system/limiter-vm.service "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/files/limiter-vm.service" >/dev/null 2>&1
wget -q -O /etc/systemd/system/limiter-vl.service "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/files/limiter-vl.service" >/dev/null 2>&1
wget -q -O /etc/systemd/system/limiter-trj.service "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/files/limiter-trj.service" >/dev/null 2>&1
wget -q -O /etc/systemd/system/limiter-shd.service "https://raw.githubusercontent.com/vermiliion/Xray-Only/main/files/limiter-shd.service" >/dev/null 2>&1


# Berikan izin eksekusi
chmod +x /etc/systemd/system/limiter-vm.service
chmod +x /etc/systemd/system/limiter-vl.service
chmod +x /etc/systemd/system/limiter-trj.service
chmod +x /etc/systemd/system/limiter-shd.service

chmod +x /usr/local/bin/notif-limit-vm
chmod +x /usr/local/bin/notif-limit-vl
chmod +x /usr/local/bin/notif-limit-trj
chmod +x /usr/local/bin/notif-limit-shd


# Reload systemd dan aktifkan layanan
systemctl daemon-reload
systemctl enable --now limiter-vm
systemctl enable --now limiter-vl
systemctl enable --now limiter-trj
systemctl enable --now limiter-shd

# Hapus skrip ini sendiri jika sudah selesai
rm -f "$0"
#!/bin/bash

# Fungsi untuk mengonversi ukuran byte ke format yang lebih mudah dibaca
function convert_size() {
    local -i bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes} B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(( (bytes + 1023) / 1024 )) KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$(( (bytes + 1048575) / 1048576 )) MB"
    else
        echo "$(( (bytes + 1073741823) / 1073741824 )) GB"
    fi
}

# Fungsi untuk menghitung jumlah IP yang terhubung
function count_ips() {
    local -i count=$1
    if [[ $count -lt 1024 ]]; then
        echo "${count} IP"
    elif [[ $count -lt 1048576 ]]; then
        echo "$(( (count + 1023) / 1024 )) IP"
    elif [[ $count -lt 1073741824 ]]; then
        echo "$(( (count + 1048575) / 1048576 )) IP"
    else
        echo "$(( (count + 1073741823) / 1073741824 )) IP"
    fi
}

# Membersihkan layar dan file sementara
clear
> /tmp/other.txt

# Mengambil daftar pengguna dari konfigurasi Xray
users=($(grep -E "^#!" "/etc/xray/config.json" | cut -d ' ' -f 2 | sort -u))

for user in "${users[@]}"; do
    [[ -z "$user" ]] && continue

    > /tmp/iptrojan.txt

    # Mengambil daftar IP yang terhubung ke pengguna dari log Xray
    connected_ips=($(grep -w "$user" /var/log/xray/access.log | tail -n 500 | awk '{print $3}' | sed 's/tcp://g' | cut -d ":" -f 1 | sort -u))

    for ip in "${connected_ips[@]}"; do
        if grep -qw "$ip" /var/log/xray/access.log; then
            echo "$ip" >> /tmp/iptrojan.txt
        else
            echo "$ip" >> /tmp/other.txt
        fi
    done

    if [[ -s /tmp/iptrojan.txt ]]; then
        # Mengambil waktu login terakhir
        last_login=$(journalctl -u xray --no-pager | grep -w "$user" | tail -n 1 | awk '{print $1, $2, $3}')
        [[ -z "$last_login" ]] && last_login=$(grep -w "$user" /var/log/xray/access.log | tail -n 1 | awk '{print $2, $3}')

        # Mengambil limit kuota
        limit_quota=$(convert_size "$(cat /etc/trojan/"$user" 2>/dev/null || echo 0)")

        # Menghitung jumlah IP aktif
        active_ip_count=$(wc -l < /tmp/iptrojan.txt)

        # Mengambil limit login (jumlah IP yang diizinkan)
        limit_ip=$(cat /etc/limit/trojan/ip/"$user" 2>/dev/null || echo "Tidak Dibatasi")

        # Menghitung kuota penggunaan
        usage_quota=$(convert_size "$(cat "/etc/limit/trojan/${user}" 2>/dev/null || echo 0)")

        # Menampilkan data pengguna
        echo "User        : ${user}"
        echo "Last Login  : ${last_login:-Tidak Tersedia}"
        echo "Limit Quota : ${limit_quota}"
        echo "Usage Quota : ${usage_quota}"
        echo "Limit Login : ${limit_ip} IP"
        echo "Active IP   : ${active_ip_count}"

        # Menampilkan daftar IP aktif
        nl /tmp/iptrojan.txt
        echo ""
    fi
done

# Membersihkan file sementara
rm -f /tmp/other.txt /tmp/iptrojan.txt
> /var/log/xray/access.log

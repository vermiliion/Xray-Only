#!/bin/bash
XRAY_CONFIG="/etc/xray/config.json"
domainku=$(cat /etc/xray/domain 2>/dev/null || echo "Unknown")
ISP=$(cat /etc/xray/isp 2>/dev/null || echo "Unknown")

# Wadah isolasi file sementara biar aman dari geseran log baru yang super cepat
RAW_SNAPSHOT_FILE="/tmp/xray_raw_snapshot.log"
FILTERED_FINAL_FILE="/tmp/xray_filtered_final.log"

function con() {
    local -i bytes=${1:-0}
    if [[ $bytes -lt 1024 ]]; then echo "${bytes} B";
    elif [[ $bytes -lt 1048576 ]]; then echo "$(( (bytes + 1023)/1024 )) KB";
    elif [[ $bytes -lt 1073741824 ]]; then echo "$(( (bytes + 1048575)/1048576 )) MB";
    else echo "$(( (bytes + 1073741823)/1073741824 )) GB"; fi
}

function memulai_pengecekan() {
    # 1. Ambil snapshot log porsi besar (100 ribu baris) agar user sepi tidak hilang kegusur akun berisik
    tail -n 100000 "/var/log/xray/access.log" > "$RAW_SNAPSHOT_FILE" 2>/dev/null

    # 2. SETINGAN AMBANG BATAS KONKURENSI 5 DETIK (Sesuai setelan akurat maseee)
    local TIME_WINDOW_MINUTES=1
    local LIVENESS_THRESHOLD_SECONDS=5  
    local now=$(date +%s)
    
    local search_pattern=$(for i in $(seq 0 $TIME_WINDOW_MINUTES); do date -d "$i minutes ago" +'%Y/%m/%d %H:%M'; done | tr '\n' '|' | sed 's/|$//')
    grep -E "^($search_pattern)" "$RAW_SNAPSHOT_FILE" > "$FILTERED_FINAL_FILE" 2>/dev/null

    # Ambil semua daftar nama user resmi bertanda khusus #& dari config.json
    mapfile -t data < <(grep -E '^#& ' "$XRAY_CONFIG" 2>/dev/null | awk '{print $2}' | sed 's/_LOCKED//g' | sort -u)
    
    local any_user_active=false

    for user in "${data[@]}"; do
        [[ -z "$user" ]] && continue
        
        # Cek apakah nama user dari json ini terendus di log karantina
        if ! grep -q "email: $user" "$FILTERED_FINAL_FILE"; then
            continue
        fi

        # Ambil daftar IP unik setelah kata 'from ' dan buang IP lokal localhost / 127.0.0.1
        mapfile -t unique_ips < <(
            grep "email: $user" "$FILTERED_FINAL_FILE" \
            | awk -F 'from ' '{print $2}' \
            | awk -F ':' '{print $1}' \
            | grep -v -E "127.0.0.1|localhost|tcp|udp" \
            | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
            | sort -u
        )

        local live_ip_count=0

        # PROSES VALIDASI REAL-TIME: Hitung IP yang benar-benar aktif memompa data bersamaan
        for ip in "${unique_ips[@]}"; do
            # Ambil baris data log paling terakhir khusus dari IP unik ini
            local last_line=$(grep "$ip" "$FILTERED_FINAL_FILE" | grep "email: $user" | tail -n 1)
            [[ -z "$last_line" ]] && continue

            # Bedah waktu kirim data terakhirnya (Ambil Tanggal & Jam)
            local timestamp_str=$(echo "$last_line" | awk '{print $1, $2}')
            local last_seen_timestamp=$(date -d "$timestamp_str" +%s 2>/dev/null || echo 0)

            if [[ "$last_seen_timestamp" -ne 0 ]]; then
                local time_diff=$((now - last_seen_timestamp))
                
                # IP dihitung BENAR-BENAR HIDUP jika interaksi terakhirnya kurang atau sama dengan 5 detik
                if [[ "$time_diff" -le "$LIVENESS_THRESHOLD_SECONDS" ]]; then
                    ((live_ip_count++))
                fi
            fi
        done

        # Naikkan data user ke tampilan monitoring
        any_user_active=true
        
        local user_lower=$(echo "$user" | tr '[:upper:]' '[:lower:]')
        local raw_limit_ip=$(cat /etc/limit/vless/ip/"$user" 2>/dev/null || cat /etc/limit/vless/ip/"$user_lower" 2>/dev/null || echo 0)
        local limit_ip=$(echo "$raw_limit_ip" | grep -o '[0-9]\+')
        [[ -z "$limit_ip" ]] && limit_ip=0
        
        # Membaca basis data kuota limit dan pemakaian
        local file_limit="/etc/vless/$user"
        [[ ! -f "$file_limit" ]] && file_limit="/etc/vless/$user_lower"
        
        local file_usage="/etc/limit/vless/$user"
        [[ ! -f "$file_usage" ]] && file_usage="/etc/limit/vless/$user_lower"

        local limit_quota_ku=$(con "$(cat "$file_limit" 2>/dev/null || echo 0)")
        local usage_quota_ku=$(con "$(cat "$file_usage" 2>/dev/null || echo 0)")

        # Atur teks status keaktifan HP berdasarkan logika konkuren maseee
        if [[ "$live_ip_count" -eq 0 ]]; then
            local active_display="1 IP"
        elif [[ "$limit_ip" -ne 0 && "$live_ip_count" -gt "$limit_ip" ]]; then
            local active_display="${live_ip_count} IP (MELANGGAR)"
        else
            local active_display="${live_ip_count} IP"
        fi

        # FORMAT TAMPILAN SESUAI REQUEST MASEEE (Tegak Lurus & Polos Untuk Bot)
        printf "User       : %-22s\n" "${user}"
        printf "Kuota      : %s / %s\n" "${usage_quota_ku}" "${limit_quota_ku}"
        printf "Limit IP   : %s IP\n" "${limit_ip}"
        printf "IP Aktif   : %s\n" "${active_display}"
        echo ""
    done
    
    if [ "$any_user_active" = false ]; then
        echo "Tidak ada user yang aktif"
        echo ""
    fi

    # Hapus file sampah snapshot karantina log demi menjaga performa penyimpanan VPS
    rm -f "$RAW_SNAPSHOT_FILE"
    rm -f "$FILTERED_FINAL_FILE"
}

memulai_pengecekan
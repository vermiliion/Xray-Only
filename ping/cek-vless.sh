#!/bin/bash
clear
TIME_WINDOW_MINUTES=2
LIVENESS_THRESHOLD_SECONDS=60
FULL_LOG_FILE="/var/log/xray/access.log"
FILTERED_LOG_FILE="/tmp/xray_filtered_temp.log"

convert_size() {
    local -i bytes=${1:-0}
    if [[ $bytes -lt 1024 ]]; then echo "${bytes} B";
    elif [[ $bytes -lt 1048576 ]]; then echo "$(( (bytes + 1023)/1024 )) KB";
    elif [[ $bytes -lt 1073741824 ]]; then echo "$(( (bytes + 1048575)/1048576 )) MB";
    else echo "$(( (bytes + 1073741823)/1073741824 )) GB"; fi
}

search_pattern=$(for i in $(seq 0 $TIME_WINDOW_MINUTES); do date -d "$i minutes ago" +'%Y/%m/%d %H:%M'; done | tr '\n' '|' | sed 's/|$//')
grep -E "($search_pattern)" "$FULL_LOG_FILE" > "$FILTERED_LOG_FILE"

mapfile -t users < <(grep '#&' /etc/xray/config.json 2>/dev/null | awk '{print $2}' | sort -u)
ACTIVE_USERS_FOUND=0
now=$(date +%s)

for user in "${users[@]}"; do
    [[ -z "$user" ]] && continue

    mapfile -t unique_ips < <(grep "email: $user" "$FILTERED_LOG_FILE" | awk '{print $3}' | cut -d: -f1 | sort -u)

    live_ip_count=0

    for ip in "${unique_ips[@]}"; do
        case "$ip" in
            127.0.0.1|10.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|192.168.*) continue ;;
        esac

        last_line=$(grep "$ip" "$FILTERED_LOG_FILE" | grep "email: $user" | tail -n 1)
        [[ -z "$last_line" ]] && continue

        timestamp_str=$(echo "$last_line" | awk '{print $1, $2}')
        last_seen_timestamp=$(date -d "$timestamp_str" +%s 2>/dev/null || echo 0)

        # Jika waktu valid, cek apakah IP ini masih "panas" (aktif)
        if [[ "$last_seen_timestamp" -ne 0 ]]; then
            time_diff=$((now - last_seen_timestamp))
            if [[ "$time_diff" -le "$LIVENESS_THRESHOLD_SECONDS" ]]; then
                ((live_ip_count++))
            fi
        fi
    done

    if [[ "$live_ip_count" -gt 0 ]]; then
        ACTIVE_USERS_FOUND=1
        limit_quota=$(convert_size "$(cat "/etc/vless/$user" 2>/dev/null || echo 0)")
        usage_quota=$(convert_size "$(cat "/etc/limit/vless/${user}" 2>/dev/null || echo 0)")
        limit_ip=$(cat "/etc/limit/vless/ip/$user" 2>/dev/null || echo "N/A")
        
        total_log_count=$(grep -w "$user" "$FILTERED_LOG_FILE" | wc -l)
     
        printf "%-35s \n" "User        : ${user}"
        printf "Status     : %-24s \n" "ONLINE"
        printf "%-35s \n" "Kuota      : ${usage_quota} / ${limit_quota}"
        printf "%-35s \n" "Limit IP   : ${limit_ip} IP"
        printf "%-35s \n" "Total Log: ${total_log_count}"
        
        if [[ "$limit_ip" != "N/A" && "$live_ip_count" -gt "$limit_ip" ]]; then
            printf "IP Aktif    : %-24s \n\n" "${live_ip_count} IP (MELANGGAR)"
        else
            printf "%-35s \n\n" "IP Aktif    : ${live_ip_count} IP"
        fi
    fi
done

if [[ "$ACTIVE_USERS_FOUND" -eq 0 ]]; then
    printf "%-35s \n\n" "Tidak ada user yang aktif"
fi

rm -f "$FILTERED_LOG_FILE"
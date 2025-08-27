**Assalamua'laikum Warahmatullahi Wabarrakatuh Sahabat 🫡**
- Script Ini Saya Buat Untuk Membantu Para Sahabat Sekalian untuk Jualan Akun VPN Xray Atau Untuk Berbagi Juga 😁
- Jadi Harap Di Gunakan Dengan Bijak Nggeh 🫡

- Jangan Sampai Di Perjual Belikan Ya Sahabat 🤩
- Contoh Aku Ada Script Xray All Os Nih Mau Beli Nggak?
Dan Ternyata Script Yang Di Maksud Adalah Script Ini Yang Ada Di Reposytori Saya,
Jadi Kasihan kan Untuk Yg Lain Yang Sebenarnya Gratis Tapi Malah Di Perjual Belikan.

- Jika Sahabat Sekalian Mau Beli Scriptnya Biar Jadi Milik Sahabat
- Silahkan Hubungi Kontak Telegram Saya
https://t.me/xiaokecil
- Nanti Dapet Source Code Aslinya, Harganya Cukup Rp.95k Aja Untuk Sahabat Sekalian 🫡
- Saya Juga Ada Script Yang ada Menu SSH nya Lengkap Sama Bot Untuk Jualan 😁
- Harga Sewa Script nya:
- 10k aja per 1 bulan Untuk 1 IP VPS
- 25k aja per 3 Bulan Untuk 1 IP VPS
- 75k aja per 1 Tahun Untuk 2 IP VPS

### Cara Pasang Script

- Jangan Lupa Gabung Channel Dulu Sebelum Pasang Scriptnya
- Biar Berkah, Serta Biar Tahu Juga Tentang Updetan Terbaru dari Scriptnya🫡
https://t.me/freenetlite
- Gunakan Perintah Ini Untuk Install scriptnya, salin lalu tempel atau paste di VPS Secara Berurutan:

- Langkah Ke 1
```
echo -e "net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf && sysctl -p
```
- Langkah Ke 2
```
apt update -y && apt upgrade -y --fix-missing && apt install -y xxd bzip2 wget curl sudo lsof socat net-tools build-essential bsdmainutils screen dos2unix && update-grub && apt dist-upgrade -y && sleep 2 && reboot
```
- Langkah Ke 3
```
screen -S setup-session bash -c "wget -q https://raw.githubusercontent.com/vermiliion/Xray-Only/main/setup.sh && chmod +x setup.sh && ./setup.sh"
```
### INFORMASI
- Jika mengalami putus koneksi saat penginstallan atau instalasi
- sambungkan kembali dengan perintah berikut di bawah ini dan paste di vps:
```
screen -r -d setup
```
### Untuk Perbarui Script
```
wget -q https://raw.githubusercontent.com/vermiliion/Xray-Only/main/update.sh && chmod +x update.sh && ./update.sh && rm -rf update.sh
```

**Terimakasih Untuk BIN456789**

**rebuil debian 10**
<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh debian 10 && reboot</code></pre>
**rebuil debian 11**

<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh debian 11 && reboot</code></pre>
**rebuild debian 12**

<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh debian 12 && reboot</code></pre>
**rebuild debian 13**

<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh debian 13 && reboot</code></pre>
**rebuild ubuntu 20**

<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh ubuntu 20.04 && reboot</code></pre>
**rebuild ubuntu 22**

<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh ubuntu 22.04 && reboot</code></pre>
**rebuild ubuntu 24**

<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh ubuntu 24.04 && reboot</code></pre>

**Rebuild ubuntu 25**
```
curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh ubuntu 25.04 && reboot
```

### FITUR SCRIPT

- Cek penggunaan CPU & RAM dengan gotop
- Notifikasi Bot Telegram
- Panel Bot Telegram
- Ubah UUID Xray secara kustom
- Batas Kuota & Cek Total Penggunaan Kuota untuk Xray
- Kunci Otomatis Pengguna Xray yang Multi Login
- Dan lain-lain

**MENDUKUNG DI OS:**
- Debian:

- 10 (Buster): Stabil
- 11 (Bullseye): Stabil
- 12 (Bookworm): Stabil
- 13 (trixie) : Tes Sendiri karena saya belom coba

- Ubuntu:

- 20.04 LTS (Focal): Stabil
- 22.04 LTS (Jammy): Stabil
- 24.04 LTS (Noble): Stabil
- 25.04 LTS (Noble): Stabil (Kecuali Bot Ndak Jalan)


**MENDUKUNG DI PORT:**

- HTTP  : 80, 8080, 2082, 2086, 8880
- HTTPS : 443, 2083, 8443

**Spesifikasi Minimum VPS:**

- RAM: 1 GB (Minimal)
- SSD: 10 GB
- 1 vCPU


**HAK CIPTA & LISENSI:**

Skrip dilisensikan di bawah CC BY-SA 4.0.
Hak Cipta © 2025 oleh Lite Vermilion Project



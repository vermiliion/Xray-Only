- 1
```
echo -e "net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf && sysctl -p
```
- 2
```
apt update -y && apt upgrade -y --fix-missing && apt install -y xxd bzip2 wget curl sudo lsof socat net-tools bc coreutils build-essential bsdmainutils screen dos2unix && update-grub && apt dist-upgrade -y && sleep 2 && reboot
```
- 3
```
screen -S setup-session bash -c "wget -q https://raw.githubusercontent.com/vermiliion/Xray-Only/main/setup.sh && chmod +x setup.sh && ./setup.sh"
```
### Untuk Menghubungkan Ulang
```
screen -r -d setup
```
### Update Script
```
wget -q https://raw.githubusercontent.com/vermiliion/Xray-Only/main/update.sh && chmod +x update.sh && ./update.sh && rm -rf update.sh
```

**reode></pr*
<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh debian 10 && reboot</code></pre>
**rebuild debian 11**

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

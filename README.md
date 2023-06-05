# routeros-chr-cloud-config
Cloud Configs for installing MikroTik RouterOS CHR

## How to use
1. Choose the cloud config `.yml` file that best suits you.
2. Copy and paste the cloud config `.yml` contents where applicable for your cloud.  (I make use of Hetzner Cloud, though your cloud may work without any changes necessary.)
3. (Optional) Specify an alternate disk device to install to.  Change it at the bottom of the `.yml` contents (default is /dev/sda): 
    - `  - /root/install-routeros-chr-7.x-stable.sh /dev/sda >/dev/tty1 2>&1`
4. The RouterOS CHR image will be downloaded, written to disk, and the OS partition will be maximized.
5. Once installed, RouterOS will be available via SSH, HTTP (port `80`), and WinBox (port `8291`) by default.  Enjoy!

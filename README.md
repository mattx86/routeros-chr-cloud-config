# routeros-chr-cloud-config
Cloud Configs for installing MikroTik RouterOS CHR

## How to use
1. Choose the cloud config `.yml` file that best suits you.
2. Copy and paste the cloud config `.yml` contents where applicable for your cloud.  (I make use of Hetzner Cloud, though your cloud may work without any changes necessary.)
3. (Optional) Specify an alternate disk device to install to, and whether to `install` or make an install `iso`.  Change it at the bottom of the `.yml` contents (default is `/dev/sda` and `install`): 
    - Example: `  - /root/routeros-chr-7.x-stable.sh /dev/sda install >/dev/tty1 2>&1`
4. The RouterOS CHR image will be downloaded and either installed to disk or create an install ISO for download.
5. Once installed, RouterOS will be available via SSH (port `22`), HTTP (port `80`), and WinBox (port `8291`) by default.  Enjoy!

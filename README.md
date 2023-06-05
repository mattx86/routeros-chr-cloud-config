# routeros-chr-cloud-config
Cloud Configs for installing MikroTik RouterOS CHR

## How to use
1. Choose the cloud config `.yml` file that best suits you.
2. Copy and paste the cloud config `.yml` contents where applicable for your cloud.  (I make use of Hetzner Cloud, though your cloud may work without any changes necessary.)
3. The RouterOS CHR image will be downloaded, written to disk, and the OS partition will be maximized.
4. Once installed, RouterOS will be available via SSH, HTTP (port `80`), and WinBox (port `8291`) by default.  Enjoy!

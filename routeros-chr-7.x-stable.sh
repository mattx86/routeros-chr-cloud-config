#!/bin/bash
#
# Copyright (c) 2023 Matt Smith
# MIT License
#
CHR_DISK="${1:-/dev/sda}"
ACTION="${2:-install}"

CHR_ZIP_URL=$(curl -Ls https://mikrotik.com/download | egrep -o 'https://.*/chr-7\.[0-9.]+\.img\.zip')
CHR_ZIP=/root/${CHR_ZIP_URL##*/}
CHR_IMG=${CHR_ZIP%*.zip}
CHR_VERSION=$(echo ${CHR_ZIP_URL##*/} | sed -re 's;^chr-;;' -e 's;\.img\.zip$;;')

FINNIX_VERSION=125
FINNIX_ISO_URL=https://ftp-nyc.osuosl.org/pub/finnix/${FINNIX_VERSION}/finnix-${FINNIX_VERSION}.iso
FINNIX_ISO=/root/finnix.iso
FINNIX_MOUNT=/mnt/finnix
FINNIX_UNSQUASHED=/root/finnix_unsquashed
FINNIX_SQUASHFS=/root/filesystem.squashfs

# Download the Finnix ISO and extract filesystem.squashfs.
curl -L $FINNIX_ISO_URL -o $FINNIX_ISO
mkdir $FINNIX_MOUNT
mount -o loop,ro $FINNIX_ISO $FINNIX_MOUNT
unsquashfs -d $FINNIX_UNSQUASHED $FINNIX_MOUNT/live/filesystem.squashfs
umount $FINNIX_MOUNT

# Download and copy the CHR image.
curl -L $CHR_ZIP_URL -o $CHR_ZIP
unzip $CHR_ZIP -d $(dirname $CHR_IMG)
cp $CHR_IMG $FINNIX_UNSQUASHED/root/

# Create Finnix ISO's rc.local script for installing CHR.
cat <<EOF >$FINNIX_UNSQUASHED/etc/rc.local
#!/bin/bash
PART_NUM=2
PART_NEW_SIZE=\$(lsblk $CHR_DISK | egrep "^${CHR_DISK##*/}" | awk '{match(\$4, /([A-Z])/, unit); sub(/[A-Z]/, "", \$4); size=\$4; print size unit[1]"iB"}')

dd if=$CHR_IMG of=$CHR_DISK bs=10M
parted $CHR_DISK resizepart \$PART_NUM \$PART_NEW_SIZE
e2fsck -fp ${CHR_DISK}\${PART_NUM}
resize2fs ${CHR_DISK}\${PART_NUM}

reboot
exit 0
EOF
chmod +x $FINNIX_UNSQUASHED/etc/rc.local

# Resquash the Finnix filesystem and update the Finnix ISO.
mksquashfs $FINNIX_UNSQUASHED $FINNIX_SQUASHFS -comp xz
xorriso -dev $FINNIX_ISO -boot_image any keep -boot_image grub partition_table=on -update $FINNIX_SQUASHFS /live/filesystem.squashfs

if [ "$ACTION" == "install" ] ; then

  # Add a grub entry for booting the ISO.
  cat <<EOF >/etc/grub.d/40_custom
#!/bin/sh
exec tail -n +3 \$0
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
menuentry 'Install RouterOS CHR $CHR_VERSION' --class ubuntu --class gnu-linux --class gnu --class os {
        recordfail
        load_video
        insmod gzio
        insmod part_gpt
        insmod ext2
        loopback loop (hd0,1)$FINNIX_ISO
        echo    'Loading vmlinuz ...'
        linux   (loop)/live/vmlinuz findiso=$FINNIX_ISO toram boot=live components
        echo    'Loading initrd.img ...'
        initrd  (loop)/live/initrd.img
}
EOF

  # Update grub and install RouterOS CHR to disk.
  update-grub
  grub-reboot "Install RouterOS CHR $CHR_VERSION"
  reboot

elif [ "$ACTION" == "iso" ] ; then

  apt-get install -y nginx
  ufw allow http
  ufw allow https
  FINAL_FILENAME="routeros-chr-${CHR_VERSION}-install.iso"
  ADDRESSES=$(ip addr | grep -P 'inet (?!127)' | awk '{sub(/\/[0-9]+/, "", $2); print $2}')
  /bin/mkdir /var/www/html/routeros
  /bin/mv $FINNIX_ISO /var/www/html/routeros/${FINAL_FILENAME}
  cd /var/www/html/routeros
  sha256sum -b $FINAL_FILENAME >${FINAL_FILENAME}.sha256
  openssl req -nodes -newkey rsa:2048 -keyout /etc/ssl/private/routeros.iso.key -out /tmp/routeros.iso.csr -subj "/C=XX/ST=Unknown/L=Unknown/O=Unknown/OU=Unknown/CN=routeros.iso"
  openssl x509 -signkey /etc/ssl/private/routeros.iso.key -in /tmp/routeros.iso.csr -req -days 365 -out /etc/ssl/certs/routeros.iso.crt
  echo '
server {
	listen 80 default_server;
	listen [::]:80 default_server;
	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;
	ssl_certificate /etc/ssl/certs/routeros.iso.crt;
	ssl_certificate_key /etc/ssl/private/routeros.iso.key;
	root /var/www/html;
	default_type text/plain;
	index index.html index.nginx-debian.html;
	server_name _;
	location / {
		autoindex on;
		try_files $uri $uri/ =404;
	}
}' > /etc/nginx/sites-enabled/default
  systemctl restart nginx
  echo
  echo "===================================="
  echo "Get the RouterOS CHR Install ISO at:"
  for ADDRESS in $ADDRESSES; do
    echo "http://${ADDRESS}/routeros/${FINAL_FILENAME}"
    echo "https://${ADDRESS}/routeros/${FINAL_FILENAME}"
  done
  echo "===================================="
  echo 

fi

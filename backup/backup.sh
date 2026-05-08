#!/bin/bash

DATE=$(date +%y-%m-%d)
PASS="change-me"
DB_HOST="192.168.2.2"

mkdir -p ${DATE}
mnt=$(podman mount app)
cp -R ${mnt}/opt/app-root/src/upload ${DATE}
cp ${mnt}/opt/app-root/src/application/config/config.php ${DATE}
cp ${mnt}/opt/app-root/src/application/config/security.php ${DATE}
cp ${mnt}/opt/app-root/src/vendor/phpmailer/phpmailer/src/PHPMailer.php ${DATE}
podman umount app

mysqldump --no-tablespaces \
          --user=ztap \
          --password=${PASS} \
          --database assessment \
          --port=3308 \
          --host=${DB_HOST} > ${DATE}/ztap-${DATE}.sql

cp -R /opt/nginx ${DATE}
cp -R /etc/cloudflared ${DATE}
tar cfvz ${DATE}.$$.tar.gz ${DATE}
chown ztap:users ${DATE}.$$.tar.gz
rm -rf ${DATE}

gpg --batch --yes --encrypt --recipient "email@example.com" ${DATE}.$$.tar.gz
rm -f ${DATE}.$$.tar.gz
chown ztap:users ${DATE}.$$.tar.gz.gpg

# send the backup off site
# su - ztap -c "scp -P 22 backup/${DATE}.$$.tar.gz.gpg user@offsite.com:backup"


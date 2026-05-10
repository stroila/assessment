#!/bin/bash
set -euo pipefail

# --- Explicit environment for cron ---
PATH=/usr/local/bin:/usr/bin:/bin
HOME=/root
HOST_USER=user

DATE=$(date +%y-%m-%d)
PASS="change-me"
HOST="HOST_IP"
WORKDIR="/opt/backup"
TMPDIR="${WORKDIR}/${DATE}"
DB_USER="db"

mkdir -p "${TMPDIR}"
cd "${WORKDIR}"

# --- Podman requires full path + correct user ---
PODMAN=/usr/bin/podman

mnt=$(${PODMAN} mount app)

cp -R "${mnt}/opt/app-root/src/upload" "${TMPDIR}/"
cp "${mnt}/opt/app-root/src/application/config/config.php" "${TMPDIR}/"
cp "${mnt}/opt/app-root/src/application/config/security.php" "${TMPDIR}/"
cp "${mnt}/opt/app-root/src/vendor/phpmailer/phpmailer/src/PHPMailer.php" "${TMPDIR}/"

${PODMAN} umount app

# --- mysqldump with full path ---
/usr/bin/mysqldump \
  --no-tablespaces \
  --user=${DB_USER} \
  --password="${PASS}" \
  --databases db \
  --port=3306 \
  --host="${HOST}" \
  > "${TMPDIR}/app-${DATE}.sql"

cp -R /opt/nginx "${TMPDIR}/"
cp -R /etc/cloudflared "${TMPDIR}/"

ARCHIVE="${WORKDIR}/${DATE}.$$.tar.gz"
tar czf "${ARCHIVE}" "${DATE}"
chown ${HOST_USER}:users "${ARCHIVE}"

rm -rf "${TMPDIR}"

# --- gpg must be non-interactive ---
/usr/bin/gpg \
  --batch \
  --yes \
  --trust-model always \
  --encrypt \
  --recipient "user@example.com" \
  "${ARCHIVE}"

rm -f "${ARCHIVE}"
chown ${HOST_USER}:users "${ARCHIVE}.gpg"

# --- su needs -s to avoid TTY issues ---
/bin/su -s /bin/bash ${HOST_USER} -c \
  "/usr/bin/scp -P 22 '${ARCHIVE}.gpg' user@remote.com:backup"


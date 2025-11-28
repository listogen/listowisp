#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# LISTOWISP v02.0 – Post Install Script
# ==========================================================

APP_DIR="/var/www/listowisp"
APP_USER="lwisp"
WEB_GROUP="www-data"
PHP_BIN="php"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Please run as root."
  exit 1
fi

if [ ! -d "$APP_DIR" ]; then
  echo "ERROR: App directory $APP_DIR not found."
  exit 1
fi

cd "$APP_DIR"

mkdir -p storage/framework/sessions
mkdir -p storage/framework/cache
mkdir -p storage/framework/views
mkdir -p storage/logs
chown -R lwisp:www-data storage bootstrap
find storage bootstrap/cache -type d -exec chmod 775 {} \;
find storage bootstrap/cache -type f -exec chmod 664 {} \;

echo ">>> [1/4] Ensure scheduler cron entry..."
CRON_LINE="* * * * * www-data $PHP_BIN $APP_DIR/artisan schedule:run >> /dev/null 2>&1"
( crontab -u www-data -l 2>/dev/null | grep -Fv 'artisan schedule:run' ; echo "$CRON_LINE" ) | crontab -u www-data -

echo ">>> [2/4] Supervisor/queue workers..."

QUEUE_CONF="/etc/supervisor/conf.d/listowisp-queue.conf"

cat > "$QUEUE_CONF" <<EOF
[program:listowisp-queue]
command=$PHP_BIN $APP_DIR/artisan queue:work --sleep=3 --tries=3 --max-time=3600
directory=$APP_DIR
user=www-data
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/listowisp-queue.log
stopwaitsecs=3600
EOF

supervisorctl reread
supervisorctl update
supervisorctl restart listowisp-queue || true

echo ">>> [3/4] Generate Swagger / OpenAPI docs (if L5-Swagger installed)..."
$PHP_BIN artisan l5-swagger:generate || true

echo ">>> [4/4] Final permissions..."
if id "$APP_USER" >/dev/null 2>&1; then
  chown -R "$APP_USER":"$WEB_GROUP" "$APP_DIR"
else
  echo "WARNING: User $APP_USER does not exist. Skipping chown."
fi
find "$APP_DIR/storage" "$APP_DIR/bootstrap/cache" -type d -exec chmod 775 {} \;

echo "=================================================="
echo "LISTOWISP v02.0 post-install complete."
echo "=================================================="

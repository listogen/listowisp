#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# LISTOWISP v02.0 – Application Install / Update
# ==========================================================

# ---------- CONFIGURABLE ENV SETTINGS ----------
APP_DIR="/var/www/listowisp"
APP_USER="lwisp"
WEB_GROUP="www-data"

# App / environment
APP_ENVIRONMENT="local"
APP_DEBUG="true"
APP_URL="http://localhost"

# Database
DB_NAME="listowisp"
DB_USER="listowispuser"
DB_PASS="Password"
DB_HOST="127.0.0.1"
DB_PORT="3306"

# Mail defaults
MAIL_MAILER="log"
MAIL_HOST="127.0.0.1"
MAIL_PORT="1025"
MAIL_USERNAME=""
MAIL_PASSWORD=""
MAIL_ENCRYPTION=""
MAIL_FROM_ADDRESS="no-reply@listowisp.pro"
MAIL_FROM_NAME="LISTOWISP"

# Schema + seed files (v02 naming)
SCHEMA_BASE="$APP_DIR/database/schema/010_base_schema_v02.sql"
SCHEMA_SERVICES_V2="$APP_DIR/database/schema/020_services_v02.sql"
PATCH_DIR="$APP_DIR/database/schema/patches"
SEED_CORE="$APP_DIR/database/seeds/seed_core_minimal_v02.sql"

# ----------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Please run as root."
  exit 1
fi

if [ ! -d "$APP_DIR" ]; then
  echo "ERROR: App directory $APP_DIR does not exist."
  exit 1
fi

echo ">>> Ensuring database and user exist..."
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost'
  IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

cd "$APP_DIR"

echo ">>> Installing PHP dependencies (composer install)..."
if [ -f "composer.json" ]; then
  if id "$APP_USER" >/dev/null 2>&1; then
    sudo -u "$APP_USER" -H bash -c 'composer install --no-dev --optimize-autoloader'
  else
    composer install --no-dev --optimize-autoloader
  fi
else
  echo "WARNING: composer.json not found, skipping composer install."
fi

echo ">>> Building frontend assets (npm/yarn)..."
if [ -f "package.json" ]; then
  if id "$APP_USER" >/dev/null 2>&1; then
    sudo -u "$APP_USER" -H bash -c '
      if [ -f "package-lock.json" ] || [ -f "npm-shrinkwrap.json" ]; then
        npm install
      elif [ -f "yarn.lock" ]; then
        yarn install
      else
        npm install
      fi
      npm run build
    '
  else
    if [ -f "package-lock.json" ] || [ -f "npm-shrinkwrap.json" ]; then
      npm install
    elif [ -f "yarn.lock" ]; then
      yarn install
    else
      npm install
    fi
    npm run build
  fi
else
  echo "No package.json found, skipping frontend build."
fi

echo ">>> Preparing .env (fresh write)..."

if [ -f ".env" ]; then
  echo " - Backing up existing .env to .env.bak"
  cp .env ".env.bak"
fi

cat > .env <<EOF
APP_NAME="LISTOWISP"
APP_ENV=${APP_ENVIRONMENT}
APP_KEY=
APP_DEBUG=${APP_DEBUG}
APP_URL="${APP_URL}"

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_DATABASE=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASS}

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database
SESSION_DRIVER=database
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=${MAIL_MAILER}
MAIL_HOST=${MAIL_HOST}
MAIL_PORT=${MAIL_PORT}
MAIL_USERNAME=${MAIL_USERNAME}
MAIL_PASSWORD=${MAIL_PASSWORD}
MAIL_ENCRYPTION=${MAIL_ENCRYPTION}
MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS}"
MAIL_FROM_NAME="${MAIL_FROM_NAME}"

DB_FOREIGN_KEYS=true
EOF

echo ">>> Generating APP_KEY..."
php artisan key:generate --force || true

echo ">>> Importing base schema..."
if [ -f "$SCHEMA_BASE" ]; then
  mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SCHEMA_BASE"
else
  echo "WARNING: Base schema file $SCHEMA_BASE not found. Skipping."
fi

echo ">>> Importing services v02 schema..."
if [ -f "$SCHEMA_SERVICES_V2" ]; then
  mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SCHEMA_SERVICES_V2"
else
  echo "WARNING: Services v02 schema file $SCHEMA_SERVICES_V2 not found. Skipping."
fi

echo ">>> Applying schema patches (if any)..."
if [ -d "$PATCH_DIR" ]; then
  PATCH_FILES=$(find "$PATCH_DIR" -maxdepth 1 -type f -name '*.sql' | sort)
  for patch in $PATCH_FILES; do
    echo " - Applying patch: $(basename "$patch")"
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$patch"
  done
else
  echo "No patches directory found at $PATCH_DIR. Skipping patches."
fi

echo ">>> Importing core seed data..."
if [ -f "$SEED_CORE" ]; then
  mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SEED_CORE"
else
  echo "WARNING: Seed file $SEED_CORE not found. Skipping core seeds."
fi

echo "Back safeguard....May removed in later versions"
mkdir -p resources/views
mkdir -p storage/framework/views
php artisan config:clear || true


echo ">>> Laravel optimizations..."
php artisan storage:link || true
php artisan config:clear || true
php artisan cache:clear || true
php artisan route:clear || true
php artisan view:clear || true

php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

echo ">>> Fixing permissions..."
if id "$APP_USER" >/dev/null 2>&1; then
  chown -R "$APP_USER":"$WEB_GROUP" "$APP_DIR"
else
  echo "WARNING: User $APP_USER does not exist. Skipping chown."
fi
find "$APP_DIR/storage" "$APP_DIR/bootstrap/cache" -type d -exec chmod 775 {} \;

echo "=================================================="
echo "LISTOWISP v02.0 install/update complete."
echo "Next: run scripts/post_install_listowisp_v02.sh"
echo "=================================================="

#!/bin/bash
set -e

export PORT=${PORT:-80}
envsubst '$PORT' < /etc/nginx/nginx.template.conf > /etc/nginx/nginx.conf

# Generate backend .env from container environment variables
cat > /var/www/backend/.env <<EOF
APP_NAME=${APP_NAME:-PharmaCare}
APP_ENV=${APP_ENV:-production}
APP_DEBUG=${APP_DEBUG:-false}
APP_TIMEZONE=UTC
APP_BASE_PATH=${APP_BASE_PATH:-none}
DB_HOST=${DB_HOST:-127.0.0.1}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-railway}
DB_USER=${DB_USER:-root}
DB_PASS=${DB_PASS:-}
JWT_SECRET=${JWT_SECRET:-change-me-in-production}
JWT_EXPIRY=${JWT_EXPIRY:-900}
JWT_REFRESH_EXPIRY=${JWT_REFRESH_EXPIRY:-604800}
CORS_ORIGINS=${CORS_ORIGINS:-*}
MAIL_HOST=${MAIL_HOST:-localhost}
MAIL_PORT=${MAIL_PORT:-1025}
MAIL_USER=${MAIL_USER:-}
MAIL_PASS=${MAIL_PASS:-}
MAIL_FROM=${MAIL_FROM:-noreply@pharmacy.com}
MAIL_FROM_NAME=${MAIL_FROM_NAME:-PharmaCare}
EOF
chown www-data:www-data /var/www/backend/.env
chmod 640 /var/www/backend/.env

mkdir -p /run/php
php-fpm8.2 -D
echo "php-fpm started, socket:"
ls -la /run/php/

# Auto-import schema on first boot (when users table doesn't exist)
DB_H="${DB_HOST:-127.0.0.1}"
DB_P="${DB_PORT:-3306}"
DB_U="${DB_USER:-root}"
DB_W="${DB_PASS:-}"
DB_N="${DB_NAME:-railway}"

# Wait up to 30s for MySQL to be reachable
echo "Waiting for MySQL at $DB_H:$DB_P..."
for i in $(seq 1 30); do
  if mysqladmin ping -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" --silent 2>/dev/null; then
    echo "MySQL is ready."
    break
  fi
  sleep 1
done

TABLE_CHECK=$(mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" -e "SHOW TABLES LIKE 'users';" 2>/dev/null | wc -l)
if [ "$TABLE_CHECK" -eq "0" ]; then
  echo "First boot — importing database schema into $DB_N..."
  mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" < /var/www/backend/database/wave_db.sql \
    && echo "Schema imported successfully." \
    || echo "Schema import failed — check logs."
fi

# Always run migrations (idempotent — CREATE TABLE IF NOT EXISTS)
echo "Running migrations..."
mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" < /var/www/backend/database/migration_wave.sql 2>/dev/null \
  && echo "migration_wave.sql done." || echo "migration_wave.sql had warnings (may be normal)."
mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" < /var/www/backend/database/migration_cash_mgmt.sql 2>/dev/null \
  && echo "migration_cash_mgmt.sql done." || echo "migration_cash_mgmt.sql had warnings (may be normal)."

# Import seed data if categories table is empty
SEED_CHECK=$(mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" -e "SELECT COUNT(*) FROM categories;" 2>/dev/null | tail -1)
if [ "$SEED_CHECK" = "0" ] || [ -z "$SEED_CHECK" ]; then
  echo "Importing seed data..."
  mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" < /var/www/backend/database/seed.sql \
    && echo "Seed data imported successfully." \
    || echo "Seed import failed — check logs."
else
  echo "Seed data already present — skipping."
fi

exec nginx -g 'daemon off;'

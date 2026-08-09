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

# Update currency to EGP if still set to SAR
mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" -e \
  "UPDATE settings SET value='EGP' WHERE \`key\`='currency' AND value='SAR';
   UPDATE settings SET value='ج.م' WHERE \`key\`='currency_symbol' AND value='ر.س';" 2>/dev/null

# Always run migrations (idempotent — CREATE TABLE IF NOT EXISTS)
echo "Running migrations..."
mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" < /var/www/backend/database/migration_wave.sql 2>/dev/null \
  && echo "migration_wave.sql done." || echo "migration_wave.sql had warnings (may be normal)."
mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" < /var/www/backend/database/migration_cash_mgmt.sql 2>/dev/null \
  && echo "migration_cash_mgmt.sql done." || echo "migration_cash_mgmt.sql had warnings (may be normal)."

# Ensure shift_cash_movements table exists (migration_cash_mgmt.sql may stop early on ALTER TABLE errors)
TBL_CHECK=$(mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" -e "SHOW TABLES LIKE 'shift_cash_movements';" 2>/dev/null | wc -l)
if [ "$TBL_CHECK" -eq "0" ]; then
  echo "Creating shift_cash_movements table..."
  mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" -e "
    CREATE TABLE IF NOT EXISTS \`shift_cash_movements\` (
      \`id\`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
      \`shift_id\`   INT UNSIGNED NOT NULL,
      \`type\`       ENUM('cash_in','cash_out') NOT NULL,
      \`amount\`     DECIMAL(12,3) NOT NULL,
      \`reason\`     VARCHAR(255) DEFAULT NULL,
      \`created_by\` INT UNSIGNED NOT NULL,
      \`created_at\` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (\`id\`),
      KEY \`idx_cash_movements_shift\` (\`shift_id\`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  " 2>/dev/null && echo "shift_cash_movements created." || echo "shift_cash_movements creation failed."
else
  echo "shift_cash_movements already exists — skipping."
fi

# Ensure shifts has extended columns — check each individually (ADD COLUMN IF NOT EXISTS
# is MySQL 8.0.3+ only; use SHOW COLUMNS to stay compatible with older versions)
add_shifts_col() {
  local COL="$1" DEF="$2"
  local EXISTS=$(mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" \
    -e "SHOW COLUMNS FROM shifts LIKE '$COL';" 2>/dev/null | wc -l)
  if [ "$EXISTS" -eq "0" ]; then
    mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" \
      -e "ALTER TABLE \`shifts\` ADD COLUMN \`$COL\` $DEF;" 2>/dev/null \
      && echo "  shifts.$COL added." || echo "  shifts.$COL add failed."
  fi
}
add_shifts_col "expected_cash"  "DECIMAL(12,3) DEFAULT NULL"
add_shifts_col "counted_cash"   "DECIMAL(12,3) DEFAULT NULL"
add_shifts_col "difference"     "DECIMAL(12,3) DEFAULT NULL"
add_shifts_col "balance_status" "ENUM('balanced','overage','shortage') DEFAULT NULL"
add_shifts_col "cash_refunds"   "DECIMAL(12,3) NOT NULL DEFAULT 0.000"
add_shifts_col "cash_in_total"  "DECIMAL(12,3) NOT NULL DEFAULT 0.000"
add_shifts_col "cash_out_total" "DECIMAL(12,3) NOT NULL DEFAULT 0.000"

# Add purchase_item_id to return_items if missing
COL_CHECK=$(mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" -e "SHOW COLUMNS FROM return_items LIKE 'purchase_item_id';" 2>/dev/null | wc -l)
if [ "$COL_CHECK" -eq "0" ]; then
  echo "Adding purchase_item_id column to return_items..."
  mysql -h "$DB_H" -P "$DB_P" -u "$DB_U" -p"$DB_W" -D "$DB_N" -e \
    "ALTER TABLE return_items ADD COLUMN purchase_item_id INT NULL AFTER batch_id;" 2>/dev/null \
    && echo "Column added." || echo "Column add failed — check logs."
else
  echo "return_items.purchase_item_id already exists — skipping."
fi

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

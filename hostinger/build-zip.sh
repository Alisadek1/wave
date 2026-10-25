#!/bin/bash
# Run from project root using Git Bash:
# bash hostinger/build-zip.sh

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$PROJECT_ROOT/hostinger/wave-deploy.zip"
TMP="$PROJECT_ROOT/hostinger/_tmp_deploy"

rm -f "$OUT"
rm -rf "$TMP"
mkdir -p "$TMP"

# 1. React build output
cp -r "$PROJECT_ROOT"/public/. "$TMP/"

# 2. Root .htaccess
cp "$PROJECT_ROOT/hostinger/public_html/.htaccess" "$TMP/.htaccess"

# 3. api/ directory
mkdir -p "$TMP/api"
cp "$PROJECT_ROOT/hostinger/public_html/api/.htaccess" "$TMP/api/.htaccess"
cp "$PROJECT_ROOT/hostinger/public_html/api/index.php"  "$TMP/api/index.php"

# 4. backend/ directory
mkdir -p "$TMP/backend"
cp "$PROJECT_ROOT/hostinger/public_html/backend/.htaccess" "$TMP/backend/.htaccess"
cp "$PROJECT_ROOT/hostinger/public_html/backend/.env"      "$TMP/backend/.env"
cp -r "$PROJECT_ROOT/backend/app"      "$TMP/backend/app"
cp -r "$PROJECT_ROOT/backend/config"   "$TMP/backend/config"
cp -r "$PROJECT_ROOT/backend/database" "$TMP/backend/database"
cp -r "$PROJECT_ROOT/backend/storage"  "$TMP/backend/storage"

# 5. Create zip with forward-slash paths
cd "$TMP"
zip -r "$OUT" .

rm -rf "$TMP"

echo ""
echo "Done! Zip created at: $OUT"
echo ""
echo "Upload to: /home/u168347145/domains/alisadek.online/public_html/wave/"
echo "Then delete the old files first, and extract the new zip."

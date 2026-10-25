# Creates wave-deploy.tar.gz with Linux-compatible forward-slash paths
# Run: powershell -File C:\xampp\htdocs\boss\hostinger\build-zip.ps1

$projectRoot = Split-Path $PSScriptRoot -Parent
$zipPath     = "$projectRoot\hostinger\wave-deploy.tar.gz"
$tmp         = "$projectRoot\hostinger\_tmp_deploy"

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
if (Test-Path $tmp)     { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp | Out-Null

# 1. React build output
Copy-Item "$projectRoot\public\*" $tmp -Recurse -Force

# 2. Root .htaccess + PHP router
Copy-Item "$projectRoot\hostinger\public_html\.htaccess" "$tmp\.htaccess" -Force
Copy-Item "$projectRoot\hostinger\public_html\index.php"  "$tmp\index.php"  -Force

# 3. api/
New-Item -ItemType Directory -Path "$tmp\api" -Force | Out-Null
Copy-Item "$projectRoot\hostinger\public_html\api\.htaccess" "$tmp\api\.htaccess" -Force
Copy-Item "$projectRoot\hostinger\public_html\api\index.php"  "$tmp\api\index.php"  -Force

# 4. backend/
New-Item -ItemType Directory -Path "$tmp\backend" -Force | Out-Null
Copy-Item "$projectRoot\hostinger\public_html\backend\.htaccess" "$tmp\backend\.htaccess" -Force
Copy-Item "$projectRoot\hostinger\public_html\backend\.env"      "$tmp\backend\.env"      -Force
Copy-Item "$projectRoot\backend\app"      "$tmp\backend\app"      -Recurse -Force
Copy-Item "$projectRoot\backend\config"   "$tmp\backend\config"   -Recurse -Force
Copy-Item "$projectRoot\backend\database" "$tmp\backend\database" -Recurse -Force
Copy-Item "$projectRoot\backend\storage"  "$tmp\backend\storage"  -Recurse -Force

# 5. Create tar.gz — Windows tar uses forward-slash paths (Linux-compatible)
Push-Location $tmp
tar -czf $zipPath .
Pop-Location

Remove-Item $tmp -Recurse -Force

Write-Host ""
Write-Host "Done! Archive created at:" -ForegroundColor Green
Write-Host "  $zipPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Delete ALL files in wave/ on Hostinger" -ForegroundColor Yellow
Write-Host "2. Upload wave-deploy.tar.gz and extract it" -ForegroundColor Yellow

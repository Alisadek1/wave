# Hostinger Shared Hosting Deployment

## Directory structure on Hostinger (public_html)

```
public_html/
├── .htaccess          ← routing (from hostinger/public_html/.htaccess)
├── index.html         ← React build output
├── assets/            ← React build output
├── uploads/           ← created manually, must be writable (chmod 755)
│   └── medicines/     ← auto-created by PHP on first upload
├── api/
│   ├── .htaccess      ← from hostinger/public_html/api/.htaccess
│   └── index.php      ← from hostinger/public_html/api/index.php
└── backend/
    ├── .htaccess      ← from hostinger/public_html/backend/.htaccess
    ├── app/
    ├── config/
    ├── database/
    ├── storage/
    └── .env           ← copy hostinger/.env.example, fill in your values
```

---

## Step-by-step deployment

### 1. Build the React frontend (on your local machine)

```bash
cd frontend
set VITE_API_URL=https://wave.alisadek.online && npm run build
```

The build output goes to `public/` in the project root.

### 2. Create the MySQL database on Hostinger

In hPanel → Databases → MySQL Databases:
- Create a new database
- Create a user and assign it to the database (all privileges)
- Note the database name, username, and password

### 3. Upload files via FTP or File Manager

Upload the following to `public_html/`:

| Source (local)                          | Destination (Hostinger public_html/)  |
|-----------------------------------------|---------------------------------------|
| `public/` contents (index.html, assets/)| directly into `public_html/`          |
| `hostinger/public_html/.htaccess`       | `public_html/.htaccess`               |
| `hostinger/public_html/api/.htaccess`   | `public_html/api/.htaccess`           |
| `hostinger/public_html/api/index.php`   | `public_html/api/index.php`           |
| `hostinger/public_html/backend/.htaccess`| `public_html/backend/.htaccess`      |
| `backend/app/`                          | `public_html/backend/app/`            |
| `backend/config/`                       | `public_html/backend/config/`         |
| `backend/database/`                     | `public_html/backend/database/`       |
| `backend/storage/`                      | `public_html/backend/storage/`        |

### 4. Configure the .env file

Copy `hostinger/.env.example` to `public_html/backend/.env` and fill in:
- `DB_HOST=localhost`
- `DB_NAME=` your database name from step 2
- `DB_USER=` your database username
- `DB_PASS=` your database password
- `CORS_ORIGINS=https://wave.alisadek.online`
- `JWT_SECRET=` generate a random 64-char string
- `UPLOAD_DIR=/home/u123456789/public_html/uploads`
  (replace `u123456789` with your actual Hostinger username — shown in hPanel)

### 5. Create the uploads directory

In hPanel File Manager, create `public_html/uploads/` and set its permissions to `755`.

### 6. Import the database

In hPanel → phpMyAdmin:
- Select your database
- Import `backend/database/wave_db.sql`
- Then import `backend/database/migration_wave.sql`
- Then import `backend/database/migration_cash_mgmt.sql`

### 7. Test

Visit `https://wave.alisadek.online` — the login page should load.
Visit `https://wave.alisadek.online/api/health` — should return `{"status":"ok","time":"..."}`.

---

## Troubleshooting

**500 error on /api/**: Check that `public_html/backend/.env` exists and DB credentials are correct.  
**404 on /api/**: Make sure `mod_rewrite` is enabled (it is on Hostinger shared hosting by default).  
**Images not showing**: Verify `UPLOAD_DIR` in `.env` points to the correct absolute path.  
**Login redirects loop**: Make sure `CORS_ORIGINS` in `.env` matches your exact domain.

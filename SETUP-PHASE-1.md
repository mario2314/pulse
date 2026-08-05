# Pulse Backend — Setup Fase 1 (Auth + Workspace)

## 1. Buat project Laravel baru (lokal)
```bash
composer create-project laravel/laravel pulse-backend
cd pulse-backend
```

## 2. Install package yang dibutuhkan
```bash
composer require tymon/jwt-auth
php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider"
php artisan jwt:secret
```

## 3. Copy file-file dari bundle ini ke project kamu
Timpa/tambahkan sesuai path yang sama persis:
- `database/migrations/*` → 3 file migration
- `app/Models/User.php`, `Workspace.php`, `WorkspaceMember.php`
- `app/Http/Controllers/Api/V1/AuthController.php`
- `app/Http/Middleware/EnsureWorkspaceMember.php`, `EnsureAdmin.php`
- `routes/api.php`
- `vercel.json` + `api/index.php` (taruh di root project)

## 4. Daftarkan middleware alias
Di `bootstrap/app.php` (Laravel 11+), tambahkan di dalam `->withMiddleware()`:
```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'ensure.workspace.member' => \App\Http\Middleware\EnsureWorkspaceMember::class,
        'ensure.admin' => \App\Http\Middleware\EnsureAdmin::class,
    ]);
})
```

## 5. Set guard `api` ke JWT
Di `config/auth.php`:
```php
'guards' => [
    'web' => ['driver' => 'session', 'provider' => 'users'],
    'api' => ['driver' => 'jwt', 'provider' => 'users'],
],
```

## 6. Environment variables (`.env` lokal dulu)
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=pulse
DB_USERNAME=root
DB_PASSWORD=

JWT_SECRET=(sudah auto-generate di step 2)
JWT_TTL=60
```

## 7. Migrate & test lokal
```bash
php artisan migrate
php artisan serve
```

Test dengan curl:
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Andi","email":"andi@test.com","password":"password123","password_confirmation":"password123","workspace_name":"Andi Workspace"}'
```
Harus balikin `access_token`.

## 8. Baru setelah lokal jalan → deploy ke Vercel
```bash
npm i -g vercel
vercel login
vercel
```
Di dashboard Vercel, isi environment variables yang sama seperti `.env` (poin 6), plus untuk production nanti ganti `DB_HOST` ke MySQL cloud (PlanetScale/Railway) karena localhost gak bisa diakses dari internet.

## Checklist sebelum lanjut ke Fase 2 (Tasks module)
- [ ] Register → dapat token
- [ ] Login → dapat token
- [ ] `GET /api/v1/me` pakai `Authorization: Bearer <token>` → dapat data user + workspace
- [ ] Deploy ke Vercel sukses, endpoint di atas jalan di URL production

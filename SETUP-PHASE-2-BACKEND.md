# Pulse Backend — Setup Fase 2 (Tasks Module + AI Suggest)

## 1. Copy file-file ini ke project Laravel kamu (yang udah ada dari Fase 1)

| Dari bundle ini | Ke project |
|---|---|
| `database/migrations/*.php` (5 file) | `database/migrations/` |
| `app/Models/Category.php`, `Label.php`, `Task.php`, `AiUsageLog.php` | `app/Models/` |
| `app/Http/Requests/*.php` (3 file) | `app/Http/Requests/` (bikin folder kalau belum ada) |
| `app/Http/Resources/TaskResource.php` | `app/Http/Resources/` (bikin folder kalau belum ada) |
| `app/Services/AiService.php` | `app/Services/` (bikin folder kalau belum ada) |
| `app/Http/Controllers/Api/V1/TaskController.php`, `AiController.php` | `app/Http/Controllers/Api/V1/` |
| `routes/api.php` | **timpa** punya kamu yang lama (sudah termasuk semua route Fase 1 + Fase 2) |

## 2. Tambahkan config AI provider

Buka `config/services.php`, tambahkan entry ini di dalam array `return [...]`:

```php
'ai' => [
    'api_key' => env('AI_API_KEY'),
    'model' => env('AI_MODEL', 'claude-sonnet-4-6'),
],
```

## 3. Tambahkan environment variable

Di `.env`:
```
AI_API_KEY=
AI_MODEL=claude-sonnet-4-6
```

> **Kalau `AI_API_KEY` dikosongin**, fitur AI suggest tetap "jalan" — `AiService` punya fallback deterministik (judul di-capitalize apa adanya, priority default medium, tanpa subtask). Ini sengaja dibuat biar kamu tetap bisa demo end-to-end tanpa API key dulu, baru diisi API key beneran pas mau nunjukin AI-nya "pintar".

Kalau mau AI-nya beneran jalan, isi `AI_API_KEY` dengan API key dari [console.anthropic.com](https://console.anthropic.com).

## 4. Bersihin cache config & migrate

```bash
php artisan config:clear
php artisan migrate
```

Harus muncul 5 migration baru: `categories`, `labels`, `tasks`, `task_labels`, `ai_usage_logs`.

## 5. Test alur Tasks (pakai token dari login Fase 1)

Semua endpoint Tasks butuh 2 header: `Authorization: Bearer <token>` DAN `X-Workspace-Id: <id>` (workspace id kamu bisa lihat dari response `/me`).

**Buat kategori dulu manual lewat Tinker (biar ada data buat dites)**
```bash
php artisan tinker
>>> App\Models\Category::create(['workspace_id' => 1, 'name' => 'Client Work', 'color' => '#6366F1']);
>>> exit
```

**Test create task (PowerShell):**
```powershell
$token = "PASTE_TOKEN"
$headers = @{ Authorization = "Bearer $token"; "X-Workspace-Id" = "1" }
$body = '{"title":"Prepare client deck","priority":"high"}'
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/tasks" -Method Post -ContentType "application/json" -Headers $headers -Body $body | ConvertTo-Json -Depth 5
```

**Test list tasks:**
```powershell
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/tasks" -Method Get -Headers $headers | ConvertTo-Json -Depth 5
```

**Test AI suggest:**
```powershell
$aiBody = '{"prompt":"prep client deck for friday meeting"}'
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/ai/tasks/suggest" -Method Post -ContentType "application/json" -Headers $headers -Body $aiBody | ConvertTo-Json -Depth 5
```
Kalau `AI_API_KEY` belum diisi, kamu tetap dapat response JSON (fallback), cuma isinya sederhana banget. Kalau udah diisi API key asli, coba lagi — hasilnya bakal ada `category_suggestion`, `priority`, `due_date_suggestion`, dan `subtasks` yang lebih masuk akal.

## Checklist sebelum lanjut ke frontend Tasks UI
- [ ] Migration 5 tabel baru sukses
- [ ] Create task via API berhasil, muncul di list
- [ ] Update task (ubah status) berhasil
- [ ] Delete task berhasil
- [ ] AI suggest endpoint balikin response (minimal fallback-nya, syukur kalau udah pakai API key asli)
- [ ] Coba akses task milik workspace lain (ganti `X-Workspace-Id` ke ID yang bukan milik kamu) → harus dapat 403 dari `EnsureWorkspaceMember`, bukan malah bisa lihat data workspace orang

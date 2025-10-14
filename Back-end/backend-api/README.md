# Absenin Backend API (Laravel 10)

This is a lightweight Laravel API connected to Supabase (Postgres).

## Setup

1. PHP and Composer installed. (PHP >= 8.1 for Laravel 10)
2. Create `.env` from `.env.example` (already created) and set Supabase env:

```
DB_CONNECTION=pgsql
DB_HOST=<your-supabase-db-host>
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=<your-db-password>
DB_SSLMODE=require

SUPABASE_URL=<your-supabase-url>
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<optional-service-role>
```

Supabase DB host and credentials can be found in Project Settings > Database.

3. Install dependencies and run migrations:

```
composer install
php artisan migrate
php artisan serve
```

API base: http://127.0.0.1:8000/api

## Endpoints

- GET /api/assignments?user_id=...  (list)
- POST /api/assignments  (create)
	- body: { user_id, title, description?, image_url? }

- GET /api/attendances?user_id=... (list)
- POST /api/attendances/check-in  (check-in)
	- body: { user_id, date, time, latitude?, longitude?, distance_m? }
- POST /api/attendances/check-out (check-out)
	- body: { user_id, date, time }

- GET /api/leaves?user_id=... (list)
- POST /api/leaves (create)
	- body: { user_id, type, start_date, end_date, reason? }

## Notes
- UUID primary keys are used; generated in controllers.
- Add authentication (Sanctum/JWT) for production.
- For file uploads, use Laravel Storage or directly upload to Supabase Storage and store public URL in `image_url`.

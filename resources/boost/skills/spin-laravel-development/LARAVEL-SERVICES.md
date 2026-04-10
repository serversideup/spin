# Laravel Services

Docker Compose service configurations for Laravel with Spin.

## Table of contents

- [Connection pattern](#connection-pattern)
- [MySQL](#mysql)
- [PostgreSQL](#postgresql)
- [MariaDB](#mariadb)
- [SQLite](#sqlite)
- [Redis](#redis)
- [Laravel Queues](#laravel-queues)
- [Laravel Horizon](#laravel-horizon)
- [Laravel Reverb](#laravel-reverb)
- [Laravel Task Scheduler](#laravel-task-scheduler)
- [Laravel Octane](#laravel-octane)
- [Vite](#vite)
- [Mailpit](#mailpit)
- [Meilisearch](#meilisearch)

---

## Connection pattern

In Docker, services connect via **container name as hostname**:

```env
DB_HOST=mysql        # NOT localhost, NOT 127.0.0.1
REDIS_HOST=redis
MAIL_HOST=mailpit
```

Avoid special characters in passwords — use long (20+) alphanumeric strings.

Database credentials are only created on **first container initialization**. To reset, remove the volume and re-run `spin up`.

---

## MySQL

`.env` configuration:

```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laraveluser
DB_PASSWORD=laravelpassword
```

Exposed on `localhost:3306` in development for GUI database clients.

---

## PostgreSQL

`.env` configuration:

```env
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laraveluser
DB_PASSWORD=laravelpassword
```

Exposed on `localhost:5432` in development.

---

## MariaDB

Drop-in replacement for MySQL. Uses the same `DB_CONNECTION=mysql`.

```env
DB_CONNECTION=mysql
DB_HOST=mariadb
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laraveluser
DB_PASSWORD=laravelpassword
```

---

## SQLite

Spin stores the SQLite database in `.infrastructure/volume_data/sqlite/` to allow volume mounting without overwriting Laravel files.

```env
DB_CONNECTION=sqlite
DB_DATABASE=/var/www/html/.infrastructure/volume_data/sqlite/database.sqlite
```

The path uses the **container path** (`/var/www/html/`), not the host path.

---

## Redis

```env
REDIS_HOST=redis
REDIS_PASSWORD=redispassword
```

Installing Laravel Horizon automatically includes Redis.

---

## Laravel Queues

Dedicated queue worker service. Default command:

```bash
php artisan queue:work --tries=3
```

Runs as a separate Docker service alongside the main PHP service.

---

## Laravel Horizon

Dashboard and queue manager for Redis queues. Default command:

```bash
php artisan horizon
```

Access the dashboard at `http://<app-url>/horizon`.

Automatically installs Redis when selected.

---

## Laravel Reverb

WebSocket server for real-time features. Default command:

```bash
php artisan reverb:start
```

Development URL: `wss://reverb.dev.test`

Production requires a **separate DNS entry** from your app domain. Example: if your app is at `app.example.com`, set up `socket.example.com` pointing to the same server, and configure:

```env
REVERB_HOST=socket.example.com
```

---

## Laravel Task Scheduler

Runs scheduled tasks every minute. Default command:

```bash
php artisan schedule:work
```

---

## Laravel Octane

High-performance application server using FrankenPHP. Default command:

```bash
php artisan octane:start --server=frankenphp --port=8080
```

Considerations when using Octane:
- The application stays loaded in memory between requests
- Avoid storing state in global variables
- Singletons persist between requests
- Test thoroughly — persistent processes can expose hidden bugs

---

## Vite

Development asset server with HMR over HTTPS.

Development URL: `https://vite.dev.test`

Default `vite.config.js` for Spin:

```js
import fs from 'fs';
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    server: {
        host: '0.0.0.0',
        hmr: {
            host: 'vite.dev.test',
            clientPort: 443,
        },
        https: {
            key: fs.readFileSync('/usr/src/app/.infrastructure/conf/traefik/dev/certificates/local-dev-key.pem'),
            cert: fs.readFileSync('/usr/src/app/.infrastructure/conf/traefik/dev/certificates/local-dev.pem'),
        },
    },
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
```

Run with: `spin run node yarn dev`

For production HTTPS asset loading, add to `AppServiceProvider::register()`:

```php
if ($this->app->environment('production') || $this->app->environment('dev')) {
    URL::forceScheme('https');
}
```

---

## Mailpit

Local email testing (development only).

URL: `https://mailpit.dev.test`

```env
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=
```

The Mailpit container may take ~15 seconds to start. If you see a 404 immediately after `spin up`, wait and retry.

---

## Meilisearch

Full-text search engine. Integrates with Laravel Scout.

Development UI: `https://meilisearch.dev.test`

```env
SCOUT_DRIVER=meilisearch
MEILISEARCH_HOST=http://meilisearch:7700
MEILISEARCH_KEY=developmentkey1234567890
```

For production, set a secure key (20+ alphanumeric characters). Avoid running the Meilisearch UI in production unless properly secured.

For additional service configurations and updates, see <https://getspin.pro/docs>.

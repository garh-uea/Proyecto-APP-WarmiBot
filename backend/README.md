# Backend de WarmiBot

API REST construida con FastAPI, SQLAlchemy y SQLite para desarrollo. Incluye
autenticación JWT, refresh tokens revocables, roles, conversaciones, caché,
trabajos asíncronos y endpoints de diagnóstico controlados por entorno.

## Inicio rápido

```powershell
Set-Location C:\WarmiBot\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
python -m uvicorn app.main:app --host 0.0.0.0 --port 800 --env-file .env
```

- Salud: `http://127.0.0.1:800/health`
- Swagger: `http://127.0.0.1:800/docs`
- OpenAPI: `http://127.0.0.1:800/openapi.json`

## Variables

| Variable | Uso | Valor de desarrollo |
|---|---|---|
| `APP_ENV` | Activa o restringe diagnósticos | `development` |
| `DATABASE_URL` | Conexión SQLAlchemy | `sqlite:///./warmibot_backend.db` |
| `JWT_SECRET` | Firma de tokens | secreto local de 32+ caracteres |
| `ACCESS_TOKEN_MINUTES` | Vigencia del access token | `15` |
| `REFRESH_TOKEN_DAYS` | Vigencia del refresh token | `7` |
| `CACHE_TTL_SECONDS` | Tiempo de caché | `60` |
| `ALLOWED_ORIGINS` | Orígenes CORS explícitos | localhost |
| `BOOTSTRAP_ADMIN_EMAIL` | Administrador inicial opcional | editable |
| `BOOTSTRAP_ADMIN_PASSWORD` | Contraseña inicial opcional | cambiar |

No publique `.env`. En producción use un gestor de secretos y HTTPS. La
aplicación rechaza `APP_ENV=production` cuando `JWT_SECRET` tiene menos de 32
caracteres o conserva un valor inseguro conocido.

## Endpoints principales

- `GET /health`: disponibilidad sin autenticación.
- `POST /api/v1/auth/login`: access token y refresh token.
- `POST /api/v1/auth/refresh`: renueva credenciales válidas.
- `/api/v1/conversations`: operaciones autenticadas de conversación.
- `/api/v1/jobs`: tareas asíncronas.
- `/api/v1/diagnostics`: métricas disponibles fuera de producción.

Importe `postman/WarmiBot_Backend.postman_collection.json` para pruebas
manuales. Su variable `baseUrl` apunta a `http://127.0.0.1:800`.

## Pruebas

```powershell
.\.venv\Scripts\python.exe -m pytest -q -p no:cacheprovider
```

La suite cubre salud, OpenAPI, autenticación, autorización por rol, revocación,
conversaciones, caché, carga eficiente y seguridad del secreto de producción.

## Benchmark

Con el servidor activo:

```powershell
.\.venv\Scripts\python.exe scripts\benchmark.py --base-url http://127.0.0.1:800
```

Los resultados dependen del equipo y no deben presentarse como equivalentes a
una prueba de carga de producción.

## Despliegue

Para producción:

1. Cambie `APP_ENV=production`.
2. Use PostgreSQL u otro motor administrado mediante `DATABASE_URL`.
3. Genere `JWT_SECRET` aleatorio, mínimo 32 caracteres.
4. Desactive el administrador de arranque o inyecte credenciales seguras.
5. Restrinja `ALLOWED_ORIGINS` al dominio real.
6. Publique detrás de un proxy HTTPS.
7. Ejecute migraciones controladas antes de escalar réplicas.

El endpoint móvil de desarrollo usa `10.0.2.2:800` solo porque Android Emulator
traduce esa dirección al host. No es una dirección de producción.

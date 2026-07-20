# Backend optimizado de WarmiBot

API REST independiente para complementar la aplicación Flutter sin alterar sus
funciones actuales. Incluye autenticación JWT, autorización por roles y
propiedad, caché cache-aside, corrección de N+1 y una cola asíncrona.

## Arquitectura implementada

- **FastAPI**: endpoints y documentación automática OpenAPI/Swagger.
- **SQLAlchemy 2**: usuarios, conversaciones, mensajes, refresh tokens y tareas.
- **SQLite**: base local para el taller; `DATABASE_URL` permite migrar después.
- **JWT**: access token de 15 minutos y refresh token de 7 días con rotación.
- **scrypt**: hash con sal aleatoria para contraseñas.
- **Cache-aside**: detalle de conversación, TTL de 60 segundos e invalidación
  al crear mensajes o eliminar la conversación.
- **Eager loading (`selectinload`)**: lista conversaciones y mensajes en dos
  consultas, en lugar de una consulta inicial más una por conversación.
- **Worker asíncrono**: `asyncio.Queue` recibe trabajos y ejecuta el resumen en
  un hilo separado para no bloquear la respuesta HTTP.

## Instalación

Desde `C:\WarmiBot\backend`:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn app.main:app --reload --env-file .env
```

Abrir:

- Swagger: `http://127.0.0.1:8000/docs`
- Estado: `http://127.0.0.1:8000/health`

Antes de una entrega real se debe cambiar `JWT_SECRET` y la contraseña inicial
del administrador. El archivo `.env` no debe incorporarse al repositorio.

## Flujo de demostración

1. `POST /api/v1/auth/login` usando formulario:
   `username=admin@warmibot.com`, `password=ChangeMe123!`.
2. Autorizar Swagger con el access token.
3. `POST /api/v1/diagnostics/seed` para crear datos de prueba.
4. `GET /api/v1/diagnostics/n-plus-one` para ver consultas y tiempo.
5. `GET /api/v1/conversations/{id}` dos veces: encabezados `MISS` y `HIT`.
6. Crear un mensaje y volver a consultar: debe regresar `MISS` por invalidación.
7. `POST /api/v1/jobs/conversation-summary/{id}` devuelve `202 Accepted`.
8. Consultar `GET /api/v1/jobs/{job_id}` hasta obtener `completed`.
9. Renovar con `POST /api/v1/auth/refresh`; reutilizar el token anterior produce
   `401 Unauthorized` por rotación.

## Pruebas y comparación

```powershell
pytest
python scripts\benchmark.py
```

El benchmark crea 20 conversaciones. El comportamiento esperado es:

| Operación | Antes | Después |
|---|---:|---:|
| Conversaciones con mensajes | 21 consultas | 2 consultas |
| Segunda lectura de detalle | Consulta SQL | Respuesta desde caché (`HIT`) |
| Resumen de conversación | Bloqueo potencial | `202` y worker independiente |
| Validación de usuario/rol | Riesgo de consultas repetidas | 1 consulta compartida |

Los milisegundos dependen del computador; deben tomarse de la ejecución real de
`benchmark.py`. La comparación principal utiliza el número de consultas, que es
reproducible y no depende de la velocidad del equipo.

La ejecución de referencia del 19 de julio de 2026 se encuentra en
`docs/evidencia_benchmark.json`: 21 consultas y 28,124 ms antes, frente a 2
consultas y 5,78 ms después. La segunda lectura cacheada respondió `HIT`.

## Justificación de carga

Se usa **eager loading** para `Conversation.messages` porque la pantalla de
historial necesita mostrar los mensajes de cada conversación. `selectinload`
evita el producto cartesiano de un `JOIN` grande y mantiene dos consultas
predecibles. Las relaciones que no se necesitan en esa operación, como tokens
de renovación, conservan carga diferida.

## Limitación conocida

La caché y la cola son locales al proceso, apropiadas para el taller y una sola
instancia. En producción con varias réplicas se reemplazarían por Redis y un
worker como Celery, RQ o Dramatiq sin cambiar los contratos HTTP.

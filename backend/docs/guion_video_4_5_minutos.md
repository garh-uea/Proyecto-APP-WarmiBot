# Guion grupal exacto para el video de WarmiBot

**Duración objetivo:** 4 minutos 30 segundos.
**Integrantes:** 3.
**Formato recomendado:** grabación horizontal 1080p, voz clara y una sola captura
de pantalla compartida. No mostrar contraseñas reales ni el contenido de `.env`.

## Material que debe estar preparado

1. Una diapositiva inicial: nombre del proyecto, integrantes y objetivo.
2. Swagger abierto en `http://127.0.0.1:800/docs`.
3. Postman con `WarmiBot_Backend.postman_collection.json` importado.
4. Terminal con `pytest` ejecutado y otra con `python scripts\benchmark.py`.
5. Editor abierto en estos archivos:
   - `app/routers/auth.py`
   - `app/cache.py`
   - `app/routers/conversations.py`
   - `app/services/conversations.py`
   - `app/worker.py`
6. No incluir la instalación de paquetes en el video; debe estar lista antes.

## Integrante 1 — Presentación, diagnóstico y autenticación (0:00–1:25)

### 0:00–0:20 — Diapositiva inicial

**En pantalla:** título del proyecto e integrantes.

**Texto exacto:**

> Buenos días. Somos el grupo responsable del proyecto WarmiBot, un asistente
> virtual móvil desarrollado en Flutter. En esta actividad incorporamos un
> backend seguro y aplicamos técnicas de optimización: caché, corrección de una
> consulta N más uno, carga anticipada, procesamiento asíncrono y mejora de la
> autenticación.

### 0:20–0:45 — Arquitectura y diagnóstico

**En pantalla:** árbol de `backend` y luego `README.md` en la sección Arquitectura.

**Texto exacto:**

> El diagnóstico inicial determinó que la aplicación trabajaba solamente con
> servicios y una base SQLite local, por lo que no existía un backend que
> centralizara usuarios y conversaciones. Implementamos una API con FastAPI,
> SQLAlchemy y SQLite. La operación costosa seleccionada fue listar
> conversaciones junto con sus mensajes, porque una implementación ingenua
> realiza una consulta adicional por cada conversación.

### 0:45–1:25 — Autenticación

**En pantalla:** `auth.py`, Swagger `POST /auth/login`, después `GET /auth/me`.

**Texto exacto:**

> La autenticación protege las contraseñas con scrypt y utiliza dos tokens JWT.
> El access token dura quince minutos y el refresh token dura siete días. El
> refresh token se almacena como hash y se rota en cada renovación, por lo que
> un token anterior no puede reutilizarse. El JWT contiene únicamente el
> identificador, rol, tipo, versión y expiración. La dependencia que valida al
> usuario ejecuta una sola consulta, y la comprobación de roles reutiliza ese
> mismo usuario. Un token inválido produce 401 y un usuario autenticado sin rol
> suficiente recibe 403.

## Integrante 2 — N+1, eager loading y caché (1:25–3:00)

### 1:25–2:05 — Consulta N+1

**En pantalla:** `services/conversations.py`; resaltar `_measure` y
`compare_loading_strategies`.

**Texto exacto:**

> Para demostrar el problema N más uno conservamos una medición diagnóstica que
> carga las conversaciones y después accede a los mensajes de cada una. Con
> veinte conversaciones, este enfoque genera veintiuna consultas: una consulta
> principal y veinte consultas adicionales. La versión optimizada utiliza
> selectinload y obtiene toda la relación en dos consultas. Elegimos eager
> loading porque el historial necesita los mensajes inmediatamente. Selectinload
> evita tanto las consultas repetidas como un join demasiado grande.

### 2:05–2:35 — Resultado antes y después

**En pantalla:** salida real de `python scripts\benchmark.py`.

**Texto exacto:**

> En la prueba reproducible, el comportamiento anterior realizó veintiuna
> consultas y el comportamiento optimizado realizó dos. Esto representa una
> reducción del noventa coma cuarenta y ocho por ciento. En nuestra ejecución de
> referencia, el tiempo pasó de veintiocho coma ciento veinticuatro milisegundos
> a cinco coma setenta y ocho milisegundos. Estos tiempos pueden variar según el
> equipo, pero la reducción de consultas es estable y verificable.

### 2:35–3:00 — Cache-aside

**En pantalla:** `cache.py`, luego ejecutar dos veces el detalle en Postman y
mostrar los encabezados `X-Cache: MISS` y `X-Cache: HIT`.

**Texto exacto:**

> También implementamos cache-aside en el detalle de una conversación, con un
> tiempo de vida de sesenta segundos. La primera solicitud no encuentra el dato,
> consulta la base y guarda el resultado; por eso responde MISS. La segunda
> solicitud responde HIT desde caché. Al agregar un mensaje o eliminar la
> conversación se ejecuta una invalidación explícita, evitando datos obsoletos.

## Integrante 3 — Worker, pruebas, dificultades y cierre (3:00–4:30)

### 3:00–3:35 — Tarea asíncrona

**En pantalla:** `worker.py`; en Postman ejecutar crear resumen y consultar tarea.

**Texto exacto:**

> Para el procesamiento asíncrono implementamos una cola con asyncio y un worker.
> Cuando solicitamos un resumen, la API crea un trabajo persistido y responde de
> inmediato con el código 202 Accepted. El worker procesa la conversación fuera
> del ciclo de la solicitud, calcula la cantidad de mensajes, palabras y términos
> frecuentes, y actualiza el estado desde queued hasta completed. Así evitamos
> bloquear la respuesta HTTP con una operación de mayor duración.

### 3:35–4:05 — Evidencias de prueba

**En pantalla:** colección de Postman y terminal con `pytest` aprobado.

**Texto exacto:**

> Verificamos el registro, inicio de sesión, renovación y rotación de tokens,
> token ausente, rol insuficiente y acceso a recursos propios. También probamos
> la reducción de consultas, el ciclo MISS-HIT de caché, su invalidación y la
> finalización del worker. La colección de Postman conserva las solicitudes y
> pruebas, y Swagger documenta todos los contratos de la API.

### 4:05–4:30 — Dificultades y conclusión

**En pantalla:** diapositiva final con tabla Antes/Después.

**Texto exacto:**

> La principal dificultad fue que el proyecto móvil no tenía backend; por ello
> se creó un módulo independiente sin afectar la aplicación Flutter. Otra
> decisión fue usar una caché y cola locales para facilitar la demostración. En
> producción se reemplazarían por Redis y un worker distribuido. Como resultado,
> WarmiBot dispone ahora de autenticación más segura, consultas controladas,
> respuestas reutilizables y procesamiento asíncrono. Gracias.

## Diapositiva final: comparación

| Aspecto | Antes | Después |
|---|---|---|
| Conversaciones y mensajes | 21 consultas con 20 conversaciones | 2 consultas |
| Segunda lectura | Nueva consulta a base de datos | Caché `HIT` |
| Modificación | Riesgo de dato cacheado obsoleto | Invalidación explícita |
| Resumen | Procesamiento dentro de la solicitud | `202 Accepted` y worker |
| Usuario y rol | Posibles consultas repetidas | Una consulta reutilizada |
| Refresh token | Sin renovación controlada | Rotación y revocación |

## Ensayo

- Integrante 1: máximo 85 segundos.
- Integrante 2: máximo 95 segundos.
- Integrante 3: máximo 90 segundos.
- Ensayar una vez con cronómetro. Si supera 4:50, recortar las pausas y no el
  contenido técnico. Si dura menos de 4:00, mostrar con más calma los encabezados
  de caché y el resultado del worker.

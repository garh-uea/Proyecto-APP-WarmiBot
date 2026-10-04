# WarmiBot - Asistente Virtual Amazónico

Aplicación móvil multiplataforma desarrollada con Flutter y un backend propio en
FastAPI. WarmiBot integra conversación por texto y voz, clima, noticias,
traducción, recordatorios, alarmas y una API con autenticación JWT, roles,
persistencia y diagnósticos.

Proyecto integrador de la Universidad Estatal Amazónica, Tena, Napo, Ecuador.

## Estado verificado

- Flutter 3.44.2 y Dart 3.12.2.
- Android SDK 36.1; ejecución comprobada en Pixel_4 con Android 13 (API 33).
- FastAPI 0.139.2 y Uvicorn 0.51.0 sobre Python 3.14.4.
- `flutter doctor -v`: sin hallazgos.
- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub`: 21 pruebas aprobadas.
- `pytest -q -p no:cacheprovider`: 11 pruebas aprobadas.
- APK de depuración: `build/app/outputs/flutter-apk/app-debug.apk`.
- Comunicación móvil-API verificada mediante `GET /health` con HTTP 200.

Las evidencias generadas el 16 de agosto de 2026 se encuentran en
`docs/evidencias/`.

## Elección de Flutter

Flutter permite mantener una sola base de código para Android, iOS, web y
escritorio, ofrece recarga en caliente y produce una interfaz consistente. Dart
aporta tipado estático, análisis automático y pruebas integradas. Para este
proyecto se prioriza Android porque el equipo dispone de Android Studio, SDK,
JDK y un AVD instalado; la misma capa de dominio puede reutilizarse en otros
destinos.

## Arquitectura

```text
lib/
|-- core/                  # constantes, tema y utilidades
|-- domain/
|   |-- models/            # entidades de conversación y recordatorio
|   `-- services/          # voz, clima, noticias, API, alarmas y traducción
|-- infrastructure/        # repositorios y persistencia local
`-- presentation/
    |-- bloc/              # eventos, estado y orquestación
    |-- pages/             # pantallas principales
    `-- widgets/           # componentes reutilizables

backend/
|-- app/
|   |-- routers/           # autenticación, conversaciones, trabajos y diagnóstico
|   |-- services/          # reglas de negocio
|   |-- main.py            # aplicación FastAPI y /health
|   |-- security.py        # scrypt, JWT y refresh token
|   `-- database.py        # SQLAlchemy y sesiones
|-- tests/                 # pruebas automatizadas
|-- postman/               # colección de pruebas manuales
`-- scripts/               # benchmark reproducible
```

El flujo de integración es:

```text
WarmiBot en Pixel_4
        |
        | HTTP de depuración: http://10.0.2.2:8000/health
        v
FastAPI en el equipo anfitrión (0.0.0.0:800)
        |
        `-- respuesta JSON: {"status":"ok","environment":"development"}
```

`10.0.2.2` es la dirección especial con la que el emulador Android accede al
`localhost` del equipo anfitrión. No se debe usar `127.0.0.1` desde el emulador,
porque allí representa al propio dispositivo virtual.

## Navegación, sesión y enlaces profundos

WarmiBot usa navegación declarativa con `go_router`. Las rutas públicas son
`/login`, `/registro` y `/estado-api`; Inicio, conversaciones, recordatorios,
perfil, trabajos y diagnóstico requieren sesión. Los tokens JWT se guardan con
almacenamiento seguro del sistema operativo.

Un `401` intenta renovar el access token; si la renovación falla, limpia la
sesión y redirige a `/login`. Un `403` no cierra la sesión: muestra
`/acceso-restringido`, porque la identidad es válida pero no tiene el rol
necesario.

En Android o iOS se puede abrir una ruta mediante el esquema registrado, por
ejemplo `warmibot://app/conversaciones/1`. En Flutter web se conserva el mismo
mapa mediante rutas URL. Si un enlace protegido llega sin sesión, la aplicación
recuerda el destino en `from` y lo abre después de autenticar al usuario.

## Requisitos

1. Windows 11, macOS o Linux.
2. Flutter 3.44.2 o una versión estable compatible con Dart 3.12.
3. Android Studio con Android SDK, Platform Tools y Emulator.
4. JDK 21 para la cadena Android de este entorno.
5. Visual Studio Code con las extensiones `Dart-Code.dart-code` y
   `Dart-Code.flutter`.
6. Python 3.12 o superior; el entorno verificado usa Python 3.14.4.
7. Git.

Visual Studio con C++ no es necesario porque WarmiBot se ejecuta en Android; el
destino Windows Desktop está deshabilitado en este equipo para que el diagnóstico
móvil no reporte una herramienta fuera del alcance.

## 1. Preparar Flutter

En Windows, agregue `C:\flutter\bin` al inicio de la variable de usuario `PATH`
y reinicie VS Code. Verifique:

```powershell
flutter --version
dart --version
flutter doctor -v
flutter doctor --android-licenses
```

El diagnóstico esperado debe terminar con `No issues found!`.

## 2. Configurar las variables móviles

La configuración móvil se entrega mediante `--dart-define`; `.env` ya no se
empaqueta dentro del APK. Para Pixel_4 utilice:

```powershell
flutter run -d emulator-5554 --debug `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Para un teléfono físico conectado por USB, active **Depuración por USB**, acepte
la autorización del equipo y compruebe `adb devices -l` y `flutter devices`.
Inicie el backend en `127.0.0.1:8000` y use el puente local de ADB:

```powershell
adb reverse tcp:8000 tcp:8000
flutter run -d <ID_DE_ADB> --debug `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

La excepción HTTP para `127.0.0.1` existe únicamente en la variante debug.
Si se prefiere la red Wi-Fi, use la IPv4 del equipo y autorice explícitamente
ese host en la configuración de depuración. Nunca suba claves al repositorio
ni las declare como recursos de Flutter.

## 3. Preparar y ejecutar FastAPI

Desde `C:\WarmiBot`:

```powershell
python -m venv backend\.venv
backend\.venv\Scripts\Activate.ps1
python -m pip install -r backend\requirements.txt
Copy-Item backend\.env.example backend\.env
Set-Location backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --env-file .env
```

En otra terminal compruebe:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

Respuesta esperada:

```json
{"status":"ok","environment":"development"}
```

Swagger queda disponible en `http://127.0.0.1:8000/docs`. Consulte
`backend/README.md` para autenticación, seguridad, pruebas y producción.

## 4. Preparar Flutter y Pixel_4

```powershell
Set-Location C:\WarmiBot
flutter pub get
flutter emulators
flutter emulators --launch Pixel_4
flutter devices
```

El AVD verificado corresponde a Pixel 4, Android 13, API 33. En este equipo
reserva 2 GB de RAM y cuatro núcleos. Cierre programas pesados durante la
exposición; si el equipo no dispone de suficiente memoria, utilice un teléfono
Android por USB.

## 5. Ejecutar y demostrar recarga en caliente

Mantenga el backend activo y ejecute:

```powershell
flutter run -d emulator-5554 --debug `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

La parte superior de WarmiBot debe mostrar `API conectada` en color verde. Si el
backend se inició después de la aplicación, toque el indicador para reintentar.

Para demostrar hot reload:

1. Mantenga `flutter run` activo.
2. Realice un cambio visual reversible.
3. Presione `r` en la terminal.
4. Muestre el mensaje `Reloaded ... libraries` sin reiniciar la aplicación.

En la verificación auténtica se recargaron tres bibliotecas y se mantuvo el
estado de la aplicación.

## Seguridad del tráfico local

- La variante principal tiene `android:usesCleartextTraffic="false"`.
- Solo el manifiesto `debug` activa tráfico HTTP.
- `network_security_config.xml` permite `10.0.2.2` para el emulador y
  `127.0.0.1` para el puente USB de un teléfono físico, solo en debug.
- Las compilaciones release no heredan esta excepción de desarrollo.
- En producción se debe usar HTTPS y un secreto JWT aleatorio de 32 caracteres
  o más.
- El backend impide iniciar en `APP_ENV=production` si `JWT_SECRET` es corto o
  conserva un valor de ejemplo.
- Dio es la única instancia HTTP de producción. Sus tiempos de conexión, envío
  y recepción son 5, 8 y 8 segundos.
- Los interceptores se registran en este orden: autenticación, renovación
  automática, reintento idempotente y registro seguro solo en desarrollo.
- El interceptor de autenticación lee el access token de Secure Storage. Ante
  un 401, el siguiente interceptor rota el refresh token, marca la solicitud y
  la reenvía una sola vez para impedir bucles.
- Los POST solo se reintentan cuando están marcados como idempotentes y llevan
  un `client_id`; las demás creaciones no se repiten automáticamente.
- Una compilación release o un ambiente `production` rechaza una URL base HTTP.

## Capacidades del dispositivo

WarmiBot usa micrófono para comandos de voz y notificaciones locales para
recordatorios y temporizadores. Ambas capacidades son opcionales. El permiso
se consulta en el momento de uso con una explicación previa; si se deniega el
micrófono, se puede escribir, y si se deniega la notificación, el recordatorio
se guarda en SQLite y continúa su sincronización. Una denegación permanente
ofrece abrir los Ajustes de la aplicación. Android declara solo
`RECORD_AUDIO` y `POST_NOTIFICATIONS` para estas funciones; iOS contiene las
cadenas `NSMicrophoneUsageDescription` y `NSSpeechRecognitionUsageDescription`.

El guion, el informe breve y las capturas tomadas del teléfono físico ALT LX2
están en `docs/Guion_Informe_Capacidades_Nativas_WarmiBot.docx` y
`docs/evidencias/capacidades_dispositivo/`.

## Pruebas y calidad

Aplicación Flutter:

```powershell
flutter analyze --no-pub
flutter test --no-pub -r expanded
flutter build apk --debug --no-pub
```

Backend:

```powershell
Set-Location backend
.\.venv\Scripts\python.exe -m pytest -q -p no:cacheprovider
```

La opción `-p no:cacheprovider` evita que pytest intente reutilizar un caché de
otra sesión; no desactiva ninguna prueba.

## Configuración de VS Code

Extensiones verificadas:

- Dart `3.140.0`.
- Flutter `3.140.0`.

Abra `C:\WarmiBot` como carpeta raíz. En la barra inferior seleccione
`emulator-5554` y use `Run > Start Debugging`. Si VS Code continúa apuntando a
un SDK anterior después de modificar `PATH`, cierre todas sus ventanas y vuelva
a abrirlo.

## Solución de problemas

### La app muestra “API sin conexión”

1. Confirme que Uvicorn escucha en `0.0.0.0:8000`.
2. Abra `http://127.0.0.1:8000/health` en el equipo.
3. Verifique `API_BASE_URL=http://10.0.2.2:8000`.
4. Toque el indicador de la app para reintentar.
5. Consulte el firewall únicamente si el endpoint local funciona pero el
   emulador no registra ninguna solicitud.

### Flutter usa otro SDK

Ejecute `Get-Command flutter -All` y asegúrese de que `C:\flutter\bin` aparezca
primero. Elimine del `PATH` referencias antiguas, no las carpetas del SDK hasta
haber confirmado que ya no se usan.

### Pixel_4 consume demasiada memoria

No ejecute simultáneamente emuladores adicionales. Cierre navegadores y Gradle
cuando termine. Para una exposición más estable, un teléfono físico mediante
ADB consume menos memoria del equipo.

### Advertencia futura de Built-in Kotlin

Flutter 3.44 avisa que futuras versiones dejarán de aceptar el complemento
Kotlin tradicional. La compilación actual es correcta. Antes de actualizar
Flutter, verifique que `flutter_tts`, `share_plus` y `speech_to_text` soporten
Built-in Kotlin y realice la migración en una rama separada.

## Evidencias y exposición

- Informe Word: `docs/Informe_Entorno_Multiplataforma_WarmiBot.docx`.
- Captura auténtica Pixel_4/API: `docs/evidencias/warmibot_pixel4_backend_retry.png`.
- Diagnóstico: `docs/evidencias/flutter_doctor.txt`.
- Pruebas: `docs/evidencias/flutter_test.txt` y
  `docs/evidencias/backend_pytest.txt`.
- Versiones: `docs/evidencias/versiones_entorno.txt`.
- Guía para tres integrantes: `docs/GUIA_EVIDENCIAS_TRES_INTEGRANTES.md`.

Cada integrante debe ejecutar y capturar su propio entorno. Las guías visuales
del informe son plantillas diferenciadas y no sustituyen evidencia auténtica de
otra computadora.

## Licencia y autoría

Uso académico. Complete los nombres del equipo, asignatura, docente y fecha de
entrega en el informe antes de presentarlo.

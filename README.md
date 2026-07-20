# 🌿 WarmiBot — Asistente Virtual Amazónico
### Flutter 3.44 · Dart 3.x · Universidad Estatal Amazónica · Tena, Napo, Ecuador

---

## 📁 Estructura del Proyecto

```
warmibot/
├── .env                              ← API Keys (NO subir a GitHub)
├── pubspec.yaml                      ← Dependencias
├── lib/
│   ├── main.dart                     ← Punto de entrada
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart    ← Idiomas, contactos, umbrales
│   │   │   └── commands.dart         ← Comandos + acciones rápidas
│   │   ├── theme/
│   │   │   └── app_theme.dart        ← Paleta amazónica, tipografía
│   │   └── utils/
│   │       └── command_parser.dart   ← Normalizar, detectar, evalMath
│   ├── domain/
│   │   ├── models/
│   │   │   ├── chat_message.dart     ← Modelo de mensaje
│   │   │   └── reminder.dart        ← Modelo de recordatorio/alarma
│   │   └── services/
│   │       ├── tts_service.dart      ← Text-to-Speech (flutter_tts)
│   │       ├── stt_service.dart      ← Speech-to-Text (speech_to_text)
│   │       ├── weather_service.dart  ← Clima (OpenWeatherMap)
│   │       ├── search_service.dart   ← Wikipedia + DuckDuckGo
│   │       ├── translation_service.dart ← Google Translate HTTP
│   │       ├── alarm_service.dart    ← Alarmas + notificaciones push
│   │       └── news_service.dart     ← Noticias RSS (BBC Mundo)
│   ├── infrastructure/
│   │   └── repositories/
│   │       └── reminders_repository.dart ← SQLite (sqflite)
│   └── presentation/
│       ├── bloc/
│       │   ├── assistant_bloc.dart   ← Cerebro principal (lógica)
│       │   ├── assistant_event.dart  ← Eventos BLoC
│       │   └── assistant_state.dart  ← Estados BLoC
│       ├── pages/
│       │   ├── home_page.dart        ← Pantalla principal
│       │   ├── conversations_page.dart ← Historial de chat
│       │   ├── reminders_page.dart   ← Lista de recordatorios
│       │   └── conversations_page.dart ← Perfil/Ajustes
│       └── widgets/
│           ├── warmi_avatar.dart     ← Avatar animado con estados
│           ├── chat_bubble.dart      ← Burbujas de chat
│           ├── quick_actions_grid.dart ← Grid 8 acciones rápidas
│           ├── voice_button.dart     ← Botón micrófono animado
│           ├── input_bar.dart        ← Barra texto + micrófono
│           └── bottom_nav.dart       ← Navegación inferior
├── assets/
│   ├── images/                       ← warmi_avatar.png (agregar)
│   └── animations/                   ← warmi_idle.json Lottie (agregar)
└── android/
    ├── app/
    │   ├── build.gradle
    │   └── src/main/
    │       └── AndroidManifest.xml   ← Permisos + receptores
    └── build.gradle
```

---

## ⚡ Instalación Rápida

### 1. Copiar el proyecto
```bash
# Copiar toda la carpeta a C:\WarmiBot
# (reemplazar el contenido existente)
```

### 2. Configurar API Key
Abrir `.env` y pegar tu API key de OpenWeatherMap:
```
OPENWEATHER_API_KEY=tu_api_key_aqui
```
> Obtener key gratis en: https://openweathermap.org/api

### 3. Instalar dependencias
```bash
cd C:\WarmiBot
flutter pub get
```

### 4. Verificar Flutter
```bash
flutter doctor
```

### 5. Ejecutar en dispositivo Android
```bash
# Conectar teléfono con USB Debugging activado
flutter run
```

---

## 🎙️ Comandos Soportados

| Comando de voz | Ejemplo |
|---|---|
| **Hora/Fecha** | "WarmiBot, ¿qué hora es?" |
| **Clima** | "clima en Tena" / "temperatura en Quito" |
| **Alarma** | "alarma a las 7 con 30" |
| **Temporizador** | "temporizador de 5 minutos" |
| **Recordatorio** | "recuérdame comprar papel bond" |
| **Búsqueda** | "busca qué es la selva amazónica" |
| **Wikipedia** | "quién es Alexander von Humboldt" |
| **Traducción** | "traduce buenos días al inglés" |
| **Noticias** | "noticias" / "qué pasó hoy" |
| **WhatsApp** | "mensaje a Vicente: ya voy" |
| **Calculadora** | "cuánto es 15 por 8" |
| **Edad** | "mi edad el 20 de junio año 1995" |
| **Chiste** | "cuéntame un chiste" |
| **Música** | "reproduce cumbia" |

---

## 🗺️ Roadmap de Fases

### ✅ Fase 1 — MVP Funcional (COMPLETADA)
- [x] Arquitectura Flutter BLoC
- [x] STT + TTS en español
- [x] Parser de comandos con fuzzy matching
- [x] Todos los comandos del Python original
- [x] Avatar animado con estados visuales
- [x] Notificaciones push (alarmas, recordatorios)
- [x] Persistencia SQLite para recordatorios
- [x] Historial de conversaciones
- [x] Tema visual amazónico (paleta verde selva)
- [x] Grid de 8 acciones rápidas
- [x] Drawer lateral con accesos directos

### 🔄 Fase 2 — Servicios Conectados (Siguiente)
- [ ] Geolocalización GPS automática para clima
- [ ] Integración Google Calendar (device_calendar)
- [ ] Contactos reales del dispositivo (contacts_service)
- [ ] Exportar respuestas via share_plus
- [ ] Deep Linking WhatsApp mejorado

### 🚀 Fase 3 — WarmiBot Avanzado
- [ ] Avatar Lottie animado 3D con identidad Kichwa
- [ ] STT on-device con Whisper TFLite (sin internet)
- [ ] Recordatorios por geolocalización (Ej: CompuClick)
- [ ] Firebase Cloud Messaging (FCM)
- [ ] YouTube Data API v3 (suscriptores)
- [ ] Modo offline completo

---

## 🔑 Dependencias Principales

```yaml
flutter_bloc: ^8.1.6       # Gestión de estado
speech_to_text: ^6.6.2     # Reconocimiento de voz
flutter_tts: ^4.0.2        # Síntesis de voz
flutter_local_notifications # Alarmas y push
sqflite: ^2.3.3+1          # Base de datos local
http: ^1.2.1               # APIs REST
lottie: ^3.1.2             # Animaciones avatar
google_fonts: ^6.2.1       # Tipografía Poppins/Lato
```

---

## 🎨 Identidad Visual WarmiBot

| Elemento | Valor |
|---|---|
| Color primario | `#1B8A3C` Verde selva |
| Color acento | `#2ECC71` Verde brillante |
| Neón micrófono | `#00FF88` |
| Fondo oscuro | `#0A1628` Azul noche amazónico |
| Tipografía títulos | Poppins |
| Tipografía texto | Lato |
| Identidad | "Warmi" (Kichwa: mujer sabia, protectora) |

---

## ❓ Preguntas Pendientes para el Desarrollador

1. **¿Tienes imagen PNG del avatar WarmiBot?**
   - Colocarla en `assets/images/warmi_avatar.png`
   - Reemplazar el emoji 🌿 actual en `warmi_avatar.dart`

2. **¿Quieres animación Lottie para el avatar?**
   - Descargar desde https://lottiefiles.com (buscar "indigenous woman")
   - Colocar en `assets/animations/warmi_idle.json`

3. **¿Los contactos de WhatsApp son los correctos?**
   - Editar `app_constants.dart` → `contacts` con los números reales

4. **¿Quieres agregar tu nombre de usuario en el perfil?**
   - Editar `ProfilePage` en `conversations_page.dart` → cambiar 'G' por tu inicial

5. **¿Necesitas soporte iOS también?**
   - El código está preparado, pero requiere Mac + Xcode para compilar

---

## 📞 Soporte
**Gustavo Rodríguez** · Universidad Estatal Amazónica · CompuClick, Tena

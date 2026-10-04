# Distribución instalable de WarmiBot

## Artefacto verificado

- Archivo: `dist/WarmiBot-1.0.0-build2-signed.apk`
- Aplicación: `com.uea.warmibot`
- Versión: `1.0.0`
- Compilación: `2`
- Tamaño: 59.190.944 bytes
- SHA-256: `07AFBEB57EA1E33943C36D4D317D679050AA1FF1FB93F263F78A64E88A9D7447`
- Firma: APK Signature Scheme v2, RSA 2048 bits
- Certificado: `CN=WarmiBot, OU=Grupo 12, O=Universidad Estatal Amazonica, L=Tena, ST=Napo, C=EC`

## Requisitos del celular

- Android 7.0 (API 24) o posterior.
- Al menos 200 MB de espacio libre para descargar e instalar.
- Conexión a Internet para autenticación y sincronización con Render.
- Permitir temporalmente la instalación desde la aplicación usada para abrir
  el APK (Archivos, Drive, navegador o correo).
- Micrófono y notificaciones son opcionales; WarmiBot explica su finalidad
  antes de solicitarlos y mantiene alternativas si se deniegan.

## Instalación directa

1. Copiar el APK al teléfono sin cambiar su extensión.
2. Abrirlo desde Archivos o Descargas.
3. Si Android lo solicita, habilitar **Instalar aplicaciones desconocidas**
   solamente para esa aplicación de origen.
4. Pulsar **Instalar** y luego **Abrir**.
5. Desactivar nuevamente el permiso de instalación desconocida si no se
   utilizará para otras aplicaciones.

## Cuenta académica

- Correo: `grupo12@uea.edu.ec`
- Contraseña: se define en Render como `BOOTSTRAP_ADMIN_PASSWORD`.
- Valor configurado por el equipo: `warmibot2026`.

## Activación del backend en Render

1. Confirmar que la rama del proyecto con `render.yaml` esté en GitHub.
2. Crear una cuenta en <https://render.com/> e iniciar sesión con GitHub.
3. En el panel, elegir **New > Blueprint**.
4. Seleccionar `garh-uea/Proyecto-APP-WarmiBot` y la rama preparada.
5. Render detectará `render.yaml` y propondrá el servicio
   `warmibot-api-grupo12` y la base `warmibot-db-grupo12`.
6. Cuando pida `BOOTSTRAP_ADMIN_PASSWORD`, ingresar `warmibot2026`.
7. Aprobar la creación y esperar a que el servicio indique **Live**.
8. Abrir `https://warmibot-api-grupo12.onrender.com/health`; debe responder
   `{"status":"ok","environment":"production"}`.

El servicio gratuito puede suspenderse después de un periodo sin tráfico. La
primera solicitud posterior puede tardar cerca de un minuto mientras despierta.
La base PostgreSQL gratuita de Render expira a los 30 días; para conservar el
servicio después se debe migrar o renovar la base y generar un nuevo APK solo
si cambia la URL de la API.

## Respaldo obligatorio de la firma

Guardar en una ubicación privada y con copia de seguridad:

- `android/app/warmibot-release.jks`
- `android/key.properties`

Estos archivos no se suben a GitHub. Sin ellos no será posible publicar una
actualización firmada con la misma identidad. Son privados y no deben acompañar
al APK.

## Verificación realizada

- `flutter analyze`: sin problemas.
- `flutter test`: 44 pruebas aprobadas.
- `pytest`: 14 pruebas aprobadas.
- Compilación `release`: correcta.
- Firma del APK: verificada con `apksigner`.

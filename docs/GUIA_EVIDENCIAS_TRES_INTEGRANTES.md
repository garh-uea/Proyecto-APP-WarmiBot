# Guía de evidencias y exposición - tres integrantes

Esta guía distribuye la exposición sin atribuir capturas de un equipo a otro.
Cada integrante debe ejecutar los comandos en su propia computadora y reemplazar
en el informe los campos editables con su nombre y sus capturas auténticas.

## Integrante 1 - Entorno y elección de Flutter

Identidad visual sugerida: encabezados verdes.

1. Presentar WarmiBot, objetivo y justificación de Flutter.
2. Mostrar `flutter --version` y `flutter doctor -v`.
3. Mostrar VS Code y las extensiones Dart/Flutter.
4. Capturar la terminal completa incluyendo nombre del equipo o una nota de
   identificación visible.

Evidencia mínima: versiones, diagnóstico sin hallazgos y estructura `lib/`.

## Integrante 2 - Backend y comunicación

Identidad visual sugerida: encabezados azules.

1. Activar el entorno virtual del backend.
2. Ejecutar Uvicorn en `0.0.0.0:800`.
3. Abrir `http://127.0.0.1:800/health` y Swagger.
4. Explicar por qué el móvil usa `http://10.0.2.2:800`.
5. Mostrar una línea `GET /health ... 200 OK` en la terminal del servidor.

Evidencia mínima: servidor activo, respuesta JSON y configuración `.env.example`
sin mostrar secretos reales.

## Integrante 3 - Aplicación, hot reload y pruebas

Identidad visual sugerida: encabezados coral.

1. Iniciar Pixel_4 o conectar un teléfono por USB.
2. Ejecutar `flutter run -d <dispositivo>`.
3. Mostrar el indicador verde `API conectada`.
4. Realizar un cambio visual reversible y presionar `r`.
5. Mostrar `flutter test` y el APK generado.

Evidencia mínima: app en dispositivo, `Reloaded ... libraries`, pruebas aprobadas
y ruta del APK.

## Lista de control común

- Sustituir `[NOMBRE DEL INTEGRANTE]`, `[ASIGNATURA]`, `[DOCENTE]` y `[FECHA]`.
- No capturar contraseñas, tokens, claves de API ni el contenido de `.env`.
- Mantener visible la fecha de la demostración.
- Verificar el endpoint antes de grabar.
- Grabar con resolución legible y evitar ventanas ajenas al proyecto.
- Indicar cualquier diferencia de versiones entre equipos.

La captura incluida en el repositorio corresponde únicamente al equipo donde se
realizó la verificación del 16 de agosto de 2026. Las otras dos composiciones del
informe son guías de encuadre, no evidencia de ejecución.

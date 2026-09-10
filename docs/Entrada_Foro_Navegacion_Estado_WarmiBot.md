# Entrada para el foro: navegación y manejo de estado en WarmiBot

## 1. Descripción del proyecto

Nuestro proyecto se denomina **WarmiBot**. Es una aplicación móvil multiplataforma desarrollada con Flutter y orientada a funcionar como asistente virtual con identidad amazónica. Permite interactuar mediante texto y voz, consultar clima y noticias, realizar búsquedas y traducciones, y administrar recordatorios y alarmas. Además, se comunica con un backend propio construido con FastAPI, que incorpora autenticación mediante JWT, roles de usuario, conversaciones persistentes, tareas asíncronas y endpoints de diagnóstico.

Después de revisar e implementar el mapa de navegación, estimamos alrededor de **diez destinos de pantalla**: inicio de sesión, registro, estado de la API, Inicio, conversaciones, detalle de conversación, recordatorios, perfil, estado de trabajos y diagnóstico administrativo. También existen vistas transitorias de carga y acceso restringido, pero no las consideramos módulos funcionales principales.

Sí requerimos enlaces profundos. Su principal utilidad será abrir directamente una conversación o consultar el estado de un resumen desde una notificación, por ejemplo `warmibot://app/conversaciones/15` o `warmibot://app/trabajos/abc123`. Android explica que un vínculo profundo debe dirigir al usuario a un destino concreto de la aplicación, no únicamente abrir su pantalla inicial (Android Developers, 2026). Esta decisión también reduce pasos para acceder al contenido pertinente (Google Search Central, 2025).

## 2. Mapa de rutas

### Rutas públicas

- **`/login` — Iniciar sesión.** Consume `POST /api/v1/auth/login`. Si existe una sesión almacenada también intervienen `GET /api/v1/auth/me` y, cuando el access token venció, `POST /api/v1/auth/refresh`.
- **`/registro` — Crear cuenta.** Consume `POST /api/v1/auth/register`; después autentica al nuevo usuario mediante login.
- **`/estado-api` — Comprobar el backend.** Consume `GET /health` y muestra si la respuesta es HTTP 200 con `status: "ok"`.
- **`/cargando` — Comprobación transitoria de sesión.** No consume por sí misma un endpoint; representa visualmente el proceso de restauración o renovación de credenciales.

### Rutas protegidas para usuarios autenticados

- **`/inicio` — Asistente principal.** Presenta el chat, entrada de texto y voz, acciones rápidas y el indicador que consulta `GET /health`. Sus servicios de clima, noticias, traducción y búsqueda utilizan APIs externas; la conversación inmediata se mantiene en `AssistantBloc`.
- **`/conversaciones` — Historial de la sesión.** Actualmente muestra los mensajes administrados por `AssistantBloc`. El backend asociado dispone de `GET /api/v1/conversations` y `POST /api/v1/conversations` para la siguiente etapa de persistencia completa.
- **`/conversaciones/:conversationId` — Detalle enlazable.** Consume realmente `GET /api/v1/conversations/{conversation_id}` con token Bearer. Es un destino apto para enlaces profundos.
- **`/recordatorios` — Recordatorios y alarmas.** No necesita un endpoint remoto: utiliza el repositorio local SQLite y las notificaciones del dispositivo. Se mantiene protegida porque los recordatorios forman parte de la información personal del usuario.
- **`/perfil` — Datos y configuración.** La identidad mostrada procede de la sesión validada mediante `GET /api/v1/auth/me`. El cierre de sesión consume `POST /api/v1/auth/logout`.
- **`/trabajos/:jobId` — Estado de una tarea asíncrona.** Consume `GET /api/v1/jobs/{job_id}`. El trabajo se origina con `POST /api/v1/jobs/conversation-summary/{conversation_id}`.

### Ruta protegida por rol

- **`/diagnosticos` — Diagnóstico administrativo.** Solo admite usuarios con rol `admin` y consume `GET /api/v1/diagnostics/cache`. El backend también ofrece `POST /api/v1/diagnostics/seed` y `GET /api/v1/diagnostics/n-plus-one` en entornos donde el diagnóstico esté habilitado.

### Ruta de control de acceso

- **`/acceso-restringido` — Respuesta a un 403.** No consume un endpoint adicional. Explica que la sesión continúa siendo válida, pero el usuario no posee el rol necesario.

## 3. Navegación imperativa frente a declarativa

La navegación imperativa usa instrucciones como `push`, `pop` o cambios manuales de índice. Es directa y conveniente para acciones puntuales, como cerrar un diálogo. Sin embargo, se vuelve difícil de mantener cuando la pantalla depende simultáneamente de una URL, la autenticación, el rol y un enlace profundo.

La navegación declarativa expresa qué pantalla debe existir para un estado y una ubicación determinados. En WarmiBot adoptamos este enfoque con `go_router`: si no existe una sesión, una ruta protegida produce `/login`; si la sesión es válida, se conserva el destino solicitado; y si el rol es insuficiente, se presenta `/acceso-restringido`. Los filtros nativos fueron registrados en Android e iOS mediante el esquema `warmibot://app/...`.

Elegimos navegación declarativa porque WarmiBot ya no es una aplicación lineal. Necesita restaurar sesiones, aceptar rutas con parámetros, proteger módulos y reaccionar a 401 y 403. Mantenemos navegación imperativa únicamente para elementos pasajeros, como cerrar el menú lateral o un cuadro de confirmación. Esta combinación evita convertir un diálogo en una ruta permanente y, al mismo tiempo, hace reproducibles los destinos funcionales.

## 4. Comparación de mecanismos de manejo de estado

Comparamos **`setState`/ChangeNotifier-Provider** con **BLoC/Cubit** conforme a alcance, complejidad, predictibilidad, pruebas y mantenimiento.

`setState` resulta apropiado para un dato pequeño y exclusivo de un widget. Tiene poca configuración y permite actualizar rápidamente una vista; no obstante, si se usa para sesión, mensajes o permisos, la lógica queda mezclada con la interfaz y es difícil reconstruir cómo ocurrió cada transición. Provider con ChangeNotifier mejora el acceso compartido y requiere menos código que BLoC, pero conserva un objeto mutable que puede notificar varios cambios sin que la causa quede representada como un evento. Martín Cubero (2023) considera Provider adecuado para cantidades pequeñas o moderadas de datos y BLoC más conveniente cuando la lógica es grande o compleja.

BLoC/Cubit separa entradas, reglas y resultados. Su costo es una mayor cantidad de clases y una curva de aprendizaje superior; a cambio, proporciona estados explícitos, transiciones predecibles y pruebas unitarias más directas. Torres Peña y Andrade Solórzano (2021) describen BLoC como gestor principal de la lógica durante la vida de una aplicación y muestran el uso de `BlocListener` para efectos como navegación y avisos. Benavides Cabrera y Sánchez Sucuzhañay (2023) también documentan el uso conjunto de BLoC y Provider en una aplicación Flutter con servicios y estado compartido.

En WarmiBot adoptamos una estrategia híbrida y proporcional:

- **BLoC** para el asistente, porque coordina voz, texto, servicios, mensajes, carga y errores.
- **Cubit** para autenticación, porque la sesión tiene menos eventos, pero afecta a toda la aplicación y a la navegación.
- **`setState`** para estado efímero que pertenece a una sola pantalla, por ejemplo la carga local de recordatorios o la presentación temporal de una solicitud.

Esta elección no intenta reemplazar todo con BLoC. Busca que cada estado tenga el alcance mínimo correcto. La separación también coincide con la experiencia académica descrita por Ocaña Ocaña (2023), donde Flutter se integra con APIs y navegación dentro de una aplicación móvil estructurada.

## 5. Clasificación del estado

1. **Texto que el usuario escribe y validación del formulario — estado efímero.** Solo interesa mientras la pantalla de acceso o registro está abierta. Si se abandona el formulario, no es necesario conservarlo como dato global.
2. **Posición de desplazamiento y apertura de un diálogo — estado efímero.** Son detalles visuales locales y no representan información del negocio.
3. **Indicador de carga de recordatorios — estado efímero.** Describe una operación temporal de una pantalla; se maneja localmente con `setState`.
4. **Mensajes y estado del asistente — estado de aplicación.** Se usan en Inicio y Conversaciones, y coordinan reconocimiento de voz, síntesis, procesamiento, errores y respuestas. Por eso pertenecen a `AssistantBloc`.
5. **Sesión, usuario, rol y tokens — estado de aplicación.** Determinan qué rutas pueden abrirse y qué credenciales acompañan las solicitudes. Se administran con `AuthCubit`, mientras los tokens se guardan en almacenamiento seguro del sistema operativo.
6. **Recordatorios — estado persistente de aplicación.** Deben sobrevivir al cierre de una pantalla y al reinicio de la aplicación; por eso se almacenan en SQLite y se vinculan con alarmas locales.

## 6. Diferencia entre 401 y 403

No trataremos ambos códigos como si fueran el mismo error. MDN Contributors (2025a) define 401 como ausencia de credenciales válidas, mientras 403 indica que el servidor conoce la solicitud pero rechaza el acceso por falta de permisos (MDN Contributors, 2025b).

Ante **HTTP 401**, WarmiBot entiende que la autenticación dejó de ser válida. Primero intenta `POST /api/v1/auth/refresh`. Si obtiene nuevos tokens, conserva la pantalla y permite reintentar la petición. Si la renovación también falla, elimina las credenciales, cambia el estado a no autenticado y redirige a `/login`, guardando la ruta original en el parámetro `from`. FastAPI explica que el frontend debe enviar el token Bearer en `Authorization` para acceder a endpoints protegidos (Ramírez, s. f.-a).

Ante **HTTP 403**, WarmiBot no borra los tokens ni envía al usuario al login, porque iniciar sesión nuevamente no concede un rol distinto. Conserva la sesión y abre `/acceso-restringido`, donde informa que la identidad es válida pero el permiso es insuficiente. En el backend esta diferencia ya existe: una cuenta desactivada puede producir 403 y los endpoints de diagnóstico exigen rol administrador. OAuth2 y JWT permiten expresar restricciones adicionales mediante permisos o *scopes* (Ramírez, s. f.-b).

## Conclusión

La solución final ya no depende de un índice aislado para decidir qué pantalla mostrar. El mapa declarativo relaciona ubicación, sesión y rol; los enlaces profundos pueden recuperar un destino específico; y el manejo de estado distingue datos pasajeros de información compartida o persistente. Elegimos BLoC/Cubit para los procesos que atraviesan varias pantallas y `setState` para detalles locales. La diferencia explícita entre 401 y 403 mejora tanto la seguridad como la experiencia del usuario, porque una sesión expirada requiere autenticación y un permiso insuficiente requiere una explicación, no otro inicio de sesión.

## Referencias bibliográficas

Android Developers. (2026). *Cómo crear vínculos directos para un destino*. Google. https://developer.android.com/guide/navigation/design/deep-link?hl=es-419

Benavides Cabrera, J. C., & Sánchez Sucuzhañay, L. F. (2023). *Aplicación móvil multiplataforma de asistencia vial para la comunidad de motociclistas de la ciudad de Cuenca* [Trabajo de titulación, Universidad Politécnica Salesiana]. https://dspace.ups.edu.ec/bitstream/123456789/24927/1/UPS-CT010546.pdf

Google Search Central. (2025). *Enlaces profundos de aplicaciones: conectar tu sitio web y aplicación*. Google for Developers. https://developers.google.com/search/blog/2025/05/app-deep-links?hl=es

Martín Cubero, D. (2023). *DaSell: Plataforma de compraventa mediante servicios avanzados realizado en Flutter* [Trabajo de fin de grado, Universidad de Valladolid]. https://uvadoc.uva.es/bitstream/10324/59938/1/TFG-B.%201916.pdf

MDN Contributors. (2025a). *401 Unauthorized*. MDN Web Docs. https://developer.mozilla.org/es/docs/Web/HTTP/Reference/Status/401

MDN Contributors. (2025b). *403 Forbidden*. MDN Web Docs. https://developer.mozilla.org/es/docs/Web/HTTP/Reference/Status/403

Ocaña Ocaña, D. V. (2023). *Aplicación móvil utilizando Flutter para la reserva de taxis urbanos dentro de la ciudad de Ambato* [Trabajo de titulación, Universidad Técnica de Ambato]. https://repositorio.uta.edu.ec/handle/123456789/38383

Ramírez, S. (s. f.-a). *Seguridad: primeros pasos*. FastAPI. Recuperado el 26 de agosto de 2026, de https://fastapi.tiangolo.com/es/tutorial/security/first-steps/

Ramírez, S. (s. f.-b). *OAuth2 con Password (y hashing), Bearer con tokens JWT*. FastAPI. Recuperado el 26 de agosto de 2026, de https://fastapi.tiangolo.com/es/tutorial/security/oauth2-jwt/

Torres Peña, P. A., & Andrade Solórzano, B. A. (2021). *Aplicación móvil informativa y de apoyo académico de la Universidad Politécnica Salesiana* [Trabajo de titulación, Universidad Politécnica Salesiana]. https://dspace.ups.edu.ec/bitstream/123456789/21490/1/UPS-CT009458.pdf

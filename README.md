# Chambing-Flutter

App Flutter que **consume la API Spring Boot** de Chambing (`../ChambingV3_ARREGLADO 5/chambing_debug`).
No se conecta directo a las bases: el backend usa MongoDB (empresas, propuestas, usuarios) y MySQL (catálogos).

## Funciones
1. **Registrar empresa** → `POST /empresa` (Mongo)
2. **Login de empresa + propuestas**: publicar, listar y eliminar → `/api/auth/login`, `/empresa/me`, `/empresa/{id}/propuestas` (Mongo)
3. **Registrar usuario** con tipo de documento y género cargados de MySQL → `/api/catalogos/**`, `POST /usuario`
4. **Login de usuario + postulaciones**: buscar y filtrar ofertas, ver detalle, postularse y seguir el estado
   (Pendiente / Aprobado / Rechazado) → `/api/auth/login`, `/usuario/me`, `/usuario/propuestas`,
   `POST /usuario/aplicar/{idUsuario}/{idPropuesta}`, `/usuario/postulaciones/{idUsuario}` (Mongo)

## Cómo correrla
1. Encender el backend (puerto 9999).
2. En esta carpeta:
   ```
   flutter pub get
   flutter run -d chrome      # o -d edge
   ```
   No hace falta ningún flag: el backend acepta CORS desde `http://localhost:*` y `http://127.0.0.1:*`
   (bean `corsConfigurationSource()` en `security/SecurityConfig.java`).
   Con Visual Studio "Desarrollo de escritorio con C++" instalado también sirve `flutter run -d windows`.
3. Para otro servidor: `--dart-define=API_URL=http://IP:9999`.
   Si la app web se sirve desde otro dominio o IP, hay que agregarlo en `allowedOriginPatterns` de ese bean;
   si no, el navegador muestra `ClientException: Failed to fetch`.

## Manejo de errores
Todo pasa por `lib/core/network/api_client.dart`, que convierte cualquier fallo en una `AppException`
(`lib/core/errors/app_exception.dart`) con mensaje en español:
sin internet, servidor apagado, tiempo agotado, sesión vencida (Spring redirige a /login),
cuenta del tipo equivocado (empresa/usuario), postulación repetida (409), datos inválidos (400 del backend), error 500, JSON inesperado.
Además, `main.dart` captura los errores no previstos y reemplaza la pantalla roja de Flutter;
un banner avisa cuando no hay conexión.

## Tests
`flutter test` — cubre cada caso de error del cliente HTTP, el login de usuario, las postulaciones y el arranque de la app.

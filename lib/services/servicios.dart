import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/session/session_store.dart';
import '../models/catalogo_item.dart';
import '../models/empresa.dart';
import '../models/postulacion.dart';
import '../models/propuesta.dart';
import '../models/usuario.dart';

// ── Instancias compartidas (inyección simple) ───────────────────────────────
final sessionStore = SessionStore();
final connectivityService = ConnectivityService();
final apiClient = ApiClient(
  session: sessionStore,
  hayConexion: connectivityService.hayConexion,
);
final authService = AuthService(apiClient, sessionStore);
final empresaService = EmpresaService(apiClient);
final propuestaService = PropuestaService(apiClient);
final usuarioService = UsuarioService(apiClient);
final catalogoService = CatalogoService(apiClient);
final postulacionService = PostulacionService(apiClient);

/// Login de empresa con JWT (`POST /api/auth/login` + `GET /empresa/me`).
class AuthService {
  AuthService(this._api, this._session);

  final ApiClient _api;
  final SessionStore _session;

  Future<Empresa> loginEmpresa(String correo, String contrasena) async {
    await _pedirToken(correo, contrasena);

    try {
      final me = await _api.get('/empresa/me', auth: true);
      final empresa =
          parsearRespuesta(() => Empresa.fromJson(me as Map<String, dynamic>));
      await _session.guardarEmpresa(empresa.idEmpresa!, empresa.nombreEmpresa);
      return empresa;
    } on AppException catch (e) {
      await _session.limpiar();
      // Token recién emitido pero no es empresa: es una cuenta de usuario.
      // Spring deja pasar /empresa/me a cualquier logueado (regla GET
      // /empresa/{idEmpresa}) y responde 404 "Empresa no encontrada".
      if (e is AccesoDenegado || e is SesionExpirada || e is NoEncontrado) {
        throw const AccesoDenegado('Esta cuenta no es de empresa. '
            'Inicia sesión con el correo de una empresa.');
      }
      rethrow;
    }
  }

  /// Login de usuario (`POST /api/auth/login` + `GET /usuario/me`).
  Future<void> loginUsuario(String correo, String contrasena) async {
    await _pedirToken(correo, contrasena);
    try {
      final me = await _api.get('/usuario/me', auth: true);
      final (id, nombre) = parsearRespuesta(() {
        final m = me as Map<String, dynamic>;
        final nombre = '${m['nombre'] ?? ''} ${m['apellido'] ?? ''}'.trim();
        return (m['idUsuario'] as String, nombre.isEmpty ? 'Mi cuenta' : nombre);
      });
      await _session.guardarUsuario(id, nombre);
    } on AppException catch (e) {
      await _session.limpiar();
      // Token válido pero sin permiso USER: es una cuenta de empresa.
      if (e is AccesoDenegado || e is SesionExpirada) {
        throw const AccesoDenegado('Esta cuenta es de empresa. '
            'Usa "Soy empresa: iniciar sesión".');
      }
      rethrow;
    }
  }

  Future<void> _pedirToken(String correo, String contrasena) async {
    await _session.limpiar();
    final res = await _api.post('/api/auth/login', {
      // El backend guarda los correos en minúscula pero no normaliza el login.
      'email': correo.trim().toLowerCase(),
      'password': contrasena,
    });
    final token = parsearRespuesta(() => (res as Map)['token'] as String);
    await _session.guardarToken(token);
  }

  Future<void> cerrarSesion() => _session.limpiar();
}

/// Registro de empresa (`POST /empresa`, colección Mongo "empresas").
class EmpresaService {
  EmpresaService(this._api);

  final ApiClient _api;

  Future<void> registrar(Empresa empresa) async {
    try {
      await _api.post('/empresa', empresa.toRegistroJson());
    } on ErrorServidor {
      // Mongo rechaza NIT duplicado (índice único) con un 500.
      throw const ErrorServidor('No se pudo registrar la empresa. '
          'Es posible que el NIT ya esté registrado.');
    }
  }
}

/// Propuestas de la empresa logueada (colección Mongo "propuestas").
class PropuestaService {
  PropuestaService(this._api);

  final ApiClient _api;

  Future<List<Propuesta>> listar(String idEmpresa) async {
    final res = await _api.get('/empresa/$idEmpresa/propuestas', auth: true);
    return parsearRespuesta(() => (res as List)
        .map((e) => Propuesta.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  Future<Propuesta> crear(String idEmpresa, Propuesta propuesta) async {
    final res = await _api.post(
        '/empresa/$idEmpresa/propuestas', propuesta.toJson(),
        auth: true);
    return parsearRespuesta(
        () => Propuesta.fromJson(res as Map<String, dynamic>));
  }

  Future<void> eliminar(String idEmpresa, String idPropuesta) =>
      _api.delete('/empresa/$idEmpresa/propuestas/$idPropuesta', auth: true);
}

/// Registro de usuario (`POST /usuario`, colección Mongo "usuarios").
class UsuarioService {
  UsuarioService(this._api);

  final ApiClient _api;

  Future<void> registrar(Usuario usuario) async {
    try {
      await _api.post('/usuario', usuario.toRegistroJson());
    } on ErrorServidor {
      throw const ErrorServidor('No se pudo registrar el usuario. '
          'Es posible que el número de documento ya esté registrado.');
    }
  }
}

/// Catálogos que el backend lee de MySQL (`/api/catalogos/**`).
class CatalogoService {
  CatalogoService(this._api);

  final ApiClient _api;

  Future<List<CatalogoItem>> tiposDocumento() =>
      _cargar('/api/catalogos/tipos-documento');

  Future<List<CatalogoItem>> generos() => _cargar('/api/catalogos/generos');

  Future<List<CatalogoItem>> _cargar(String path) async {
    try {
      final res = await _api.get(path);
      return parsearRespuesta<List<CatalogoItem>>(() => (res as List)
          .map((e) => CatalogoItem.fromJson(e as Map<String, dynamic>))
          .toList());
    } on ErrorServidor {
      throw const ErrorServidor('No se pudieron cargar los catálogos '
          '(base de datos MySQL). Intenta más tarde.');
    }
  }
}

/// Ofertas y postulaciones del usuario logueado (colecciones Mongo
/// "propuestas" y "postulaciones").
class PostulacionService {
  PostulacionService(this._api);

  final ApiClient _api;

  /// Todas las propuestas publicadas por todas las empresas. El backend no
  /// pagina: son miles (más de 12 MB), así que se espera más de lo normal.
  Future<List<Propuesta>> ofertas() async {
    final res = await _api.get('/usuario/propuestas',
        auth: true, timeout: const Duration(seconds: 60));
    return parsearRespuesta(() => (res as List)
        .map((e) => Propuesta.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  Future<Postulacion> aplicar(String idUsuario, String idPropuesta) async {
    try {
      final res = await _api.post(
          '/usuario/aplicar/$idUsuario/$idPropuesta', null,
          auth: true);
      return parsearRespuesta<Postulacion>(
          () => Postulacion.fromJson(res as Map<String, dynamic>));
    } on Validacion catch (e) {
      // 400 "Usuario o propuesta no encontrados": la oferta ya no existe.
      if (e.mensaje.contains('no encontrad')) {
        throw const NoEncontrado('Esta propuesta ya no está disponible.');
      }
      rethrow;
    }
  }

  Future<List<Postulacion>> misPostulaciones(String idUsuario) async {
    final res = await _api.get('/usuario/postulaciones/$idUsuario', auth: true);
    final lista = parsearRespuesta(() => (res as List)
        .map((e) => Postulacion.fromJson(e as Map<String, dynamic>))
        .toList());
    // Más recientes primero.
    lista.sort((a, b) => (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
    return lista;
  }
}

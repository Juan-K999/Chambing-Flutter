import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errors/app_exception.dart';
import '../../models/catalogo_item.dart';
import '../../models/direccion.dart';
import '../../models/usuario.dart';
import '../../services/servicios.dart';
import '../../widgets/comunes.dart';
import 'login_usuario_screen.dart';

/// Registro de usuario. Los tipos de documento y los géneros se cargan de
/// MySQL (vía /api/catalogos); el usuario se guarda en Mongo (POST /usuario).
class RegistroUsuarioScreen extends StatefulWidget {
  const RegistroUsuarioScreen({super.key});

  @override
  State<RegistroUsuarioScreen> createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  final _form = GlobalKey<FormState>();
  final _documento = TextEditingController();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _edad = TextEditingController();
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  final _calle = TextEditingController();
  final _ciudad = TextEditingController();
  final _departamento = TextEditingController();

  List<CatalogoItem> _tipos = [];
  List<CatalogoItem> _generos = [];
  String? _tipoDocumento;
  String? _genero;

  bool _cargandoCatalogos = true;
  String? _errorCatalogos;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  @override
  void dispose() {
    for (final c in [
      _documento, _nombre, _apellido, _edad, _email,
      _contrasena, _calle, _ciudad, _departamento,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCatalogos = null;
    });
    try {
      final r = await Future.wait(
          [catalogoService.tiposDocumento(), catalogoService.generos()]);
      if (!mounted) return;
      setState(() {
        _tipos = r[0];
        _generos = r[1];
        if (_tipos.isEmpty || _generos.isEmpty) {
          _errorCatalogos = 'Los catálogos de MySQL están vacíos. '
              'Pide al administrador que registre géneros y tipos de documento.';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _errorCatalogos = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargandoCatalogos = false);
    }
  }

  Future<void> _registrar() async {
    if (_enviando || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    try {
      await usuarioService.registrar(Usuario(
        tipoDocumento: _tipoDocumento!,
        documento: int.parse(_documento.text.trim()),
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        edad: int.parse(_edad.text.trim()),
        genero: _genero!,
        email: _email.text.trim(),
        contrasena: _contrasena.text,
        direccion: Direccion(
          calle: _calle.text.trim(),
          ciudad: _ciudad.text.trim(),
          departamento: _departamento.text.trim(),
        ),
      ));
      if (!mounted) return;
      mostrarMensaje(context, 'Usuario registrado. Ahora inicia sesión.',
          error: false);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => LoginUsuarioScreen(correoInicial: _email.text.trim())));
    } catch (e) {
      if (mounted) mostrarMensaje(context, mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar usuario')),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargandoCatalogos) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Cargando catálogos…'),
        ]),
      );
    }
    if (_errorCatalogos != null) {
      return ErrorView(mensaje: _errorCatalogos!, onReintentar: _cargarCatalogos);
    }

    return Form(
      key: _form,
      child: FormularioCentrado(children: [
        const Seccion('Identificación'),
        _desplegable(
          label: 'Tipo de documento *',
          icono: Icons.badge_outlined,
          valor: _tipoDocumento,
          items: [
            for (final t in _tipos)
              DropdownMenuItem(value: t.codigo ?? t.nombre, child: Text(t.nombre)),
          ],
          onChanged: (v) => setState(() => _tipoDocumento = v),
          error: 'Elige un tipo de documento',
        ),
        Campo(
          controller: _documento,
          label: 'Número de documento *',
          icono: Icons.numbers,
          teclado: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => Validar.numero(v, 'El documento', min: 5, max: 15),
        ),
        const Seccion('Datos personales'),
        Campo(
          controller: _nombre,
          label: 'Nombre *',
          icono: Icons.person_outline,
          validator: (v) => Validar.requerido(v, 'El nombre'),
        ),
        Campo(
          controller: _apellido,
          label: 'Apellido *',
          icono: Icons.person_outline,
          validator: (v) => Validar.requerido(v, 'El apellido'),
        ),
        Campo(
          controller: _edad,
          label: 'Edad *',
          icono: Icons.cake_outlined,
          teclado: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          validator: Validar.edad,
        ),
        _desplegable(
          label: 'Género *',
          icono: Icons.wc,
          valor: _genero,
          items: [
            for (final g in _generos)
              DropdownMenuItem(value: g.nombre, child: Text(g.nombre)),
          ],
          onChanged: (v) => setState(() => _genero = v),
          error: 'Elige un género',
        ),
        const Seccion('Cuenta'),
        Campo(
          controller: _email,
          label: 'Correo *',
          icono: Icons.email_outlined,
          teclado: TextInputType.emailAddress,
          validator: Validar.correo,
        ),
        Campo(
          controller: _contrasena,
          label: 'Contraseña *',
          icono: Icons.lock_outline,
          oculto: true,
          validator: Validar.contrasena,
        ),
        const Seccion('Dirección'),
        Campo(controller: _calle, label: 'Calle', icono: Icons.home_outlined),
        Campo(controller: _ciudad, label: 'Ciudad', icono: Icons.location_city),
        Campo(
          controller: _departamento,
          label: 'Departamento',
          icono: Icons.map_outlined,
          accion: TextInputAction.done,
        ),
        const SizedBox(height: 8),
        LoadingButton(
          cargando: _enviando,
          onPressed: _registrar,
          texto: 'Crear cuenta',
          icono: Icons.person_add_alt,
        ),
      ]),
    );
  }

  Widget _desplegable({
    required String label,
    required IconData icono,
    required String? valor,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: valor,
        items: items,
        onChanged: onChanged,
        validator: (v) => v == null ? error : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icono),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

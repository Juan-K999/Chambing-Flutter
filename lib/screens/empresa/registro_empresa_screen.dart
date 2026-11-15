import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errors/app_exception.dart';
import '../../models/direccion.dart';
import '../../models/empresa.dart';
import '../../services/servicios.dart';
import '../../widgets/comunes.dart';
import 'login_empresa_screen.dart';

class RegistroEmpresaScreen extends StatefulWidget {
  const RegistroEmpresaScreen({super.key});

  @override
  State<RegistroEmpresaScreen> createState() => _RegistroEmpresaScreenState();
}

class _RegistroEmpresaScreenState extends State<RegistroEmpresaScreen> {
  final _form = GlobalKey<FormState>();
  final _nit = TextEditingController();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _calle = TextEditingController();
  final _ciudad = TextEditingController();
  final _departamento = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    for (final c in [_nit, _nombre, _correo, _contrasena, _calle, _ciudad, _departamento]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_enviando || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    try {
      await empresaService.registrar(Empresa(
        nit: int.parse(_nit.text.trim()),
        nombreEmpresa: _nombre.text.trim(),
        correo: _correo.text.trim(),
        contrasena: _contrasena.text,
        direccion: Direccion(
          calle: _calle.text.trim(),
          ciudad: _ciudad.text.trim(),
          departamento: _departamento.text.trim(),
        ),
      ));
      if (!mounted) return;
      mostrarMensaje(context, 'Empresa registrada. Ahora inicia sesión.',
          error: false);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) =>
              LoginEmpresaScreen(correoInicial: _correo.text.trim())));
    } catch (e) {
      if (mounted) mostrarMensaje(context, mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar empresa')),
      body: Form(
        key: _form,
        child: FormularioCentrado(children: [
          const Seccion('Datos de la empresa'),
          Campo(
            controller: _nit,
            label: 'NIT *',
            icono: Icons.badge_outlined,
            teclado: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => Validar.numero(v, 'El NIT', min: 6, max: 15),
          ),
          Campo(
            controller: _nombre,
            label: 'Nombre de la empresa *',
            icono: Icons.business,
            validator: (v) => Validar.requerido(v, 'El nombre'),
          ),
          Campo(
            controller: _correo,
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
          Campo(
            controller: _calle,
            label: 'Calle *',
            icono: Icons.home_outlined,
            validator: (v) => Validar.requerido(v, 'La calle'),
          ),
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
            texto: 'Crear cuenta de empresa',
            icono: Icons.business,
          ),
        ]),
      ),
    );
  }
}

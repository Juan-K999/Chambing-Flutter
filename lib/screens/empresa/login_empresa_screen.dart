import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../services/servicios.dart';
import '../../widgets/comunes.dart';
import 'propuestas_screen.dart';
import 'registro_empresa_screen.dart';

class LoginEmpresaScreen extends StatefulWidget {
  const LoginEmpresaScreen({super.key, this.correoInicial});

  final String? correoInicial;

  @override
  State<LoginEmpresaScreen> createState() => _LoginEmpresaScreenState();
}

class _LoginEmpresaScreenState extends State<LoginEmpresaScreen> {
  final _form = GlobalKey<FormState>();
  late final _correo = TextEditingController(text: widget.correoInicial);
  final _contrasena = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (_enviando || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    try {
      await authService.loginEmpresa(_correo.text, _contrasena.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PropuestasScreen()),
        (ruta) => ruta.isFirst,
      );
    } catch (e) {
      if (mounted) mostrarMensaje(context, mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión como empresa')),
      body: Form(
        key: _form,
        child: FormularioCentrado(children: [
          const SizedBox(height: 8),
          Campo(
            controller: _correo,
            label: 'Correo de la empresa',
            icono: Icons.email_outlined,
            teclado: TextInputType.emailAddress,
            validator: Validar.correo,
          ),
          Campo(
            controller: _contrasena,
            label: 'Contraseña',
            icono: Icons.lock_outline,
            oculto: true,
            accion: TextInputAction.done,
            validator: Validar.contrasena,
          ),
          const SizedBox(height: 8),
          LoadingButton(
            cargando: _enviando,
            onPressed: _ingresar,
            texto: 'Ingresar',
            icono: Icons.login,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const RegistroEmpresaScreen())),
            child: const Text('¿No tienes cuenta? Registra tu empresa'),
          ),
        ]),
      ),
    );
  }
}

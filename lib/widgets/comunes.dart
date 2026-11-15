import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/servicios.dart';

// ── Mensajes ────────────────────────────────────────────────────────────────

void mostrarMensaje(BuildContext context, String mensaje, {bool error = true}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final esquema = Theme.of(context).colorScheme;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? esquema.error : Colors.green.shade700,
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
            child: Text(mensaje, style: const TextStyle(color: Colors.white))),
      ]),
    ));
}

// ── Banner global de "sin conexión" ─────────────────────────────────────────

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _conectado = true;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    connectivityService.hayConexion().then(_actualizar);
    _sub = connectivityService.cambios.listen(_actualizar, onError: (_) {});
  }

  void _actualizar(bool conectado) {
    if (mounted && conectado != _conectado) {
      setState(() => _conectado = conectado);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: _conectado
          ? const SizedBox(width: double.infinity)
          : Material(
              color: Colors.orange.shade800,
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sin conexión a internet. Los cambios no se enviarán '
                        'hasta que vuelvas a conectarte.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}

// ── Vista de error con "Reintentar" ─────────────────────────────────────────

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off,
              size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ]),
      ),
    );
  }
}

// ── Botón con estado de carga (evita dobles envíos) ─────────────────────────

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.cargando,
    required this.onPressed,
    required this.texto,
    this.icono,
  });

  final bool cargando;
  final VoidCallback onPressed;
  final String texto;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: cargando ? null : onPressed,
        icon: cargando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icono ?? Icons.check),
        label: Text(cargando ? 'Enviando…' : texto),
      ),
    );
  }
}

// ── Contenedor de formularios: centrado y con ancho máximo en PC ────────────

class FormularioCentrado extends StatelessWidget {
  const FormularioCentrado({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class Seccion extends StatelessWidget {
  const Seccion(this.titulo, {super.key});

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(titulo,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

// ── Campo de texto con espaciado y estilo uniformes ─────────────────────────

class Campo extends StatelessWidget {
  const Campo({
    super.key,
    required this.controller,
    required this.label,
    this.icono,
    this.validator,
    this.teclado,
    this.oculto = false,
    this.lineas = 1,
    this.formatters,
    this.accion = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icono;
  final String? Function(String?)? validator;
  final TextInputType? teclado;
  final bool oculto;
  final int lineas;
  final List<TextInputFormatter>? formatters;
  final TextInputAction accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: oculto,
        keyboardType: teclado,
        maxLines: oculto ? 1 : lineas,
        inputFormatters: formatters,
        textInputAction: lineas > 1 ? TextInputAction.newline : accion,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icono == null ? null : Icon(icono),
          border: const OutlineInputBorder(),
          alignLabelWithHint: lineas > 1,
        ),
      ),
    );
  }
}

// ── Validaciones (las mismas reglas que aplica el backend) ──────────────────

class Validar {
  Validar._();

  static String? requerido(String? v, [String campo = 'Este campo']) =>
      (v == null || v.trim().isEmpty) ? '$campo es obligatorio' : null;

  static String? correo(String? v) {
    final r = requerido(v, 'El correo');
    if (r != null) return r;
    final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(v!.trim());
    return ok ? null : 'Escribe un correo válido';
  }

  static String? contrasena(String? v) => (v == null || v.length < 4)
      ? 'La contraseña debe tener mínimo 4 caracteres'
      : null;

  static String? numero(String? v, String campo, {int min = 1, int max = 15}) {
    final r = requerido(v, campo);
    if (r != null) return r;
    final d = v!.trim();
    if (!RegExp(r'^\d+$').hasMatch(d)) return '$campo solo admite números';
    if (d.length < min || d.length > max) {
      return '$campo debe tener entre $min y $max dígitos';
    }
    return null;
  }

  static String? edad(String? v) {
    final r = numero(v, 'La edad', max: 3);
    if (r != null) return r;
    final n = int.parse(v!.trim());
    if (n < 18) return 'Debes ser mayor de edad (18+)';
    if (n > 100) return 'Escribe una edad válida';
    return null;
  }
}

// ── Formato de salario con separador de miles (1.500.000) ──────────────────

String formatearMiles(num valor) {
  final digitos = valor.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}

class MilesInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return const TextEditingValue();
    final recortado = digitos.length > 12 ? digitos.substring(0, 12) : digitos;
    final texto = formatearMiles(int.parse(recortado));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

double? leerMiles(String texto) {
  final d = texto.replaceAll(RegExp(r'\D'), '');
  return d.isEmpty ? null : double.parse(d);
}

import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../models/propuesta.dart';
import '../../services/servicios.dart';
import '../../widgets/comunes.dart';
import 'login_empresa_screen.dart';

/// Publica una propuesta. Devuelve `true` al cerrar si se creó.
class NuevaPropuestaScreen extends StatefulWidget {
  const NuevaPropuestaScreen({super.key, required this.idEmpresa});

  final String idEmpresa;

  @override
  State<NuevaPropuestaScreen> createState() => _NuevaPropuestaScreenState();
}

class _NuevaPropuestaScreenState extends State<NuevaPropuestaScreen> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _requisitos = TextEditingController();
  final _salario = TextEditingController();
  String? _categoria;
  bool _enviando = false;

  @override
  void dispose() {
    for (final c in [_titulo, _descripcion, _requisitos, _salario]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _publicar() async {
    if (_enviando || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    try {
      await propuestaService.crear(
        widget.idEmpresa,
        Propuesta(
          titulo: _titulo.text.trim(),
          descripcion: _descripcion.text.trim(),
          requisitos: _requisitos.text.trim(),
          salario: leerMiles(_salario.text),
          categoria: _categoria!,
        ),
      );
      if (!mounted) return;
      mostrarMensaje(context, 'Propuesta publicada', error: false);
      Navigator.of(context).pop(true);
    } on SesionExpirada catch (e) {
      if (!mounted) return;
      mostrarMensaje(context, e.mensaje);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginEmpresaScreen()),
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
      appBar: AppBar(title: const Text('Nueva propuesta')),
      body: Form(
        key: _form,
        child: FormularioCentrado(children: [
          const SizedBox(height: 8),
          Campo(
            controller: _titulo,
            label: 'Título del cargo *',
            icono: Icons.title,
            validator: (v) => Validar.requerido(v, 'El título'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoría *',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in Propuesta.categorias)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _categoria = v),
              validator: (v) => v == null ? 'Elige una categoría' : null,
            ),
          ),
          Campo(
            controller: _salario,
            label: 'Salario (COP)',
            icono: Icons.payments_outlined,
            teclado: TextInputType.number,
            formatters: [MilesInputFormatter()],
          ),
          Campo(
            controller: _descripcion,
            label: 'Descripción *',
            lineas: 4,
            validator: (v) => Validar.requerido(v, 'La descripción'),
          ),
          Campo(controller: _requisitos, label: 'Requisitos', lineas: 3),
          const SizedBox(height: 8),
          LoadingButton(
            cargando: _enviando,
            onPressed: _publicar,
            texto: 'Publicar propuesta',
            icono: Icons.send,
          ),
        ]),
      ),
    );
  }
}

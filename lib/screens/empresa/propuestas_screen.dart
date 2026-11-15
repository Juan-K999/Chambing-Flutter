import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../models/propuesta.dart';
import '../../services/servicios.dart';
import '../../widgets/comunes.dart';
import 'login_empresa_screen.dart';
import 'nueva_propuesta_screen.dart';

/// Lista de propuestas de la empresa logueada: publicar, ver y eliminar.
class PropuestasScreen extends StatefulWidget {
  const PropuestasScreen({super.key});

  @override
  State<PropuestasScreen> createState() => _PropuestasScreenState();
}

class _PropuestasScreenState extends State<PropuestasScreen> {
  String? _idEmpresa;
  String _nombreEmpresa = 'Mis propuestas';
  List<Propuesta> _propuestas = [];
  bool _cargando = true;
  String? _error;
  final Set<String> _eliminando = {};

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    _idEmpresa = await sessionStore.idEmpresa;
    _nombreEmpresa = await sessionStore.nombreEmpresa ?? _nombreEmpresa;
    if (_idEmpresa == null) {
      _irAlLogin(const SesionExpirada().mensaje);
      return;
    }
    await _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await propuestaService.listar(_idEmpresa!);
      if (mounted) setState(() => _propuestas = lista);
    } on SesionExpirada catch (e) {
      _irAlLogin(e.mensaje);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _irAlLogin(String mensaje) {
    if (!mounted) return;
    mostrarMensaje(context, mensaje);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginEmpresaScreen()),
      (ruta) => ruta.isFirst,
    );
  }

  Future<void> _nueva() async {
    final creada = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => NuevaPropuestaScreen(idEmpresa: _idEmpresa!)));
    if (creada == true) await _cargar();
  }

  Future<void> _eliminar(Propuesta p) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar propuesta'),
        content: Text('¿Seguro que quieres eliminar "${p.titulo}"? '
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final id = p.idPropuesta!;
    setState(() => _eliminando.add(id));
    try {
      await propuestaService.eliminar(_idEmpresa!, id);
      if (!mounted) return;
      setState(() => _propuestas.removeWhere((x) => x.idPropuesta == id));
      mostrarMensaje(context, 'Propuesta eliminada', error: false);
    } on SesionExpirada catch (e) {
      _irAlLogin(e.mensaje);
    } catch (e) {
      if (mounted) mostrarMensaje(context, mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _eliminando.remove(id));
    }
  }

  Future<void> _cerrarSesion() async {
    await authService.cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nombreEmpresa),
        actions: [
          IconButton(
              tooltip: 'Recargar',
              onPressed: _cargando ? null : _cargar,
              icon: const Icon(Icons.refresh)),
          IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: _idEmpresa == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _nueva,
              icon: const Icon(Icons.add),
              label: const Text('Nueva propuesta'),
            ),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando && _propuestas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _propuestas.isEmpty) {
      return ErrorView(mensaje: _error!, onReintentar: _cargar);
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: _propuestas.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              Icon(Icons.inbox_outlined, size: 56),
              SizedBox(height: 12),
              Center(child: Text('Aún no tienes propuestas publicadas.')),
              Center(child: Text('Usa "Nueva propuesta" para crear la primera.')),
            ])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _propuestas.length,
              itemBuilder: (_, i) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _Tarjeta(
                    propuesta: _propuestas[i],
                    eliminando: _eliminando.contains(_propuestas[i].idPropuesta),
                    onEliminar: () => _eliminar(_propuestas[i]),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.propuesta,
    required this.eliminando,
    required this.onEliminar,
  });

  final Propuesta propuesta;
  final bool eliminando;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final p = propuesta;
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(p.titulo, style: tema.textTheme.titleMedium)),
            if (p.estado != null) Chip(label: Text(p.estado!)),
            const SizedBox(width: 4),
            eliminando
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    tooltip: 'Eliminar',
                    onPressed: onEliminar,
                    icon: Icon(Icons.delete_outline, color: tema.colorScheme.error)),
          ]),
          Wrap(spacing: 16, runSpacing: 4, children: [
            if (p.categoria.isNotEmpty)
              _Dato(icono: Icons.category_outlined, texto: p.categoria),
            _Dato(
                icono: Icons.payments_outlined,
                texto: p.salario == null
                    ? 'Salario a convenir'
                    : '\$ ${formatearMiles(p.salario!)}'),
          ]),
          if (p.descripcion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.descripcion, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(texto),
      ]);
}

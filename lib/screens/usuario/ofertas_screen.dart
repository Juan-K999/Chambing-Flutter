import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../models/postulacion.dart';
import '../../models/propuesta.dart';
import '../../services/servicios.dart';
import '../../widgets/comunes.dart';
import 'login_usuario_screen.dart';

/// Panel del usuario logueado: ver ofertas, postularse y seguir el estado
/// de sus postulaciones.
class OfertasScreen extends StatefulWidget {
  const OfertasScreen({super.key});

  @override
  State<OfertasScreen> createState() => _OfertasScreenState();
}

class _OfertasScreenState extends State<OfertasScreen> {
  String? _idUsuario;
  String _nombre = 'Ofertas';

  List<Propuesta> _ofertas = [];
  List<Postulacion> _postulaciones = [];

  /// Texto en minúscula de cada oferta, para buscar sin recalcularlo.
  List<String> _indice = [];
  List<String> _categorias = [];
  List<Propuesta> _filtradas = [];
  Map<String, Postulacion> _porPropuesta = {};
  bool _cargando = true;
  String? _error;
  final Set<String> _aplicando = {};

  final _busqueda = TextEditingController();
  String _ultimaBusqueda = '';
  String? _categoria;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(_alEscribir);
    _iniciar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  void _alEscribir() {
    if (_busqueda.text == _ultimaBusqueda) return; // solo cambió el cursor
    _ultimaBusqueda = _busqueda.text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(_filtrar);
    });
  }

  void _indexar() {
    _indice = [
      for (final p in _ofertas)
        '${p.titulo} ${p.empresaNombre ?? ''} ${p.categoria} ${p.descripcion}'
            .toLowerCase(),
    ];
    _categorias = {
      for (final p in _ofertas)
        if (p.categoria.isNotEmpty) p.categoria,
    }.toList()
      ..sort();
    if (!_categorias.contains(_categoria)) _categoria = null;
    _indexarPostulaciones();
    _filtrar();
  }

  void _indexarPostulaciones() =>
      _porPropuesta = {for (final po in _postulaciones) po.propuestaId: po};

  void _filtrar() {
    final q = _busqueda.text.trim().toLowerCase();
    _filtradas = [
      for (var i = 0; i < _ofertas.length; i++)
        if ((_categoria == null || _ofertas[i].categoria == _categoria) &&
            (q.isEmpty || _indice[i].contains(q)))
          _ofertas[i],
    ];
  }

  Future<void> _iniciar() async {
    _idUsuario = await sessionStore.idUsuario;
    _nombre = await sessionStore.nombreUsuario ?? _nombre;
    if (_idUsuario == null) {
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
      final ofertas = postulacionService.ofertas();
      final postulaciones = postulacionService.misPostulaciones(_idUsuario!);
      final o = await ofertas;
      final p = await postulaciones;
      if (!mounted) return;
      setState(() {
        _ofertas = o;
        _postulaciones = p;
        _indexar();
      });
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
      MaterialPageRoute(builder: (_) => const LoginUsuarioScreen()),
      (ruta) => ruta.isFirst,
    );
  }

  Future<void> _cerrarSesion() async {
    await authService.cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  Postulacion? _postulacionDe(Propuesta p) => _porPropuesta[p.idPropuesta];

  Future<void> _aplicar(Propuesta p) async {
    final id = p.idPropuesta!;
    if (_aplicando.contains(id)) return;
    setState(() => _aplicando.add(id));
    try {
      final nueva = await postulacionService.aplicar(_idUsuario!, id);
      if (!mounted) return;
      setState(() {
        _postulaciones.insert(0, nueva);
        _indexarPostulaciones();
      });
      mostrarMensaje(context, 'Te postulaste a "${p.titulo}"', error: false);
    } on SesionExpirada catch (e) {
      _irAlLogin(e.mensaje);
    } catch (e) {
      if (!mounted) return;
      mostrarMensaje(context, mensajeDeError(e));
      // Puede que ya estuviera postulado desde la web o que la oferta
      // se haya borrado: sincronizamos con el servidor.
      if (e is Validacion || e is NoEncontrado) await _cargar();
    } finally {
      if (mounted) setState(() => _aplicando.remove(id));
    }
  }

  void _verDetalle(Propuesta p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (ctx) => _Detalle(
        propuesta: p,
        postulacion: _postulacionDe(p),
        onAplicar: () {
          Navigator.pop(ctx);
          _aplicar(p);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sinDatos = _ofertas.isEmpty && _postulaciones.isEmpty;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_nombre),
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
          bottom: TabBar(tabs: [
            const Tab(icon: Icon(Icons.work_outline), text: 'Ofertas'),
            Tab(
              icon: const Icon(Icons.assignment_turned_in_outlined),
              text: 'Mis postulaciones (${_postulaciones.length})',
            ),
          ]),
        ),
        body: _cargando && sinDatos
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Cargando ofertas… puede tardar unos segundos.'),
                ]),
              )
            : _error != null && sinDatos
                ? ErrorView(mensaje: _error!, onReintentar: _cargar)
                : TabBarView(children: [_tabOfertas(), _tabPostulaciones()]),
      ),
    );
  }

  Widget _tabOfertas() {
    final lista = _filtradas;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(child: _Centrado(child: _filtros(lista.length))),
        ),
        if (lista.isEmpty)
          SliverToBoxAdapter(
            child: _Vacio(
              icono: Icons.search_off,
              texto: _ofertas.isEmpty
                  ? 'Todavía no hay ofertas publicadas.'
                  : 'No se encontraron ofertas con ese criterio.',
            ),
          )
        else
          // Lista perezosa: solo se construyen las tarjetas visibles.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.builder(
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final p = lista[i];
                return _Centrado(
                  child: _TarjetaOferta(
                    propuesta: p,
                    postulacion: _postulacionDe(p),
                    aplicando: _aplicando.contains(p.idPropuesta),
                    onTap: () => _verDetalle(p),
                    onAplicar: () => _aplicar(p),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }

  Widget _filtros(int total) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: _busqueda,
        decoration: InputDecoration(
          hintText: 'Buscar por cargo, empresa o palabra clave',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          suffixIcon: _busqueda.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar',
                  onPressed: _busqueda.clear,
                  icon: const Icon(Icons.close)),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String?>(
        // La key fuerza a redibujar si la categoría se reinicia al recargar.
        key: ValueKey(_categoria),
        initialValue: _categoria,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Categoría',
          prefixIcon: Icon(Icons.category_outlined),
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
          for (final c in _categorias) DropdownMenuItem(value: c, child: Text(c)),
        ],
        onChanged: (c) => setState(() {
          _categoria = c;
          _filtrar();
        }),
      ),
      const SizedBox(height: 8),
      Text(
        '${formatearMiles(total)} '
        '${total == 1 ? 'oferta encontrada' : 'ofertas encontradas'}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
    ]);
  }

  Widget _tabPostulaciones() {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: _postulaciones.isEmpty
          ? ListView(children: const [
              _Vacio(
                icono: Icons.inbox_outlined,
                texto: 'Aún no te has postulado a ninguna oferta.',
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _postulaciones.length,
              itemBuilder: (_, i) =>
                  _Centrado(child: _TarjetaPostulacion(_postulaciones[i])),
            ),
    );
  }
}

// ── Piezas de la pantalla ───────────────────────────────────────────────────

class _Centrado extends StatelessWidget {
  const _Centrado({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760), child: child),
      );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(children: [
          Icon(icono, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
        ]),
      );
}

String _salario(Propuesta p) => p.salario == null
    ? 'Salario a convenir'
    : '\$ ${formatearMiles(p.salario!)}';

class _Datos extends StatelessWidget {
  const _Datos(this.propuesta);

  final Propuesta propuesta;

  @override
  Widget build(BuildContext context) {
    final p = propuesta;
    return Wrap(spacing: 16, runSpacing: 4, children: [
      _Dato(
          icono: Icons.business_outlined,
          texto: p.empresaNombre ?? 'Empresa confidencial'),
      if (p.categoria.isNotEmpty)
        _Dato(icono: Icons.category_outlined, texto: p.categoria),
      _Dato(icono: Icons.payments_outlined, texto: _salario(p)),
    ]);
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Flexible(child: Text(texto)),
      ]);
}

/// Botón de postularse, o el estado si ya se postuló / la oferta cerró.
class _BotonAplicar extends StatelessWidget {
  const _BotonAplicar({
    required this.propuesta,
    required this.postulacion,
    required this.aplicando,
    required this.onAplicar,
  });

  final Propuesta propuesta;
  final Postulacion? postulacion;
  final bool aplicando;
  final VoidCallback onAplicar;

  @override
  Widget build(BuildContext context) {
    if (postulacion != null) return _EstadoChip(postulacion!.estado);
    if (propuesta.cerrada) {
      return const FilledButton(onPressed: null, child: Text('Cerrada'));
    }
    return FilledButton.icon(
      onPressed: aplicando ? null : onAplicar,
      icon: aplicando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.send),
      label: Text(aplicando ? 'Enviando…' : 'Postularme'),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip(this.estado);

  final String estado;

  @override
  Widget build(BuildContext context) {
    final (color, icono) = switch (estado) {
      'Aprobado' => (Colors.green.shade700, Icons.check_circle_outline),
      'Rechazado' => (Theme.of(context).colorScheme.error, Icons.cancel_outlined),
      _ => (Colors.orange.shade800, Icons.schedule),
    };
    return Chip(
      avatar: Icon(icono, color: color, size: 18),
      label: Text(estado, style: TextStyle(color: color)),
      side: BorderSide(color: color),
    );
  }
}

class _TarjetaOferta extends StatelessWidget {
  const _TarjetaOferta({
    required this.propuesta,
    required this.postulacion,
    required this.aplicando,
    required this.onTap,
    required this.onAplicar,
  });

  final Propuesta propuesta;
  final Postulacion? postulacion;
  final bool aplicando;
  final VoidCallback onTap;
  final VoidCallback onAplicar;

  @override
  Widget build(BuildContext context) {
    final p = propuesta;
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.titulo,
                style: tema.textTheme.titleMedium
                    ?.copyWith(color: tema.colorScheme.primary)),
            const SizedBox(height: 4),
            _Datos(p),
            if (p.descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(p.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(children: [
              TextButton(onPressed: onTap, child: const Text('Ver detalle')),
              const Spacer(),
              _BotonAplicar(
                propuesta: p,
                postulacion: postulacion,
                aplicando: aplicando,
                onAplicar: onAplicar,
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({
    required this.propuesta,
    required this.postulacion,
    required this.onAplicar,
  });

  final Propuesta propuesta;
  final Postulacion? postulacion;
  final VoidCallback onAplicar;

  @override
  Widget build(BuildContext context) {
    final p = propuesta;
    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.titulo,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                _Datos(p),
                const Seccion('Descripción'),
                Text(p.descripcion.isEmpty
                    ? 'Sin descripción.'
                    : p.descripcion),
                const Seccion('Requisitos'),
                Text(p.requisitos.isEmpty
                    ? 'Sin requisitos especificados.'
                    : p.requisitos),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: _BotonAplicar(
                    propuesta: p,
                    postulacion: postulacion,
                    aplicando: false,
                    onAplicar: onAplicar,
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}

class _TarjetaPostulacion extends StatelessWidget {
  const _TarjetaPostulacion(this.postulacion);

  final Postulacion postulacion;

  static String _dos(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final po = postulacion;
    final f = po.fecha;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(child: Icon(Icons.work_outline)),
        title: Text(po.propuestaTitulo),
        subtitle: Text(f == null
            ? 'Fecha no disponible'
            : 'Postulado el ${_dos(f.day)}/${_dos(f.month)}/${f.year} '
                'a las ${_dos(f.hour)}:${_dos(f.minute)}'),
        trailing: _EstadoChip(po.estado),
      ),
    );
  }
}

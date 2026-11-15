import 'package:flutter/material.dart';

import 'empresa/login_empresa_screen.dart';
import 'empresa/registro_empresa_screen.dart';
import 'usuario/login_usuario_screen.dart';
import 'usuario/registro_usuario_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.work_outline, size: 64, color: tema.colorScheme.primary),
                const SizedBox(height: 8),
                Text('Chambing',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tema.colorScheme.primary)),
                const SizedBox(height: 4),
                Text('Conectamos empresas con talento',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyLarge),
                const SizedBox(height: 32),
                _Opcion(
                  icono: Icons.login,
                  titulo: 'Soy empresa: iniciar sesión',
                  subtitulo: 'Publica y administra tus propuestas',
                  destino: const LoginEmpresaScreen(),
                ),
                _Opcion(
                  icono: Icons.business,
                  titulo: 'Registrar empresa',
                  subtitulo: 'Crea la cuenta de tu empresa',
                  destino: const RegistroEmpresaScreen(),
                ),
                _Opcion(
                  icono: Icons.person_outline,
                  titulo: 'Soy usuario: iniciar sesión',
                  subtitulo: 'Busca ofertas y postúlate',
                  destino: const LoginUsuarioScreen(),
                ),
                _Opcion(
                  icono: Icons.person_add_alt,
                  titulo: 'Registrar usuario',
                  subtitulo: 'Crea tu cuenta para postularte',
                  destino: const RegistroUsuarioScreen(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.destino,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Widget destino;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(child: Icon(icono)),
        title: Text(titulo),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => destino)),
      ),
    );
  }
}

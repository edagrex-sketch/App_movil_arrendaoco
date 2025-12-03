import 'package:flutter/material.dart';

import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/view/login.dart';
import 'package:arrendaoco/view/arrendador.dart';
import 'package:arrendaoco/view/registrar_inmueble.dart';
import 'package:arrendaoco/model/sesion_actual.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MiTema.blanco,
        title: Text(
          'Cerrar sesión',
          style: TextStyle(color: MiTema.azul),
        ),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: MiTema.azul),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: MiTema.rojo,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      // Limpiar sesión
      SesionActual.usuarioId = null;
      SesionActual.nombre = null;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = SesionActual.nombre ?? 'Usuario';
    final username = nombre; // puedes separar nombre/username si quieres

    return Container(
      color: MiTema.crema,
      child: CustomScrollView(
        slivers: [
          // Encabezado del perfil
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              decoration: BoxDecoration(
                color: MiTema.azul,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: MiTema.crema,
                    child: Icon(Icons.person, size: 60, color: MiTema.azul),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nombre,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: MiTema.crema,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 14,
                      color: MiTema.crema.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Estadísticas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite_outline,
                      title: 'Favoritos',
                      value: '0',
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.home_outlined,
                      title: 'Publicados',
                      value: '0',
                      color: MiTema.vino,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.mail_outline,
                      title: 'Mensajes',
                      value: '0',
                      color: MiTema.celeste,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Sección: Mis publicaciones
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis publicaciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MiTema.azul,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Publicar
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.add_home_work_outlined,
                          label: 'Publicar',
                          bgColor: MiTema.celeste,
                          onTap: () {
                            final propietarioId = SesionActual.usuarioId ?? 1;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RegistrarInmuebleScreen(
                                  propietarioId: propietarioId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Ver todas
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.list_outlined,
                          label: 'Ver todas',
                          bgColor: MiTema.vino,
                          onTap: () {
                            final usuarioId = SesionActual.usuarioId ?? 1;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ArrendadorScreen(usuarioId: usuarioId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Sección: Cuenta
          SliverToBoxAdapter(
            child: _SectionCard(
              title: 'Cuenta',
              headerColor: MiTema.azul,
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Editar perfil',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Pantalla de editar perfil (pendiente)'),
                      ),
                    );
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Sección: Preferencias
          SliverToBoxAdapter(
            child: _SectionCard(
              title: 'Preferencias',
              headerColor: MiTema.azul,
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Configuración de notificaciones pendiente',
                          ),
                        ),
                      );
                    },
                    activeColor: MiTema.celeste,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tema oscuro',
                  trailing: Switch(
                    value: false,
                    onChanged: (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Tema oscuro aún no implementado'),
                        ),
                      );
                    },
                    activeColor: MiTema.celeste,
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Sección: Soporte
          SliverToBoxAdapter(
            child: _SectionCard(
              title: 'Soporte',
              headerColor: MiTema.azul,
              children: [
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Centro de ayuda',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Centro de ayuda próximamente'),
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'Acerca de ArrendaOco',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'ArrendaOco',
                      applicationVersion: '1.0.0',
                      applicationIcon:
                          Icon(Icons.home, color: MiTema.azul),
                      children: const [
                        Text('Aplicación para renta de inmuebles.'),
                      ],
                    );
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Botón Cerrar sesión
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _cerrarSesion(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MiTema.rojo,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ================= Widgets auxiliares =================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MiTema.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const SizedBox(height: 2),
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color headerColor;

  const _SectionCard({
    required this.title,
    required this.children,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MiTema.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(158, 158, 158, 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MiTema.crema,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: MiTema.azul),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing:
              trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
          onTap: onTap,
          visualDensity: const VisualDensity(vertical: -1),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(color: Colors.grey.shade200),
          ),
      ],
    );
  }
}

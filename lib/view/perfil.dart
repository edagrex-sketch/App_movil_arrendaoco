import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/view/login.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      // Limpiar datos y volver al login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Encabezado del perfil
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            color: MiTema.vino,
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: MiTema.crema,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: MiTema.vino,
                  ),
                ),
                const SizedBox(height: 16),

                // Nombre y email
                Text(
                  'Juan Pérez',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MiTema.crema,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'juan.perez@email.com',
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
                    value: '12',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.home_outlined,
                    title: 'Publicados',
                    value: '5',
                    color: MiTema.vino,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.mail_outline,
                    title: 'Mensajes',
                    value: '8',
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
                    color: MiTema.vino,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.add_home_work_outlined,
                        label: 'Publicar',
                        bgColor: MiTema.vino,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.list_outlined,
                        label: 'Ver todas',
                        bgColor: MiTema.celeste,
                        onTap: () {},
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
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Editar perfil',
                onTap: () {},
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
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: MiTema.celeste,
                ),
              ),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Tema oscuro',
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
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
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Centro de ayuda',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Acerca de ArrendaOco',
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Botón Cerrar sesión
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _cerrarSesion(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }
}

// Widget para tarjeta de estadística
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para botón de acción rápida
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

// Widget para tarjeta de sección
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              color: MiTema.vino,
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

// Widget para elemento de configuración
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
          leading: Icon(icon, color: MiTema.vino),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
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

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/view/login.dart';
import 'package:arrendaoco/view/arrendador.dart';
import 'package:arrendaoco/view/registrar_inmueble.dart';
import 'package:arrendaoco/view/calendario_inquilino.dart';
import 'package:arrendaoco/view/calendario_arrendador.dart';
import 'package:arrendaoco/view/gestionar_rentas.dart';
import 'package:arrendaoco/view/mis_rentas.dart';
import 'package:arrendaoco/view/editar_perfil.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/services/fcm_service.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/services/auth_service.dart';
import 'package:arrendaoco/view/inquilino_home.dart';
import 'dart:async';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  bool _notificacionesActivas = true;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  int _favoritosCount = 0;
  int _inmueblesCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userRes = await _api.get('/me');
      final favsRes = await _api.get('/favoritos');

      int inmueblesCount = 0;
      if (SesionActual.esPropietario) {
        final propsRes = await _api.get('/inmuebles');
        if (propsRes.statusCode == 200) {
          inmueblesCount = (propsRes.data['data'] as List).length;
        }
      }

      if (mounted) {
        setState(() {
          if (userRes.statusCode == 200) {
            _userData = userRes.data['data'];
          }
          if (favsRes.statusCode == 200) {
            _favoritosCount = (favsRes.data['data'] as List).length;
          }
          _inmueblesCount = inmueblesCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error actualizando perfil: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar sesión',
          style: TextStyle(color: MiTema.azul, fontWeight: FontWeight.bold),
        ),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: MiTema.azul)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: MiTema.rojo),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      LottieLoading.showLoadingDialog(context, message: 'Cerrando sesión...');
      await _auth.signOut();

      SesionActual.usuarioId = null;
      SesionActual.nombre = '';
      SesionActual.email = '';
      SesionActual.rol = '';
      SesionActual.todosLosRoles = [];
      SesionActual.publicId = null;

      FCMService.dispose();

      if (context.mounted) {
        LottieLoading.hideLoadingDialog(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: Colors.white),
                  );
                }

                String? fotoPerfilUrl = _userData?['foto_perfil'];
                String displayName =
                    _userData?['nombre'] ?? SesionActual.nombre;

                // Sync singleton
                SesionActual.nombre = displayName;

                return Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                fotoPerfilUrl != null &&
                                    fotoPerfilUrl.isNotEmpty
                                ? NetworkImage(fotoPerfilUrl)
                                : null,
                            child:
                                (fotoPerfilUrl == null || fotoPerfilUrl.isEmpty)
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 60,
                                    color: MiTema.celeste,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName.isEmpty ? 'Usuario' : displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            SesionActual.rol.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.badge_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ID: ${SesionActual.publicId ?? SesionActual.usuarioId ?? "N/A"}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Stats
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite_rounded,
                      title: 'Favoritos',
                      value: '$_favoritosCount',
                      color: MiTema.rojo,
                    ),
                  ),
                  if (SesionActual.esPropietario) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.home_work_rounded,
                        title: 'Publicados',
                        value: '$_inmueblesCount',
                        color: MiTema.vino,
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.chat_bubble_rounded,
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

          // Arrendador Panel
          if (SesionActual.esPropietario)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              sliver: SliverToBoxAdapter(
                child: StunningCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.real_estate_agent_rounded,
                            color: MiTema.azul,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Panel Arrendador',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MiTema.azul,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.add_home_work_rounded,
                              label: 'Publicar',
                              gradient: AppGradients.accentGradient,
                              onTap: () async {
                                final pid = SesionActual.usuarioId ?? '';
                                if (pid.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RegistrarInmuebleScreen(
                                            propietarioId: pid,
                                          ),
                                    ),
                                  );
                                  // No need to manual reload as stream handles it
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.dashboard_customize_rounded,
                              label: 'Gestionar',
                              gradient: AppGradients.primaryGradient,
                              onTap: () {
                                final uid = SesionActual.usuarioId ?? '';
                                if (uid.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ArrendadorScreen(usuarioId: uid),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (SesionActual.esPropietario)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(title: 'CUENTA'),
                StunningCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.person_rounded,
                        title: 'Editar perfil',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditarPerfilScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.key_rounded,
                        title: 'Mis Rentas',
                        onTap: () {
                          if (SesionActual.esPropietario) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GestionarRentasScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MisRentasScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.calendar_month_rounded,
                        title: 'Calendario',
                        showDivider: SesionActual.canSwitchDashboard,
                        onTap: () {
                          if (SesionActual.esPropietario) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CalendarioArrendadorScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CalendarioInquilinoScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      if (SesionActual.canSwitchDashboard)
                        _SettingsTile(
                          icon: Icons.swap_horiz_rounded,
                          title: SesionActual.esPropietario
                              ? 'Cambiar a Dashboard Inquilino'
                              : 'Cambiar a Dashboard Arrendador',
                          showDivider: false,
                          onTap: () {
                            final uid = SesionActual.usuarioId ?? '';
                            if (SesionActual.esPropietario) {
                              // Cambiar a Inquilino
                              SesionActual.rol = 'inquilino';
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InquilinoHomeScreen(usuarioId: uid),
                                ),
                                (route) => false,
                              );
                            } else {
                              // Cambiar a Arrendador
                              SesionActual.rol = SesionActual.todosLosRoles.firstWhere(
                                (r) => r.toLowerCase() == 'arrendador' || r.toLowerCase() == 'propietario' || r.toLowerCase() == 'admin',
                                orElse: () => 'arrendador',
                              );
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ArrendadorScreen(usuarioId: uid),
                                ),
                                (route) => false,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(title: 'PREFERENCIAS'),
                StunningCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_active_rounded,
                        title: 'Notificaciones',
                        trailing: Switch(
                          value: _notificacionesActivas,
                          activeColor: MiTema.celeste,
                          onChanged: (val) {
                            setState(() => _notificacionesActivas = val);
                            if (val) {
                              LottieFeedback.showSuccess(
                                context,
                                message: 'Notificaciones activas',
                              );
                            }
                          },
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.dark_mode_rounded,
                        title: 'Tema Oscuro',
                        showDivider: false,
                        trailing: Switch(
                          value: false,
                          onChanged: (val) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Próximamente...')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(title: 'SOPORTE'),
                StunningCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Centro de Ayuda',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Acerca de ArrendaOco',
                        showDivider: false,
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'ArrendaOco',
                            applicationVersion: '2.0.0 Stunning',
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                StunningButton(
                  onPressed: () => _cerrarSesion(context),
                  text: 'CERRAR SESIÓN',
                  icon: Icons.logout_rounded,
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 100, // Slightly taller
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20), // More rounded
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Stronger shadow
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MiTema.celeste.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              // shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MiTema.celeste, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          trailing:
              trailing ??
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
          onTap: onTap,
        ),
        if (showDivider) Divider(color: Colors.grey[100], indent: 70),
      ],
    );
  }
}

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
import 'package:arrendaoco/services/notificaciones_service.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/services/fcm_service.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/services/auth_service.dart';
import 'package:arrendaoco/view/chats/chat_list_screen.dart';
import 'package:arrendaoco/view/favoritos.dart';
import 'package:arrendaoco/view/inquilino_home.dart';
import 'package:url_launcher/url_launcher.dart';
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
  int _photoVersion = DateTime.now().millisecondsSinceEpoch;
  Map<String, dynamic>? _userData;
  int _favoritosCount = 0;
  int _inmueblesCount = 0;
  int _rentasCount = 0;

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

      int rentasCount = 0;
      final rentasRes = await _api.get('/contratos');
      if (rentasRes.statusCode == 200) {
        rentasCount = (rentasRes.data['data'] as List).length;
      }

      if (mounted) {
        setState(() {
          if (userRes.statusCode == 200) {
            _userData = userRes.data['data'];
            SesionActual.stripeOnboardingCompleted = _userData?['stripe_onboarding_completed'] ?? false;
            _photoVersion = DateTime.now().millisecondsSinceEpoch;
          }
          if (favsRes.statusCode == 200) {
            _favoritosCount = (favsRes.data['data'] as List).length;
          }
          _inmueblesCount = inmueblesCount;
          _rentasCount = rentasCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error actualizando perfil: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ascenderAArrendador() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Conviértete en Arrendador!'),
        content: const Text('¿Deseas activar los privilegios para publicar y gestionar tus propios inmuebles?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ahora no')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MiTema.azul, foregroundColor: Colors.white),
            child: const Text('¡Sí, quiero publicar!'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      LottieLoading.showLoadingDialog(context, message: 'Actualizando privilegios...');
      try {
        final res = await _api.post('/perfil/solicitar-propietario', data: {});
        if (mounted) LottieLoading.hideLoadingDialog(context);

        if (res.statusCode == 200 && res.data['success']) {
          final userData = res.data['user'];
          setState(() {
            SesionActual.rol = userData['rol'] ?? 'arrendador';
            SesionActual.todosLosRoles = List<String>.from(userData['roles'] ?? []);
            SesionActual.stripeOnboardingCompleted = userData['stripe_onboarding_completed'] ?? false;
          });
          
          if (mounted) {
            await LottieFeedback.showSuccess(context, message: res.data['message'] ?? '¡Ya eres arrendador!');
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => InquilinoHomeScreen(usuarioId: SesionActual.usuarioId ?? '')),
                (route) => false,
              );
            }
          }
        } else {
          if (mounted) LottieFeedback.showError(context, message: res.data['message'] ?? 'No se pudo actualizar el rol');
        }
      } catch (e) {
        if (mounted) {
          LottieLoading.hideLoadingDialog(context);
          LottieFeedback.showError(context, message: 'Error de conexión: $e');
        }
      }
    }
  }

  Future<void> _vincularCuentaStripe() async {
    LottieLoading.showLoadingDialog(context, message: 'Generando enlace seguro...');
    try {
      final res = await _api.get('/stripe/onboarding-link');
      if (mounted) LottieLoading.hideLoadingDialog(context);

      if (res.statusCode == 200 && res.data['url'] != null) {
        final url = Uri.parse(res.data['url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          // Mostrar un diálogo para que el usuario verifique cuando regrese
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Configuración en curso'),
                content: const Text('¿Has completado la vinculación en la página de Stripe?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aún no')),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _verificarEstadoStripe();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: MiTema.azul, foregroundColor: Colors.white),
                    child: const Text('Sí, verificar ya'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) LottieFeedback.showError(context, message: 'No se pudo abrir el navegador.');
        }
      }
    } catch (e) {
      if (mounted) {
        LottieLoading.hideLoadingDialog(context);
        LottieFeedback.showError(context, message: 'Error al conectar con Stripe: $e');
      }
    }
  }

  Future<void> _verificarEstadoStripe() async {
    LottieLoading.showLoadingDialog(context, message: 'Verificando con Stripe...');
    try {
      final res = await _api.get('/stripe/check-status');
      if (mounted) LottieLoading.hideLoadingDialog(context);

      if (res.statusCode == 200) {
        final completed = res.data['completed'] ?? false;
        if (completed) {
          setState(() => SesionActual.stripeOnboardingCompleted = true);
          if (mounted) await LottieFeedback.showSuccess(context, message: '¡Cuenta vinculada con éxito!');
        } else {
          if (mounted) LottieFeedback.showError(context, message: 'La configuración parece no estar completa todavía.');
        }
      }
    } catch (e) {
      if (mounted) {
        LottieLoading.hideLoadingDialog(context);
        LottieFeedback.showError(context, message: 'Error de verificación: $e');
      }
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión', style: TextStyle(color: MiTema.azul, fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: MiTema.azul))),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: MiTema.rojo), child: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold))),
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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
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
                  return Container(padding: const EdgeInsets.symmetric(vertical: 80), alignment: Alignment.center, child: CircularProgressIndicator(color: MiTema.azul));
                }

                String? fotoPerfilUrl = _userData?['foto_perfil'];
                if (fotoPerfilUrl != null && fotoPerfilUrl.isNotEmpty) {
                  fotoPerfilUrl = '$fotoPerfilUrl?v=$_photoVersion';
                }
                String displayName = _userData?['nombre'] ?? SesionActual.nombre;
                SesionActual.nombre = displayName;

                return Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: fotoPerfilUrl != null && fotoPerfilUrl.isNotEmpty ? NetworkImage(fotoPerfilUrl) : null,
                            child: (fotoPerfilUrl == null || fotoPerfilUrl.isEmpty) ? Icon(Icons.person_rounded, size: 60, color: MiTema.celeste) : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(displayName.isEmpty ? 'Usuario' : displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                          child: Text(SesionActual.esPropietario ? 'INQUILINO / ARRENDADOR' : SesionActual.rol.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _StatCard(icon: Icons.favorite_rounded, title: 'Favoritos', value: '$_favoritosCount', color: MiTema.rojo, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Mis Favoritos'), flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryGradient))),
                      body: FavoritosScreen(),
                    )));
                  })),
                  const SizedBox(width: 12),
                  if (SesionActual.esPropietario) ...[
                    Expanded(child: _StatCard(icon: Icons.home_work_rounded, title: 'Publicados', value: '$_inmueblesCount', color: MiTema.vino)),
                  ] else ...[
                    Expanded(child: _StatCard(icon: Icons.key_rounded, title: 'Rentas', value: '$_rentasCount', color: MiTema.vino, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                        appBar: AppBar(title: const Text('Mis Rentas'), flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryGradient))),
                        body: const MisRentasScreen(),
                      )));
                    })),
                  ],
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(icon: Icons.chat_bubble_rounded, title: 'Mensajes', value: '0', color: MiTema.celeste, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Mensajes'), flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryGradient))),
                      body: ChatListScreen(),
                    )));
                  })),
                ],
              ),
            ),
          ),
          if (!SesionActual.esPropietario)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: StunningCard(
                    onTap: _ascenderAArrendador,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.campaign_rounded, color: Colors.red),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('¿Quieres ser arrendador?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Publica tus inmuebles y gestiona rentas.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          if (SesionActual.esPropietario)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (!SesionActual.stripeOnboardingCompleted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF003049), Color(0xFF002030)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF003049).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20,
                                  top: -20,
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 150,
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 24),
                                          ),
                                          const SizedBox(width: 15),
                                          const Expanded(
                                            child: Text(
                                              '¡Configuración pendiente!',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Necesitas vincular una cuenta bancaria con Stripe para recibir tus pagos. Sin esto, no podrás publicar inmuebles.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _vincularCuentaStripe,
                                          icon: const Icon(Icons.link_rounded),
                                          label: const Text('VINCULAR CUENTA AHORA', style: TextStyle(fontWeight: FontWeight.w900)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFC1121F),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    StunningCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Icon(Icons.real_estate_agent_rounded, color: MiTema.azul), const SizedBox(width: 12), Text('Panel Arrendador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MiTema.azul))]),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _QuickActionButton(icon: Icons.add_home_work_rounded, label: 'Publicar', gradient: SesionActual.stripeOnboardingCompleted ? AppGradients.accentGradient : const LinearGradient(colors: [Colors.grey, Colors.blueGrey]), onTap: () async {
                                if (!SesionActual.stripeOnboardingCompleted) {
                                  _vincularCuentaStripe();
                                  return;
                                }
                                final pid = SesionActual.usuarioId ?? '';
                                if (pid.isNotEmpty) {
                                  final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrarInmuebleScreen(propietarioId: pid)));
                                  if (res == true) _refreshData();
                                }
                              })),
                              const SizedBox(width: 12),
                              Expanded(child: _QuickActionButton(icon: Icons.dashboard_customize_rounded, label: 'Gestionar', gradient: AppGradients.primaryGradient, onTap: () {
                                final uid = SesionActual.usuarioId ?? '';
                                if (uid.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (context) => ArrendadorScreen(usuarioId: uid)));
                              })),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(title: 'CUENTA'),
                StunningCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(icon: Icons.person_rounded, title: 'Editar perfil', onTap: () async {
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditarPerfilScreen()));
                        if (res == true) _refreshData();
                      }),
                      _SettingsTile(icon: Icons.key_rounded, title: 'Mi Renta', onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                          appBar: AppBar(title: const Text('Mi Renta'), flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryGradient))),
                          body: const MisRentasScreen(),
                        )));
                      }),
                      _SettingsTile(icon: Icons.favorite_rounded, title: 'Favoritos', onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                          appBar: AppBar(title: const Text('Mis Favoritos'), flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryGradient))),
                          body: FavoritosScreen(),
                        )));
                      }),
                      _SettingsTile(icon: Icons.chat_bubble_rounded, title: 'Mensajes', showDivider: SesionActual.esPropietario, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                          appBar: AppBar(title: const Text('Mensajes'), flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryGradient))),
                          body: ChatListScreen(),
                        )));
                      }),
                      if (SesionActual.esPropietario)
                         _SettingsTile(icon: Icons.assignment_rounded, title: 'Gestión de Rentas', showDivider: false, onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => GestionarRentasScreen()));
                         }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'PREFERENCIAS'),
                StunningCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(icon: Icons.notifications_active_rounded, title: 'Notificaciones', showDivider: true, trailing: Switch(value: _notificacionesActivas, activeColor: MiTema.celeste, onChanged: (v) => setState(() => _notificacionesActivas = v))),
                      _SettingsTile(
                        icon: Icons.notification_important_rounded, 
                        title: 'Probar Notificación 🔔', 
                        showDivider: false, 
                        onTap: () async {
                          await NotificacionesService.mostrarNotificacion(
                            titulo: 'ArrendaOco Test',
                            cuerpo: '¡Funciona! Esta es una notificación de alta prioridad tipo WhatsApp.',
                            groupKey: 'test_group',
                          );
                        }
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
                      _SettingsTile(icon: Icons.help_outline_rounded, title: 'Centro de Ayuda', onTap: () {}),
                      _SettingsTile(icon: Icons.info_outline_rounded, title: 'Acerca de ArrendaOco', showDivider: false, onTap: () => showAboutDialog(context: context, applicationName: 'ArrendaOco', applicationVersion: '2.0.0')),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                StunningButton(onPressed: () => _cerrarSesion(context), text: 'CERRAR SESIÓN', icon: Icons.logout_rounded),
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
  final VoidCallback? onTap;
  const _StatCard({required this.icon, required this.title, required this.value, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)), Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600))])));
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.gradient, required this.onTap});
  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTapDown: (_) => _controller.forward(), onTapUp: (_) { _controller.reverse(); widget.onTap(); }, onTapCancel: () => _controller.reverse(), child: ScaleTransition(scale: _scale, child: Container(height: 100, decoration: BoxDecoration(gradient: widget.gradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(widget.icon, color: Colors.white, size: 32), const SizedBox(height: 8), Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]))));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8, left: 8), child: Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  const _SettingsTile({required this.icon, required this.title, this.trailing, this.onTap, this.showDivider = true});
  @override
  Widget build(BuildContext context) {
    return Column(children: [ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: MiTema.celeste.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: MiTema.celeste, size: 22)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]), onTap: onTap), if (showDivider) Divider(color: Colors.grey[100], indent: 70)]);
  }
}

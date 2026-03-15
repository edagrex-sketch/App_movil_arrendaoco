import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arrendaoco/view/SeleccionarRolScreen.dart';
import 'package:arrendaoco/view/arrendador.dart';
import 'package:arrendaoco/view/inquilino_home.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/services/auth_service.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/services/fcm_service.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/theme/arrenda_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    // Pequeño delay para que la animación se vea
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final session = await _authService.checkSession();
    if (session != null && mounted) {
      SesionActual.usuarioId = session['id'];
      SesionActual.nombre = session['nombre'] ?? '';
      SesionActual.email = session['email'] ?? '';
      SesionActual.rol = session['rol'] ?? 'inquilino';
      SesionActual.todosLosRoles = List<String>.from(session['roles'] ?? []);
      SesionActual.publicId = session['public_id'];

      _navigateByUserRole(SesionActual.rol, SesionActual.usuarioId!);
    }
  }

  void _navigateByUserRole(String role, String userId) {
    final uid = int.tryParse(userId) ?? 0;
    if (uid > 0) FCMService.initialize(uid);

    final normalizedRole = role.toLowerCase().trim();

    // En el seeder es 'propietario' y 'admin'. En el registro es 'arrendador'.
    // Aceptamos cualquier variante para ir al dashboard de gestión.
    final isLandlord =
        normalizedRole == 'arrendador' ||
        normalizedRole == 'propietario' ||
        normalizedRole == 'admin' ||
        normalizedRole == 'administrador';

    if (isLandlord) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ArrendadorScreen(usuarioId: userId),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InquilinoHomeScreen(usuarioId: userId),
        ),
      );
    }
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!mounted) return;
    LottieLoading.showLoadingDialog(context, message: 'Iniciando sesión...');

    try {
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);

      if (result['success']) {
        final userData = result['userData'] as Map<String, dynamic>;

        SesionActual.usuarioId =
            userData['id']?.toString() ?? result['user']?.uid;
        SesionActual.nombre = userData['nombre'] ?? '';
        SesionActual.email = userData['email'] ?? '';
        SesionActual.rol = userData['rol'] ?? 'inquilino';
        SesionActual.todosLosRoles = List<String>.from(userData['roles'] ?? []);
        SesionActual.publicId = userData['public_id'];

        if (SesionActual.usuarioId != null) {
          _navigateByUserRole(SesionActual.rol, SesionActual.usuarioId!);
        }
      } else {
        await LottieFeedback.showError(
          context,
          message: result['message'] ?? 'Error al iniciar sesión',
        );
      }
    } catch (e) {
      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);
      await LottieFeedback.showError(
        context,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Ingresa tu email para restablecer la contraseña',
          ),
          backgroundColor: MiTema.azul,
        ),
      );
      return;
    }

    LottieLoading.showLoadingDialog(context, message: 'Enviando email...');

    final result = await _authService.resetPassword(email);

    if (!mounted) return;
    LottieLoading.hideLoadingDialog(context);

    if (result['success']) {
      await LottieFeedback.showSuccess(
        context,
        message: 'Email de recuperación enviado',
      );
    } else {
      await LottieFeedback.showError(
        context,
        message: result['message'] ?? 'Error al enviar email',
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArrendaColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.surfaceGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with subtle glow or shadow effect
                    // Logo
                    Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            // Eliminamos shape circular para ver el logo completo
                            borderRadius: BorderRadius.circular(20),
                            // box shadow opcional, lo mantenemos sutil
                          ),
                          child: Image.asset(
                            'assets/icon/logo.png',
                            height: 120,
                            fit: BoxFit.contain, // Asegura que se vea completo
                            errorBuilder: (ctx, err, stack) => Icon(
                              Icons.home_work_rounded,
                              size: 100,
                              color: MiTema.azul,
                            ),
                          ),
                        )
                        .animate()
                        .rotate(
                          begin: -0.5,
                          end: 0,
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                        ) // Swing in
                        .scale(begin: const Offset(0.5, 0.5), duration: 800.ms)
                        .fadeIn(duration: 500.ms),
                    const SizedBox(height: 30),

                    StunningCard(
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: [
                                Text(
                                  'Bienvenido de nuevo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: MiTema.azul,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Inicia sesión para continuar',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                StunningTextField(
                                  controller: emailController,
                                  label: 'Email',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa tu email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Email inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                StunningTextField(
                                  controller: passwordController,
                                  label: 'Contraseña',
                                  icon: Icons.lock_rounded,
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingresa tu contraseña';
                                    }
                                    return null;
                                  },
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: resetPassword,
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        color: MiTema.azul,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                StunningButton(
                                  onPressed: login,
                                  text: 'INICIAR SESIÓN',
                                  icon: Icons.login_rounded,
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.2, curve: Curves.easeOutCubic)
                        .blurXY(begin: 10, end: 0), // Blur shift

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          StunningPageRoute(page: const SeleccionarRolScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: '¿No tienes cuenta? ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: 'Regístrate',
                              style: TextStyle(
                                color: MiTema.vino,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                    const SizedBox(height: 20),

                    // Botón de configuración de servidor (Debug/Dev)
                    Opacity(
                      opacity: 0.6,
                      child: TextButton.icon(
                        onPressed: () => _showServerConfig(context),
                        icon: const Icon(Icons.settings_remote_rounded, size: 18),
                        label: const Text('Configurar Servidor'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showServerConfig(BuildContext context) {
    final controller = TextEditingController(text: _authService.currentBaseUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa la URL base de tu servidor Laravel:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.107:8003/api',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Emulador: http://10.0.2.2:8003/api\n• WiFi: http://tu-ip:8003/api',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.updateBaseUrl(controller.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Servidor actualizado correctamente')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

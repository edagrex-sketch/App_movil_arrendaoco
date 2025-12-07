import 'package:flutter/material.dart';
import 'package:arrendaoco/view/SeleccionarRolScreen.dart';
import 'package:arrendaoco/view/arrendador.dart';
import 'package:arrendaoco/view/inquilino_home.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/services/auth_service.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/services/fcm_service.dart';

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

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Mostrar loading
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
        final user = result['user'];

        // GUARDAR SESIÓN
        SesionActual.usuarioId = user.uid;
        SesionActual.nombre = userData['nombre'] ?? '';
        SesionActual.email = userData['email'] ?? '';
        SesionActual.rol = userData['rol'] ?? 'Inquilino';
        SesionActual.publicId = userData['public_id'];

        // Navegar según el rol
        if (SesionActual.rol == 'Arrendador') {
          // Inicializar notificaciones realtime
          if (SesionActual.usuarioId != null) {
            final uid = int.tryParse(SesionActual.usuarioId!) ?? 0;
            if (uid > 0) FCMService.initialize(uid);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ArrendadorScreen(usuarioId: user.uid),
            ),
          );
        } else {
          // Inicializar notificaciones realtime
          if (SesionActual.usuarioId != null) {
            final uid = int.tryParse(SesionActual.usuarioId!) ?? 0;
            if (uid > 0) FCMService.initialize(uid);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InquilinoHomeScreen(usuarioId: user.uid),
            ),
          );
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
        const SnackBar(content: Text('Ingresa tu usuario o email primero')),
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
      appBar: AppBar(
        backgroundColor: MiTema.azul,
        title: Text('Iniciar sesión', style: TextStyle(color: MiTema.crema)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset('assets/images/logo.png', height: 100),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu email';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
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
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MiTema.celeste,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeleccionarRolScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '¿No tienes cuenta? Regístrate!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

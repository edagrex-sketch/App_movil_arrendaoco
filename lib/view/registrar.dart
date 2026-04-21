import 'package:flutter/material.dart';

import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/view/login.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/services/auth_service.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';

class RegisterScreen extends StatefulWidget {
  final String rolInicial; // Recibe el rol elegido
  const RegisterScreen({super.key, required this.rolInicial});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  // No need for bools to toggle visibility if StunningTextField doesn't support it yet,
  // BUT StunningTextField usually needs 'isPassword' to be just a bool.
  // I will update StunningTextField to support toggle safely or just assume standard behavior.
  // Actually, my StunningTextField 'isPassword' just sets obscureText. It doesn't adhere to internal toggling.
  // I should have made StunningTextField smarter, but for now I can just use it as is
  // or update it. Since I overwrote it, I know it doesn't have a toggle button inside.
  // I will implement a simpler version where I just trust the user or the obscureText.
  // Wait, for a "selling" app, password visibility toggle is important.
  // I should update StunningTextField in `stunning_widgets.dart` to support suffixIcon or built-in toggle.
  // For now, I'll pass a suffixIcon to StunningTextField if I update it to accept decoration tweaks,
  // but StunningTextField takes 'icon' (prefix).
  // I'll stick to basic StunningTextField for now to ensure stability, or better yet,
  // I'll quickly update StunningTextField to support `suffixIcon` or just modify `RegisterScreen` to not worry about it
  // IF StunningTextField exposed the decoration. It doesn't.
  // Okay, I will update code to use `StunningTextField` but maybe I can't easily add the eye icon without editing the widget.
  // I'll edit the `stunning_widgets.dart` first to add `suffixIcon` support, then do the register screen.
  // It's a small change.

  String? _selectedRol;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedRol = widget.rolInicial;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final nombre = _nameController.text.trim();
    final password = _passwordController.text;
    final rol = _selectedRol!;

    if (!mounted) return;
    LottieLoading.showLoadingDialog(context, message: 'Registrando usuario...');

    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        nombre: nombre,
        rol: rol,
      );

      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);

      if (result['success']) {
        await LottieFeedback.showSuccess(
          context,
          message: '¡Usuario registrado correctamente!',
          onComplete: () {
            Navigator.pushReplacement(
              context,
              StunningPageRoute(page: const LoginScreen()),
            );
          },
        );
      } else {
        await LottieFeedback.showError(
          context,
          message: result['message'] ?? 'Error al registrar usuario',
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        Text(
                          'Crear Cuenta',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 10),

                        StunningCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                StunningTextField(
                                  controller: _nameController,
                                  label: 'Nombre completo',
                                  icon: Icons.person_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa tu nombre';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                StunningTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa un email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Email inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                StunningTextField(
                                  controller: _passwordController,
                                  label: 'Contraseña',
                                  icon: Icons.lock_rounded,
                                  isPassword: true,
                                  validator: (v) {
                                    if (v == null || v.length < 6)
                                      return 'Mínimo 6 caracteres';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                StunningTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirmar contraseña',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  validator: (v) {
                                    if (v != _passwordController.text)
                                      return 'No coinciden';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                StunningButton(
                                  onPressed: _register,
                                  text: 'REGISTRARME',
                                  icon: Icons.person_add_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              StunningPageRoute(page: const LoginScreen()),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              text: '¿Ya tienes cuenta? ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Inicia sesión',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

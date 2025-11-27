import 'package:arrendaoco/view/SeleccionarRolScreen.dart';
import 'package:flutter/material.dart';
import 'package:arrendaoco/view/arrendador.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();   // username
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final db = await BaseDatos.conecta();

      final res = await db.query(
        'usuarios',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
        limit: 1,
      );

      if (res.isNotEmpty) {
        final usuario = res.first;
        print('ROW USUARIO: $usuario');

        final dynamic idValue = usuario['id'];
        if (idValue == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario sin id en la BD')),
          );
          return;
        }

        int usuarioId;
        if (idValue is int) {
          usuarioId = idValue;
        } else if (idValue is num) {
          usuarioId = idValue.toInt();
        } else if (idValue is String) {
          usuarioId = int.tryParse(idValue) ?? 0;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Tipo inesperado para id: ${idValue.runtimeType}'),
            ),
          );
          return;
        }

        if (usuarioId <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Id de usuario inválido')),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ArrendadorScreen(usuarioId: usuarioId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario o contraseña incorrectos'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MiTema.azul,
        title: Text(
          'Iniciar sesión',
          style: TextStyle(color: MiTema.crema),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
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
                    return 'Por favor ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MiTema.celeste,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
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
                  '¿No tienes cuenta? ¡Regístrate!',
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
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/services/storage_service.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();

  final StorageService _storageService = StorageService();
  File? _nuevaFoto;
  String? _fotoActualUrl;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    if (uid == 0) return;

    try {
      final user = await BaseDatos.obtenerUsuario(uid);
      if (user != null) {
        if (mounted) {
          setState(() {
            _nombreController.text = user['nombre'] ?? '';
            _fotoActualUrl = user['foto_perfil'];
            _cargando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _nuevaFoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    if (uid == 0) return;

    LottieLoading.showLoadingDialog(context, message: 'Actualizando perfil...');

    try {
      String? nuevaUrlFoto;

      if (_nuevaFoto != null) {
        nuevaUrlFoto = await _storageService.uploadProfilePhoto(
          userId: uid.toString(),
          imageFile: _nuevaFoto!,
        );
      }

      final Map<String, dynamic> datos = {
        'nombre': _nombreController.text.trim(),
      };

      if (nuevaUrlFoto != null) {
        datos['foto_perfil'] = nuevaUrlFoto;
      }

      if (_passwordController.text.isNotEmpty) {
        datos['password'] = _passwordController.text;
      }

      await BaseDatos.actualizarUsuario(uid, datos);
      SesionActual.nombre = datos['nombre'];

      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);

      await LottieFeedback.showSuccess(
        context,
        message: '¡Perfil actualizado!',
        onComplete: () {
          Navigator.pop(context, true);
        },
      );
    } catch (e) {
      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);
      await LottieFeedback.showError(context, message: 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator(color: MiTema.celeste)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryGradient,
          ),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            StunningCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _seleccionarFoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: MiTema.celeste.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: _nuevaFoto != null
                                  ? FileImage(_nuevaFoto!)
                                  : (_fotoActualUrl != null &&
                                            _fotoActualUrl!.isNotEmpty
                                        ? NetworkImage(_fotoActualUrl!)
                                              as ImageProvider
                                        : null),
                              child:
                                  (_nuevaFoto == null &&
                                      (_fotoActualUrl == null ||
                                          _fotoActualUrl!.isEmpty))
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 60,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MiTema.celeste,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tu Información',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MiTema.azul,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Nombre
                    StunningTextField(
                      controller: _nombreController,
                      label: 'Nombre completo',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 20),

                    // Contraseña
                    StunningTextField(
                      controller: _passwordController,
                      label: 'Nueva contraseña (opcional)',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    const SizedBox(height: 40),

                    StunningButton(
                      onPressed: _guardarCambios,
                      text: 'GUARDAR CAMBIOS',
                      icon: Icons.save_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

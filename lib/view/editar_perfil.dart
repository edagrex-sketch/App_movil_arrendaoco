import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/services/storage_service.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';

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
            // No cargamos la contraseña por seguridad
            _fotoActualUrl =
                user['foto_perfil']; // Asumiendo campo 'foto_perfil'
            _cargando = false;
          });
        }
      }
    } catch (e) {
      print('Error cargando perfil: $e');
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

      // 1. Subir foto si hay nueva
      if (_nuevaFoto != null) {
        nuevaUrlFoto = await _storageService.uploadProfilePhoto(
          userId: uid.toString(),
          imageFile: _nuevaFoto!,
        );
      }

      // 2. Preparar datos
      final Map<String, dynamic> datos = {
        'nombre': _nombreController.text.trim(),
      };

      if (nuevaUrlFoto != null) {
        datos['foto_perfil'] = nuevaUrlFoto;
      }

      if (_passwordController.text.isNotEmpty) {
        datos['password'] =
            _passwordController.text; // En texto plano por simplicidad actual
      }

      // 3. Guardar en BD
      await BaseDatos.actualizarUsuario(uid, datos);

      // 4. Actualizar sesión local
      SesionActual.nombre = datos['nombre'];

      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);

      await LottieFeedback.showSuccess(
        context,
        message: '¡Perfil actualizado!',
        onComplete: () {
          Navigator.pop(context, true); // Retorna true si hubo cambios
        },
      );
    } catch (e) {
      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);
      await LottieFeedback.showError(
        context,
        message: 'Error al actualizar: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: MiTema.celeste)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Editar Perfil', style: TextStyle(color: MiTema.crema)),
        backgroundColor: MiTema.azul,
        iconTheme: IconThemeData(color: MiTema.crema),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Foto de perfil
              GestureDetector(
                onTap: _seleccionarFoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _nuevaFoto != null
                          ? FileImage(_nuevaFoto!)
                          : (_fotoActualUrl != null
                                ? NetworkImage(_fotoActualUrl!) as ImageProvider
                                : null),
                      child: (_nuevaFoto == null && _fotoActualUrl == null)
                          ? Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: MiTema.celeste,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline, color: MiTema.azul),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 20),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña (opcional)',
                  helperText: 'Deja en blanco para no cambiarla',
                  prefixIcon: Icon(Icons.lock_outline, color: MiTema.azul),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarCambios,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MiTema.celeste,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar cambios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/services/storage_service.dart';
import 'package:arrendaoco/sensors/ubicacion.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arrendaoco/widgets/map_preview_osm.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegistrarInmuebleScreen extends StatefulWidget {
  final String propietarioId;
  final Map<String, dynamic>? inmuebleData;
  final String? inmuebleId;

  const RegistrarInmuebleScreen({
    super.key,
    required this.propietarioId,
    this.inmuebleData,
    this.inmuebleId,
  });

  @override
  State<RegistrarInmuebleScreen> createState() =>
      _RegistrarInmuebleScreenState();
}

class _RegistrarInmuebleScreenState extends State<RegistrarInmuebleScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();

  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();

  bool _disponible = true;
  String? _categoriaSeleccionada;
  int _camas = 1;
  int _banos = 1;
  String _tamano = 'Pequeño';

  final List<String> _categorias = ['Casa', 'Departamento', 'Cuarto'];

  Position? _ubicacionActual;
  String _mensajeUbicacion = '';
  List<XFile> _imagenesSeleccionadas = [];

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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

    if (widget.inmuebleData != null) {
      _cargarDatosInmueble();
    }
    _entryController.forward();
  }

  void _cargarDatosInmueble() {
    final data = widget.inmuebleData!;
    _tituloController.text = data['titulo'] ?? '';
    _descripcionController.text = data['descripcion'] ?? '';
    _precioController.text = (data['precio'] ?? 0).toString();
    final disp = data['disponible'];
    if (disp is bool) {
      _disponible = disp;
    } else if (disp is int) {
      _disponible = disp == 1;
    } else {
      _disponible = true;
    }
    _categoriaSeleccionada = data['categoria'];
    _camas = data['camas'] ?? 1;
    _banos = data['banos'] ?? 1;
    _tamano = data['tamano'] ?? 'Pequeño';

    if (data['latitud'] != null && data['longitud'] != null) {
      _ubicacionActual = Position(
        latitude: data['latitud'],
        longitude: data['longitud'],
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      _mensajeUbicacion =
          'Ubicación cargada: Lat ${data['latitud'].toStringAsFixed(5)}, Lng ${data['longitud'].toStringAsFixed(5)}';
    }
  }

  Future<void> seleccionarImagenes() async {
    if (!mounted) return;
    LottieLoading.showLoadingDialog(
      context,
      message: 'Seleccionando imágenes...',
      animationPath: 'assets/animations/uploading.json',
    );

    final picker = ImagePicker();
    final imagenes = await picker.pickMultiImage();

    if (!mounted) return;
    LottieLoading.hideLoadingDialog(context);

    if (imagenes.isNotEmpty) {
      setState(() {
        _imagenesSeleccionadas = imagenes;
      });
    }
  }

  Future<void> _obtenerUbicacion() async {
    if (!mounted) return;
    LottieLoading.showLoadingDialog(
      context,
      message: 'Obteniendo ubicación...',
      animationPath: 'assets/animations/location.json',
    );

    try {
      final posicion = await obtenerUbicacionActual();

      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);

      setState(() {
        _ubicacionActual = posicion;
        _mensajeUbicacion =
            'Ubicación obtenida: Lat ${posicion.latitude.toStringAsFixed(5)}, Lng ${posicion.longitude.toStringAsFixed(5)}';
      });

      await LottieFeedback.showSuccess(
        context,
        message: '¡Ubicación obtenida!',
        duration: const Duration(milliseconds: 1500),
      );
    } catch (e) {
      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);

      setState(() {
        _mensajeUbicacion = 'Error obteniendo ubicación: $e';
      });

      await LottieFeedback.showError(
        context,
        message: 'No se pudo obtener la ubicación',
        duration: const Duration(milliseconds: 1500),
      );
    }
  }

  Future<void> _guardarInmueble() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ubicacionActual == null) {
      await LottieFeedback.showError(
        context,
        message: 'Debes obtener la ubicación antes de guardar',
      );
      return;
    }

    if (_imagenesSeleccionadas.isEmpty && widget.inmuebleId == null) {
      await LottieFeedback.showError(
        context,
        message: 'Debes seleccionar al menos una imagen',
      );
      return;
    }

    final titulo = _tituloController.text.trim();
    final descripcion = _descripcionController.text.trim();
    final precioTexto = _precioController.text.trim();
    final precio = double.tryParse(precioTexto.replaceAll(',', '.'));

    if (precio == null || precio <= 0) {
      await LottieFeedback.showError(
        context,
        message: 'Ingresa un precio válido',
      );
      return;
    }

    final bool esEdicion = widget.inmuebleId != null;
    final String accion = esEdicion ? 'Actualizando' : 'Guardando';

    if (!mounted) return;
    LottieLoading.showLoadingDialog(context, message: '$accion inmueble...');

    try {
      List<String> imagePaths = [];
      String tempId = DateTime.now().millisecondsSinceEpoch.toString();

      if (_imagenesSeleccionadas.isNotEmpty) {
        imagePaths = await _storageService.uploadPropertyImages(
          propertyId: widget.inmuebleId ?? tempId,
          imageFiles: _imagenesSeleccionadas,
        );

        if (imagePaths.isEmpty) {
          throw Exception('No se pudieron guardar las imágenes.');
        }
      } else if (widget.inmuebleData != null) {
        final rutasViejas = widget.inmuebleData!['rutas_imagen'] as String?;
        if (rutasViejas != null) imagePaths = rutasViejas.split(',');
      }

      final datosInmueble = {
        'titulo': titulo,
        'descripcion': descripcion,
        'precio': precio,
        'disponible': _disponible ? 1 : 0,
        'categoria': _categoriaSeleccionada,
        'propietario_id': int.tryParse(widget.propietarioId) ?? 0,
        'latitud': _ubicacionActual!.latitude,
        'longitud': _ubicacionActual!.longitude,
        'rutas_imagen': imagePaths.join(','),
        'camas': _camas,
        'banos': _banos,
        'tamano': _tamano,
        'estacionamiento': 0,
        'mascotas': 0,
        'visitas': 0,
        'amueblado': 0,
        'agua': 0,
        'wifi': 0,
      };

      if (esEdicion) {
        final id = int.tryParse(widget.inmuebleId.toString()) ?? 0;
        await BaseDatos.actualizarInmueble(id, datosInmueble);
      } else {
        await BaseDatos.insertarInmueble(datosInmueble);
      }

      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);

      await LottieFeedback.showSuccess(
        context,
        message: '¡Inmueble guardado localmente!',
        onComplete: () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      LottieLoading.hideLoadingDialog(context);
      await LottieFeedback.showError(
        context,
        message: 'Error al guardar: ${e.toString()}',
      );
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Gris muy suave
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryGradient,
          ),
        ),
        title: Text(
          widget.inmuebleId != null ? 'Editar Inmueble' : 'Nuevo Inmueble',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // SECCIÓN 1: INFORMACIÓN BÁSICA
                        _SectionTitle(
                              title: 'Información Básica',
                              icon: Icons.info_outline_rounded,
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .blurXY(
                              begin: 10,
                              end: 0,
                              duration: 600.ms,
                            ) // Unblur effect
                            .slideX(begin: -0.2, curve: Curves.easeOutQuad),
                        StunningCard(
                              child: Column(
                                children: [
                                  StunningTextField(
                                    controller: _tituloController,
                                    label: 'Título del inmueble',
                                    icon: Icons.home_rounded,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Ingresa un título';
                                      }
                                      if (value.trim().length < 5) {
                                        return 'Mínimo 5 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  StunningTextField(
                                    controller: _descripcionController,
                                    label: 'Descripción',
                                    icon: Icons.description_rounded,
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Ingresa una descripción';
                                      }
                                      if (value.trim().length < 15) {
                                        return 'Mínimo 15 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  StunningTextField(
                                    controller: _precioController,
                                    label: 'Precio mensual',
                                    icon: Icons.attach_money_rounded,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Ingresa el precio';
                                      }
                                      final num = double.tryParse(
                                        value.replaceAll(',', '.'),
                                      );
                                      if (num == null || num <= 0) {
                                        return 'Precio inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 600.ms)
                            .slideX(
                              begin: -0.1,
                              curve: Curves.easeOutBack,
                            ), // Elastic slide from left
                        const SizedBox(height: 24),

                        // SECCIÓN 2: CARACTERÍSTICAS
                        _SectionTitle(
                              title: 'Características',
                              icon: Icons.grid_view_rounded,
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .scale(begin: const Offset(0.8, 0.8)), // Pop in
                        StunningCard(
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: StunningDropdown<String>(
                                          value: _categoriaSeleccionada,
                                          label: 'Categoría',
                                          icon: Icons.apartment,
                                          items: _categorias
                                              .map(
                                                (cat) => DropdownMenuItem(
                                                  value: cat,
                                                  child: Text(cat),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) => setState(
                                            () => _categoriaSeleccionada = v,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: StunningDropdown<String>(
                                          value: _tamano,
                                          label: 'Tamaño',
                                          icon: Icons.square_foot,
                                          items:
                                              ['Pequeño', 'Mediano', 'Grande']
                                                  .map(
                                                    (t) => DropdownMenuItem(
                                                      value: t,
                                                      child: Text(t),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (v) =>
                                              setState(() => _tamano = v!),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: StunningDropdown<int>(
                                          value: _camas,
                                          label: 'Camas',
                                          icon: Icons.bed_rounded,
                                          items: [1, 2, 3, 4, 5]
                                              .map(
                                                (n) => DropdownMenuItem(
                                                  value: n,
                                                  child: Text('$n'),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) =>
                                              setState(() => _camas = v!),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: StunningDropdown<int>(
                                          value: _banos,
                                          label: 'Baños',
                                          icon: Icons.bathtub_rounded,
                                          items: [1, 2, 3, 4]
                                              .map(
                                                (n) => DropdownMenuItem(
                                                  value: n,
                                                  child: Text('$n'),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) =>
                                              setState(() => _banos = v!),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _disponible
                                          ? MiTema.celeste.withValues(
                                              alpha: 0.1,
                                            )
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _disponible
                                            ? MiTema.celeste.withValues(
                                                alpha: 0.3,
                                              )
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    child: SwitchListTile(
                                      title: Text(
                                        'Disponible para renta',
                                        style: TextStyle(
                                          color: _disponible
                                              ? MiTema.azul
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      value: _disponible,
                                      activeThumbColor: MiTema.celeste,
                                      onChanged: (val) =>
                                          setState(() => _disponible = val),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 500.ms)
                            .flipV(
                              begin: -0.1,
                              duration: 600.ms,
                              curve: Curves.easeOut,
                            ), // Subtle 3D Flip
                        const SizedBox(height: 24),

                        // SECCIÓN 3: GALERÍA
                        _SectionTitle(
                              title: 'Galería de Fotos',
                              icon: Icons.photo_library_rounded,
                            )
                            .animate()
                            .fadeIn(delay: 700.ms)
                            .slideX(begin: 0.2), // Slide from right
                        StunningCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: seleccionarImagenes,
                                    child: Container(
                                      width: double.infinity,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey[50], // Light background
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(24),
                                            ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: MiTema.celeste
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.add_a_photo_rounded,
                                              size: 32,
                                              color: MiTema.celeste,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Toca para subir fotos',
                                            style: TextStyle(
                                              color: MiTema.celeste,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Muestra lo mejor de tu propiedad',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_imagenesSeleccionadas.isNotEmpty)
                                    Container(
                                      height: 140,
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            _imagenesSeleccionadas.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final img =
                                              _imagenesSeleccionadas[index];
                                          return Stack(
                                            children: [
                                              Container(
                                                width: 120, // Square ish
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      blurRadius: 5,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: ImagenDinamica(
                                                    ruta: img.path,
                                                    width: 120,
                                                    height: 140,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _imagenesSeleccionadas
                                                          .removeAt(index);
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 800.ms)
                            .saturate(
                              begin: 0,
                              duration: 800.ms,
                            ) // Grayscale to Color
                            .scale(begin: const Offset(0.95, 0.95)),
                        const SizedBox(height: 24),

                        // SECCIÓN 4: UBICACIÓN
                        _SectionTitle(
                              title: 'Ubicación',
                              icon: Icons.location_on_rounded,
                            )
                            .animate()
                            .fadeIn(delay: 1000.ms)
                            .moveY(begin: 20), // Move up
                        StunningCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  if (_ubicacionActual == null)
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Center(
                                        child: StunningButton(
                                          onPressed: _obtenerUbicacion,
                                          text: 'DETECTAR UBICACIÓN',
                                          icon: Icons.my_location_rounded,
                                          backgroundColor:
                                              MiTema.vino, // Accent color
                                        ),
                                      ),
                                    )
                                  else ...[
                                    SizedBox(
                                      height: 200,
                                      width: double.infinity,
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(24),
                                            ),
                                        child: MapPreviewOsm(
                                          lat: _ubicacionActual!.latitude,
                                          lng: _ubicacionActual!.longitude,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.green[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _mensajeUbicacion.isNotEmpty
                                                  ? _mensajeUbicacion
                                                  : 'Ubicación detectada correctamente',
                                              style: TextStyle(
                                                color: Colors.green[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _obtenerUbicacion,
                                            child: Text(
                                              'Actualizar',
                                              style: TextStyle(
                                                color: MiTema.azul,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 1200.ms)
                            .shimmer(
                              duration: 1.seconds,
                              delay: 2.seconds,
                            ) // Shimmer attention
                            .slideY(begin: 0.1),
                        const SizedBox(height: 40),

                        // ACTION BUTTON
                        StunningButton(
                              onPressed: _guardarInmueble,
                              text: widget.inmuebleId != null
                                  ? 'ACTUALIZAR PROPIEDAD'
                                  : 'PUBLICAR PROPIEDAD',
                              icon: widget.inmuebleId != null
                                  ? Icons.save_as_rounded
                                  : Icons.rocket_launch_rounded,
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .shimmer(
                              delay: 2000.ms,
                              duration: 1500.ms,
                              color: Colors.white.withValues(alpha: 0.3),
                            )
                            .animate() // Reset animation chain
                            .fadeIn(delay: 1600.ms)
                            .scale(),
                        const SizedBox(height: 20),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: MiTema.azul, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MiTema.azul,
            ),
          ),
        ],
      ),
    );
  }
}

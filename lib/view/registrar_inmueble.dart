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

  // Wrapper visual para Dropdowns para que coincidan con StunningTextField
  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
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
                  child: Column(
                    children: [
                      StunningCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Detalles de la Propiedad',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: MiTema.azul,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Haz que tu propiedad destaque con una descripción detallada.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Título
                              StunningTextField(
                                controller: _tituloController,
                                label: 'Título del inmueble',
                                icon: Icons.home_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa un título';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Descripción
                              StunningTextField(
                                controller: _descripcionController,
                                label: 'Descripción',
                                icon: Icons.description_rounded,
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa una descripción';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Precio
                              StunningTextField(
                                controller: _precioController,
                                label: 'Precio mensual',
                                icon: Icons.attach_money_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa el precio';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Categoría y Tamaño (Row)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildDropdownContainer(
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true, // Prevent overflow
                                        value: _categoriaSeleccionada,
                                        decoration: InputDecoration(
                                          labelText: 'Categoría',
                                          prefixIcon: Icon(
                                            Icons.apartment,
                                            color: MiTema.celeste,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 15,
                                              ),
                                        ),
                                        items: _categorias
                                            .map(
                                              (cat) => DropdownMenuItem(
                                                value: cat,
                                                child: Text(
                                                  cat,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) => setState(
                                          () => _categoriaSeleccionada = v,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDropdownContainer(
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: _tamano,
                                        decoration: InputDecoration(
                                          labelText: 'Tamaño',
                                          prefixIcon: Icon(
                                            Icons.square_foot,
                                            color: MiTema.celeste,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 15,
                                              ),
                                        ),
                                        items: ['Pequeño', 'Mediano', 'Grande']
                                            .map(
                                              (t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(
                                                  t,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _tamano = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Camas y Baños (Row)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildDropdownContainer(
                                      child: DropdownButtonFormField<int>(
                                        value: _camas,
                                        decoration: InputDecoration(
                                          labelText: 'Camas',
                                          prefixIcon: Icon(
                                            Icons.bed_rounded,
                                            color: MiTema.celeste,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 15,
                                              ),
                                        ),
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
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDropdownContainer(
                                      child: DropdownButtonFormField<int>(
                                        value: _banos,
                                        decoration: InputDecoration(
                                          labelText: 'Baños',
                                          prefixIcon: Icon(
                                            Icons.bathtub_rounded,
                                            color: MiTema.celeste,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 15,
                                              ),
                                        ),
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
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Disponible Switch
                              Container(
                                decoration: BoxDecoration(
                                  color: _disponible
                                      ? MiTema.celeste.withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _disponible
                                        ? MiTema.celeste.withOpacity(0.3)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: SwitchListTile(
                                  title: Text(
                                    'Disponible para renta',
                                    style: TextStyle(
                                      color: MiTema.azul,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  value: _disponible,
                                  activeColor: MiTema.celeste,
                                  onChanged: (val) =>
                                      setState(() => _disponible = val),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // FOTOGRAFÍAS
                              Text(
                                'Galería de Imágenes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: MiTema.azul,
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: seleccionarImagenes,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50], // Very light grey
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: MiTema.celeste.withOpacity(0.5),
                                      style: BorderStyle.solid,
                                      width: 1.5,
                                    ),
                                    // Make it look like a dashed area or inviting area
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 40,
                                        color: MiTema.celeste,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Toca para seleccionar fotos',
                                        style: TextStyle(
                                          color: MiTema.celeste,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_imagenesSeleccionadas.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 120,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _imagenesSeleccionadas.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final img = _imagenesSeleccionadas[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: ImagenDinamica(
                                            ruta: img.path,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 30),

                              // UBICACIÓN
                              Text(
                                'Ubicación',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: MiTema.azul,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_ubicacionActual == null)
                                StunningButton(
                                  onPressed: _obtenerUbicacion,
                                  text: 'Obtener Ubicación Actual',
                                  icon: Icons.location_on_rounded,
                                )
                              else
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _mensajeUbicacion,
                                              style: TextStyle(
                                                color: Colors.green[800],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.refresh,
                                              color: Colors.green,
                                            ),
                                            onPressed: _obtenerUbicacion,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: MapPreviewOsm(
                                        lat: _ubicacionActual!.latitude,
                                        lng: _ubicacionActual!.longitude,
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 40),

                              // BOTÓN GUARDAR
                              StunningButton(
                                onPressed: _guardarInmueble,
                                text: widget.inmuebleId != null
                                    ? 'ACTUALIZAR PROPIEDAD'
                                    : 'PUBLICAR PROPIEDAD',
                                icon: Icons.publish_rounded,
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
    );
  }
}

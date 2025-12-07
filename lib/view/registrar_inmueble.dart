import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/services/storage_service.dart';
import 'package:arrendaoco/sensors/ubicacion.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arrendaoco/widgets/map_preview_osm.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';

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

class _RegistrarInmuebleScreenState extends State<RegistrarInmuebleScreen> {
  // final FirestoreService _firestoreService = FirestoreService();
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

  InputDecoration _decoracionCampo(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: MiTema.azul),
      prefixIcon: icon != null ? Icon(icon, color: MiTema.celeste) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: MiTema.celeste.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: MiTema.azul, width: 1.8),
      ),
      filled: true,
      fillColor: MiTema.blanco,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.inmuebleData != null) {
      _cargarDatosInmueble();
    }
  }

  void _cargarDatosInmueble() {
    final data = widget.inmuebleData!;
    _tituloController.text = data['titulo'] ?? '';
    _descripcionController.text = data['descripcion'] ?? '';
    _precioController.text = (data['precio'] ?? 0).toString();
    // Manejar 'disponible' tanto si viene como bool (true/false) o int (1/0)
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
      String tempId = DateTime.now().millisecondsSinceEpoch
          .toString(); // ID Temporal para carpeta

      // Guardar imágenes localmente
      if (_imagenesSeleccionadas.isNotEmpty) {
        imagePaths = await _storageService.uploadPropertyImages(
          propertyId: widget.inmuebleId ?? tempId,
          imageFiles: _imagenesSeleccionadas,
        );

        if (imagePaths.isEmpty) {
          throw Exception('No se pudieron guardar las imágenes.');
        }
      } else if (widget.inmuebleData != null) {
        // En edición, si no seleccionó nuevas, mantenemos las viejas (?)
        // En SQLite las guardamos como string separado por comas
        final rutasViejas = widget.inmuebleData!['rutas_imagen'] as String?;
        if (rutasViejas != null) imagePaths = rutasViejas.split(',');
      }

      final datosInmueble = {
        'titulo': titulo,
        'descripcion': descripcion,
        'precio': precio,
        'disponible': _disponible ? 1 : 0, // SQLite usa INTEGER para bool
        'categoria': _categoriaSeleccionada,
        'propietario_id': int.tryParse(widget.propietarioId) ?? 0,
        'latitud': _ubicacionActual!.latitude,
        'longitud': _ubicacionActual!.longitude,
        'rutas_imagen': imagePaths.join(','), // Guardar como texto CSV
        'camas': _camas,
        'banos': _banos,
        'tamano': _tamano,
        'estacionamiento': 0, // Default
        'mascotas': 0, // Default
        'visitas': 0, // Default
        'amueblado': 0, // Default
        'agua': 0, // Default
        'wifi': 0, // Default
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: MiTema.azul,
        title: Text(
          widget.inmuebleId != null ? 'Editar inmueble' : 'Nuevo inmueble',
          style: TextStyle(color: MiTema.crema),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: MiTema.crema),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 6,
                color: MiTema.blanco,
                shadowColor: MiTema.celeste.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Registrar inmueble',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: MiTema.azul,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completa la información para publicar tu propiedad.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: MiTema.celeste),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Divider(color: MiTema.celeste.withOpacity(0.4)),
                        const SizedBox(height: 16),

                        // Título
                        TextFormField(
                          controller: _tituloController,
                          decoration: _decoracionCampo(
                            'Título del inmueble',
                            Icons.home_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa un título';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Descripción
                        TextFormField(
                          controller: _descripcionController,
                          maxLines: 3,
                          decoration: _decoracionCampo(
                            'Descripción',
                            Icons.notes_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa una descripción';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Precio
                        TextFormField(
                          controller: _precioController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _decoracionCampo(
                            'Precio mensual',
                            Icons.attach_money,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa un precio';
                            }
                            final v = double.tryParse(
                              value.trim().replaceAll(',', '.'),
                            );
                            if (v == null || v <= 0) {
                              return 'Ingresa un precio válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Categoría
                        DropdownButtonFormField<String>(
                          value: _categoriaSeleccionada,
                          decoration: _decoracionCampo(
                            'Categoría',
                            Icons.apartment,
                          ),
                          items: _categorias
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _categoriaSeleccionada = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona una categoría';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // CAMAS
                        DropdownButtonFormField<int>(
                          value: _camas,
                          decoration: _decoracionCampo(
                            'Camas',
                            Icons.bed_outlined,
                          ),
                          items: [1, 2, 3, 4, 5]
                              .map(
                                (num) => DropdownMenuItem(
                                  value: num,
                                  child: Text('$num'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _camas = value ?? 1),
                          validator: (value) {
                            if (value == null) {
                              return 'Selecciona número de camas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // BAÑOS
                        DropdownButtonFormField<int>(
                          value: _banos,
                          decoration: _decoracionCampo(
                            'Baños',
                            Icons.bathtub_outlined,
                          ),
                          items: [1, 2, 3, 4]
                              .map(
                                (num) => DropdownMenuItem(
                                  value: num,
                                  child: Text('$num'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _banos = value ?? 1),
                          validator: (value) {
                            if (value == null) {
                              return 'Selecciona número de baños';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // TAMAÑO
                        DropdownButtonFormField<String>(
                          value: _tamano,
                          decoration: _decoracionCampo(
                            'Tamaño',
                            Icons.square_foot,
                          ),
                          items: ['Pequeño', 'Mediano', 'Grande']
                              .map(
                                (tam) => DropdownMenuItem(
                                  value: tam,
                                  child: Text(tam),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _tamano = value ?? 'Pequeño'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona un tamaño';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Disponible
                        SwitchListTile(
                          title: Text(
                            'Disponible para renta',
                            style: TextStyle(color: MiTema.azul),
                          ),
                          value: _disponible,
                          activeThumbColor: MiTema.celeste,
                          onChanged: (value) {
                            setState(() {
                              _disponible = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 12),

                        // Fotografías
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Fotografías del inmueble',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: MiTema.azul,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: seleccionarImagenes,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Seleccionar imágenes'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              side: BorderSide(color: MiTema.celeste),
                              foregroundColor: MiTema.celeste,
                            ),
                          ),
                        ),
                        if (_imagenesSeleccionadas.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 170,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imagenesSeleccionadas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final img = _imagenesSeleccionadas[index];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: ImagenDinamica(
                                    ruta: img.path,
                                    width: 220,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Ubicación
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ubicación del inmueble',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: MiTema.azul,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _obtenerUbicacion,
                            icon: const Icon(Icons.gps_fixed),
                            label: const Text('Obtener ubicación actual'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              side: BorderSide(color: MiTema.celeste),
                              foregroundColor: MiTema.celeste,
                            ),
                          ),
                        ),
                        if (_mensajeUbicacion.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _mensajeUbicacion,
                            style: TextStyle(
                              color: _ubicacionActual != null
                                  ? Colors.green
                                  : MiTema.rojo,
                            ),
                          ),
                        ],
                        if (_ubicacionActual != null) ...[
                          const SizedBox(height: 10),
                          MapPreviewOsm(
                            lat: _ubicacionActual!.latitude,
                            lng: _ubicacionActual!.longitude,
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Botón guardar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _guardarInmueble,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MiTema.celeste,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.inmuebleId != null
                                  ? 'Actualizar inmueble'
                                  : 'Guardar inmueble',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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

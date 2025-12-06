import 'dart:io';

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:sqflite/sqflite.dart';
import 'package:arrendaoco/sensors/ubicacion.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arrendaoco/widgets/map_preview_osm.dart';

class RegistrarInmuebleScreen extends StatefulWidget {
  final int propietarioId;

  const RegistrarInmuebleScreen({super.key, required this.propietarioId});

  @override
  State<RegistrarInmuebleScreen> createState() =>
      _RegistrarInmuebleScreenState();
}

class _RegistrarInmuebleScreenState extends State<RegistrarInmuebleScreen> {
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

  Future<void> seleccionarImagenes() async {
    final picker = ImagePicker();
    final imagenes = await picker.pickMultiImage();
    if (imagenes.isNotEmpty) {
      setState(() {
        _imagenesSeleccionadas = imagenes;
      });
    }
  }

  Future<void> _obtenerUbicacion() async {
    setState(() {
      _mensajeUbicacion = 'Obteniendo ubicación...';
    });
    try {
      final posicion = await obtenerUbicacionActual();
      setState(() {
        _ubicacionActual = posicion;
        _mensajeUbicacion =
            'Ubicación obtenida: Lat ${posicion.latitude.toStringAsFixed(5)}, Lng ${posicion.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      setState(() {
        _mensajeUbicacion = 'Error obteniendo ubicación: $e';
      });
    }
  }

  Future<void> _guardarInmueble() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ubicacionActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes obtener la ubicación antes de guardar'),
        ),
      );
      return;
    }

    if (_imagenesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar al menos una imagen')),
      );
      return;
    }

    final titulo = _tituloController.text.trim();
    final descripcion = _descripcionController.text.trim();
    final precioTexto = _precioController.text.trim();
    final precio = double.tryParse(precioTexto.replaceAll(',', '.'));

    if (precio == null || precio <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un precio válido')));
      return;
    }

    final rutasImagenes = _imagenesSeleccionadas.map((x) => x.path).join('|');

    try {
      final db = await BaseDatos.conecta();
      await db.insert('inmuebles', {
        'titulo': titulo,
        'descripcion': descripcion,
        'precio': precio,
        'disponible': _disponible ? 1 : 0,
        'categoria': _categoriaSeleccionada,
        'propietario_id': widget.propietarioId,
        'latitud': _ubicacionActual!.latitude,
        'longitud': _ubicacionActual!.longitude,
        'rutas_imagen': rutasImagenes,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inmueble guardado correctamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      if (e is DatabaseException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar inmueble: $e')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error inesperado al guardar inmueble')),
        );
      }
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
        title: Text('Nuevo inmueble', style: TextStyle(color: MiTema.crema)),
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
                          initialValue: _categoriaSeleccionada,
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
                          initialValue: _camas,
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
                          initialValue: _banos,
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
                          initialValue: _tamano,
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
                                  child: Image.file(
                                    File(img.path),
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
                            child: const Text(
                              'Guardar inmueble',
                              style: TextStyle(
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

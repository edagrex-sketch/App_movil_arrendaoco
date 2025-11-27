import 'dart:io';

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/map_preview_osm.dart';

class DetalleInmuebleScreen extends StatefulWidget {
  final Map<String, dynamic> inmueble;

  const DetalleInmuebleScreen({
    super.key,
    required this.inmueble,
  });

  @override
  State<DetalleInmuebleScreen> createState() => _DetalleInmuebleScreenState();
}

class _DetalleInmuebleScreenState extends State<DetalleInmuebleScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inmueble = widget.inmueble;

    final titulo = inmueble['titulo'] ?? '';
    final descripcion = inmueble['descripcion'] ?? '';
    final precio = inmueble['precio'] ?? 0;
    final categoria = inmueble['categoria'] ?? '';
    final disponible = (inmueble['disponible'] as int?) == 1;
    final latitud = inmueble['latitud'] ?? 0.0;
    final longitud = inmueble['longitud'] ?? 0.0;
    final rutasStr = (inmueble['rutas_imagen'] as String?) ?? '';

    final imagenes =
        rutasStr.isNotEmpty ? rutasStr.split('|') : <String>[];

    // Datos de ejemplo (puedes guardarlos en la BD después)
    const camas = 2;
    const banos = 1;
    const metros = 80;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MiTema.vino,
        foregroundColor: MiTema.crema,
        title: Text(titulo, style: TextStyle(color: MiTema.crema)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Agregar a favoritos
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agregado a favoritos')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galería de imágenes
            if (imagenes.isNotEmpty)
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemCount: imagenes.length,
                      itemBuilder: (context, index) {
                        return Image.file(
                          File(imagenes[index]),
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    // Indicador de imágenes
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imagenes.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? MiTema.vino
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Precio y disponibilidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$$precio/mes',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: MiTema.vino,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: disponible
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: disponible
                                ? Colors.green.shade500
                                : Colors.red.shade500,
                          ),
                        ),
                        child: Text(
                          disponible ? 'Disponible' : 'No disponible',
                          style: TextStyle(
                            color: disponible
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Categoría
                  Text(
                    categoria,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Características (camas, baños, metros)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.bed_outlined, color: MiTema.vino),
                            const SizedBox(height: 4),
                            Text(
                              '$camas',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Camas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.bathtub_outlined, color: MiTema.vino),
                            const SizedBox(height: 4),
                            Text(
                              '$banos',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Baños',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.square_foot, color: MiTema.vino),
                            const SizedBox(height: 4),
                            Text(
                              '$metros',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'm²',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Descripción
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MiTema.vino,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ubicación
                  Text(
                    'Ubicación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MiTema.vino,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: MapPreviewOsm(
                      lat: latitud,
                      lng: longitud,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: MiTema.vino),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${latitud.toStringAsFixed(4)}, '
                        'Lng: ${longitud.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botones de acción
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Acción de contactar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contactando al propietario...'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MiTema.vino,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Contactar al propietario',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Acción de reservar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abriendo calendario de reservas...'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: MiTema.celeste),
                        foregroundColor: MiTema.celeste,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reservar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

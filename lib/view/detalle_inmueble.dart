import 'dart:io';

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/map_preview_osm.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';

class DetalleInmuebleScreen extends StatefulWidget {
  final Map inmueble;
  final int? usuarioId;

  const DetalleInmuebleScreen({
    super.key,
    required this.inmueble,
    this.usuarioId,
  });

  @override
  State<DetalleInmuebleScreen> createState() => _DetalleInmuebleScreenState();
}

class _DetalleInmuebleScreenState extends State<DetalleInmuebleScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _resenas = [];
  double _promedioRating = 0.0;
  int _totalResenas = 0;
  bool _esFavorito = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _cargarResenas();
    _verificarFavorito();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _verificarFavorito() async {
    if (widget.usuarioId != null) {
      final esFav = await BaseDatos.esFavorito(
        widget.usuarioId!,
        widget.inmueble['id'] as int,
      );
      if (mounted) {
        setState(() {
          _esFavorito = esFav;
        });
      }
    }
  }

  Future<void> _cargarResenas() async {
    try {
      final inmuebleId = int.parse(widget.inmueble['id'].toString());
      final lista = await BaseDatos.obtenerResenasPorInmueble(inmuebleId);
      final resumen = await BaseDatos.obtenerResumenResenas(inmuebleId);
      if (!mounted) return;
      setState(() {
        _resenas = List<Map<String, dynamic>>.from(lista);
        _promedioRating = (resumen['promedio'] ?? 0.0) as double;
        _totalResenas = (resumen['total'] ?? 0) as int;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar reseñas: $e')));
    }
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
    final imagenes = rutasStr.isNotEmpty ? rutasStr.split('|') : [];

    // De momento son constantes
    const camas = 2;
    const banos = 1;
    const metros = 80;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: MiTema.azul,
        foregroundColor: MiTema.crema,
        title: Text(titulo, style: TextStyle(color: MiTema.crema)),
        centerTitle: true,
        actions: [
          if (widget.usuarioId != null)
            IconButton(
              icon: Icon(_esFavorito ? Icons.favorite : Icons.favorite_border),
              color: MiTema.crema,
              onPressed: () async {
                if (_esFavorito) {
                  await BaseDatos.eliminarFavorito(
                    widget.usuarioId!,
                    inmueble['id'] as int,
                  );
                  if (mounted) {
                    setState(() {
                      _esFavorito = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Eliminado de favoritos')),
                    );
                  }
                } else {
                  await BaseDatos.agregarFavorito(
                    widget.usuarioId!,
                    inmueble['id'] as int,
                  );
                  if (mounted) {
                    setState(() {
                      _esFavorito = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Agregado a favoritos')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                  ? MiTema.celeste
                                  : Colors.white.withOpacity(0.6),
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
                  // Precio + disponibilidad
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
                              ? Colors.green.shade50
                              : MiTema.rojo.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: disponible
                                ? Colors.green.shade500
                                : MiTema.rojo,
                          ),
                        ),
                        child: Text(
                          disponible ? 'Disponible' : 'No disponible',
                          style: TextStyle(
                            color: disponible
                                ? Colors.green.shade700
                                : MiTema.rojo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categoria,
                    style: TextStyle(
                      fontSize: 16,
                      color: MiTema.celeste,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Características
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MiTema.blanco,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: MiTema.celeste.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.bed_outlined, color: MiTema.azul),
                            const SizedBox(height: 4),
                            const Text(
                              '$camas',
                              style: TextStyle(
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
                            Icon(Icons.bathtub_outlined, color: MiTema.azul),
                            const SizedBox(height: 4),
                            const Text(
                              '$banos',
                              style: TextStyle(
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
                            Icon(Icons.square_foot, color: MiTema.azul),
                            const SizedBox(height: 4),
                            const Text(
                              '$metros',
                              style: TextStyle(
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
                      color: MiTema.azul,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 14,
                      color: MiTema.negro.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reseñas
                  _buildSeccionResenas(context),
                  const SizedBox(height: 24),

                  // Ubicación
                  Text(
                    'Ubicación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MiTema.azul,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MiTema.celeste.withOpacity(0.4),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: MapPreviewOsm(lat: latitud, lng: longitud),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: MiTema.azul),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${latitud.toStringAsFixed(4)}, '
                        'Lng: ${longitud.toStringAsFixed(4)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Aquí ya no hay botones de "Contactar al propietario" ni "Reserver"
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======== SECCIÓN RESEÑAS ========
  Widget _buildSeccionResenas(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Reseñas de inquilinos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Califica el inmueble y lee opiniones de otros.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _mostrarFormularioResena,
              style: ElevatedButton.styleFrom(
                backgroundColor: MiTema.celeste,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.rate_review, size: 16),
              label: const Text(
                'Opinar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_totalResenas > 0)
          Row(
            children: [
              _buildEstrellas(_promedioRating),
              const SizedBox(width: 8),
              Text(
                _promedioRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text('($_totalResenas reseñas)'),
            ],
          )
        else
          const Text(
            'Aún no hay reseñas. ¡Sé el primero en opinar!',
            style: TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 12),
        ..._resenas.map((r) => _buildItemResena(r)),
      ],
    );
  }

  Widget _buildEstrellas(double valor) {
    int entero = valor.floor();
    return Row(
      children: List.generate(5, (index) {
        if (index < entero) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }

  Widget _buildItemResena(Map r) {
    final nombre = (r['usuario_nombre'] ?? 'Anónimo').toString();
    final rating = (r['rating'] ?? 0) as int;
    final comentario = (r['comentario'] ?? '').toString();
    final fecha = (r['fecha'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  fecha,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildEstrellas(rating.toDouble()),
                const SizedBox(width: 6),
                Text(
                  rating.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (comentario.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(comentario, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioResena() {
    int ratingSeleccionado = 5;
    final comentarioController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comparte tu experiencia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu reseña se publicará con tu nombre de usuario.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text('Calificación'),
              const SizedBox(height: 6),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Row(
                    children: List.generate(5, (index) {
                      final filled = index < ratingSeleccionado;
                      return IconButton(
                        onPressed: () {
                          setModalState(() {
                            ratingSeleccionado = index + 1;
                          });
                        },
                        icon: Icon(
                          filled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text('Comentario'),
              TextField(
                controller: comentarioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Cuenta tu experiencia (ruido, vecinos, zona, etc.)',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (ratingSeleccionado < 1) return;
                    try {
                      final inmuebleId = int.parse(
                        widget.inmueble['id'].toString(),
                      );
                      final nombreSesion = SesionActual.nombre;
                      final nombre =
                          (nombreSesion == null || nombreSesion.trim().isEmpty)
                          ? 'Anónimo'
                          : nombreSesion.trim();
                      final comentario = comentarioController.text.trim();
                      final fecha = DateTime.now()
                          .toIso8601String()
                          .split('T')
                          .first;
                      await BaseDatos.insertarResena({
                        'inmueble_id': inmuebleId,
                        'usuario_nombre': nombre,
                        'rating': ratingSeleccionado,
                        'comentario': comentario,
                        'fecha': fecha,
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        await _cargarResenas();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reseña enviada')),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al guardar reseña: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MiTema.celeste,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enviar reseña'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

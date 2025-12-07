import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/model/bd.dart';

class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  // final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Map<String, dynamic>>> _futureInmuebles;

  String _busqueda = '';
  String? _categoriaSeleccionada;
  final List<String> _categorias = [
    'Departamento',
    'Casa',
    'Habitación',
    'Local',
  ];

  @override
  void initState() {
    super.initState();
    _futureInmuebles = _cargarInmuebles();
  }

  Future<List<Map<String, dynamic>>> _cargarInmuebles() async {
    return await BaseDatos.obtenerInmuebles();
  }

  List<Map<String, dynamic>> _aplicarFiltros(
    List<Map<String, dynamic>> inmuebles,
  ) {
    return inmuebles.where((i) {
      final titulo = (i['titulo'] ?? '').toString().toLowerCase();
      final desc = (i['descripcion'] ?? '').toString().toLowerCase();
      final cat = (i['categoria'] ?? '').toString();

      final coincideTexto =
          _busqueda.isEmpty ||
          titulo.contains(_busqueda.toLowerCase()) ||
          desc.contains(_busqueda.toLowerCase());

      final coincideCat =
          _categoriaSeleccionada == null || _categoriaSeleccionada == cat;

      return coincideTexto && coincideCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureInmuebles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LottieLoading(
            message: 'Cargando inmuebles...',
            size: 200,
          );
        }
        if (snapshot.hasError) {
          print(snapshot.error);
          return const Center(child: Text('Error al cargar inmuebles'));
        }

        final todos = snapshot.data ?? [];
        final inmuebles = _aplicarFiltros(todos);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar departamento, casa, etc.',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.tune),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _busqueda = value.trim();
                  });
                },
              ),
            ),

            // Chips de categorías
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categorias.map((cat) {
                    final seleccionado = _categoriaSeleccionada == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: seleccionado,
                        selectedColor: MiTema.celeste.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: seleccionado ? MiTema.vino : Colors.grey[800],
                          fontWeight: seleccionado
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        onSelected: (value) {
                          setState(() {
                            _categoriaSeleccionada = value ? cat : null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Inmuebles disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MiTema.vino,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Lista de cards
            Expanded(
              child: inmuebles.isEmpty
                  ? const Center(child: Text('No se encontraron inmuebles.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: inmuebles.length,
                      itemBuilder: (context, index) {
                        final i = inmuebles[index];
                        final titulo = i['titulo'] ?? '';
                        final descripcion = i['descripcion'] ?? '';
                        final precio = i['precio'] ?? 0;
                        final categoria = i['categoria'] ?? '';

                        // Handle images local
                        final rutasRaw = i['rutas_imagen'] as String? ?? '';
                        final rutas = rutasRaw.isEmpty
                            ? []
                            : rutasRaw.split(',');
                        final primeraRuta = rutas.isNotEmpty
                            ? rutas.first
                            : null;

                        final camas = i['camas'] ?? 2;
                        final banos = i['banos'] ?? 1;
                        final tamano = i['tamano'] ?? '80';

                        final direccionCorta = descripcion
                            .toString()
                            .split('\n')
                            .first;

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 180,
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    if (primeraRuta != null)
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                        child: ImagenDinamica(
                                          ruta: primeraRuta,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    if (SesionActual.usuarioId != null)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: FutureBuilder<bool>(
                                          future: Future.value(false).then((
                                            _,
                                          ) async {
                                            // Wrap for strict logic
                                            final uid =
                                                int.tryParse(
                                                  SesionActual.usuarioId!,
                                                ) ??
                                                0;
                                            final iid = i['id'] as int;
                                            return await BaseDatos.esFavorito(
                                              uid,
                                              iid,
                                            );
                                          }),
                                          builder: (context, snapshot) {
                                            final esFav =
                                                snapshot.data ?? false;
                                            return CircleAvatar(
                                              backgroundColor: Colors.white,
                                              child: IconButton(
                                                icon: Icon(
                                                  esFav
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: esFav
                                                      ? MiTema.rojo
                                                      : Colors.grey,
                                                ),
                                                onPressed: () async {
                                                  final uid =
                                                      int.tryParse(
                                                        SesionActual.usuarioId!,
                                                      ) ??
                                                      0;
                                                  final iid = i['id'] as int;

                                                  if (esFav) {
                                                    await BaseDatos.eliminarFavorito(
                                                      uid,
                                                      iid,
                                                    );
                                                    if (context.mounted) {
                                                      await LottieFeedback.showSuccess(
                                                        context,
                                                        message:
                                                            'Eliminado de favoritos',
                                                        duration:
                                                            const Duration(
                                                              milliseconds:
                                                                  1000,
                                                            ),
                                                      );
                                                    }
                                                  } else {
                                                    await BaseDatos.agregarFavorito(
                                                      uid,
                                                      iid,
                                                    );
                                                    if (context.mounted) {
                                                      await LottieFeedback.showSuccess(
                                                        context,
                                                        message:
                                                            'Agregado a favoritos',
                                                        duration:
                                                            const Duration(
                                                              milliseconds:
                                                                  1000,
                                                            ),
                                                      );
                                                    }
                                                  }
                                                  setState(() {});
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titulo.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: MiTema.azul,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      categoria.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: MiTema.celeste,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${precio.toString()}/mes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: MiTema.vino,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.bed_outlined,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('$camas camas'),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.bathtub_outlined,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('$banos baño'),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.square_foot, size: 16),
                                        const SizedBox(width: 4),
                                        Text('$tamano m²'),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            direccionCorta,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DetalleInmuebleScreen(
                                                    inmueble: i,
                                                    usuarioId:
                                                        SesionActual.usuarioId,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: MiTema.celeste,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Ver detalles'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

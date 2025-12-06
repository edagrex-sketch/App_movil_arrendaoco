import 'dart:io';

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';

class ExplorarScreen extends StatefulWidget {
  final int? usuarioId;

  const ExplorarScreen({super.key, this.usuarioId});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  late Future<List<Map<String, dynamic>>> _futureInmuebles;
  String _busqueda = '';
  String? _categoriaSeleccionada;

  final List<String> _categorias = ['Casa', 'Departamento', 'Cuarto'];

  @override
  void initState() {
    super.initState();
    _futureInmuebles = _cargarInmuebles();
  }

  Future<List<Map<String, dynamic>>> _cargarInmuebles() async {
    final db = await BaseDatos.conecta();
    return db.query('inmuebles', orderBy: 'id DESC');
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
          return const Center(child: CircularProgressIndicator());
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
                        final rutas = (i['rutas_imagen'] as String?) ?? '';
                        final primeraRuta = rutas.isNotEmpty
                            ? rutas.split('|').first
                            : null;

                        // Datos de ejemplo para cuartos/baños/área
                        const recamaras = 2;
                        const banos = 1;
                        const metros = 80;

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
                              Stack(
                                children: [
                                  if (primeraRuta != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Image.file(
                                        File(primeraRuta),
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if (widget.usuarioId != null)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: FutureBuilder<bool>(
                                        future: BaseDatos.esFavorito(
                                          widget.usuarioId!,
                                          i['id'] as int,
                                        ),
                                        builder: (context, snapshot) {
                                          final esFav = snapshot.data ?? false;
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
                                                if (esFav) {
                                                  await BaseDatos.eliminarFavorito(
                                                    widget.usuarioId!,
                                                    i['id'] as int,
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Eliminado de favoritos',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } else {
                                                  await BaseDatos.agregarFavorito(
                                                    widget.usuarioId!,
                                                    i['id'] as int,
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Agregado a favoritos',
                                                        ),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                        Text('$recamaras camas'),
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
                                        Text('$metros m²'),
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
                                                    usuarioId: widget.usuarioId,
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

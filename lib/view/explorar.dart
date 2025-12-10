import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';

import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  late Stream<List<Map<String, dynamic>>> _inmueblesStream;
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
    _inmueblesStream = Supabase.instance.client
        .from('inmuebles')
        .stream(primaryKey: ['id'])
        .order('id', ascending: false);
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _inmueblesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: MiTema.celeste),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar inmuebles'));
        }

        final todos = snapshot.data ?? [];
        final inmuebles = _aplicarFiltros(todos);

        return Container(
          color: const Color(0xFFF5F7FA), // Light background
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER with Search and Chips
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  top: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StunningSearchBar(
                      onChanged: (value) =>
                          setState(() => _busqueda = value.trim()),
                      hintText: '¿Qué estás buscando hoy?',
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categorias.map((cat) {
                          final seleccionado = _categoriaSeleccionada == cat;
                          return StunningChip(
                            label: cat,
                            selected: seleccionado,
                            onSelected: (val) {
                              setState(() {
                                _categoriaSeleccionada = val ? cat : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Inmuebles Destacados',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: MiTema.azul,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // LIST
              Expanded(
                child: inmuebles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No encontramos resultados',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: inmuebles.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final i = inmuebles[index];
                          final titulo = i['titulo'] ?? '';
                          final descripcion = i['descripcion'] ?? '';
                          final precio = i['precio'] ?? 0;
                          final categoria = i['categoria'] ?? '';

                          final rutasRaw = i['rutas_imagen'] as String? ?? '';
                          final rutas = rutasRaw.isEmpty
                              ? []
                              : rutasRaw.split(',');
                          final primeraRuta = rutas.isNotEmpty
                              ? rutas.first
                              : null;

                          final camas = i['camas'] ?? 1;
                          final banos = i['banos'] ?? 1;
                          final tamano = i['tamano'] ?? 'Pequeño';

                          final direccionCorta = descripcion
                              .toString()
                              .split('\n')
                              .first;

                          return _FadeInUpItem(
                            index: index,
                            child: StunningCard(
                              padding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleInmuebleScreen(
                                      inmueble: i,
                                      usuarioId: SesionActual.usuarioId,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      Hero(
                                        tag: 'img_${i['id']}',
                                        child: Container(
                                          height: 220,
                                          width: double.infinity,
                                          color: Colors.grey[200],
                                          child: primeraRuta != null
                                              ? ImagenDinamica(
                                                  ruta: primeraRuta,
                                                  height: 220,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey[400],
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            categoria,
                                            style: TextStyle(
                                              color: MiTema.azul,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (SesionActual.usuarioId != null)
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: _FavoriteButton(
                                            inmuebleId: i['id'],
                                            usuarioId: SesionActual.usuarioId!,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                titulo.toString(),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: MiTema.azul,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '\$${precio.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: MiTema.vino,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              size: 16,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                direccionCorta,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            _FeatureChip(
                                              icon: Icons.bed_rounded,
                                              text: '$camas',
                                            ),
                                            const SizedBox(width: 12),
                                            _FeatureChip(
                                              icon: Icons.bathtub_rounded,
                                              text: '$banos',
                                            ),
                                            const SizedBox(width: 12),
                                            _FeatureChip(
                                              icon: Icons.square_foot_rounded,
                                              text: tamano.toString(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final int inmuebleId;
  final String usuarioId;

  const _FavoriteButton({required this.inmuebleId, required this.usuarioId});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool isFav = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final uid = int.tryParse(widget.usuarioId) ?? 0;
    final fav = await BaseDatos.esFavorito(uid, widget.inmuebleId);
    if (mounted) setState(() => isFav = fav);
  }

  Future<void> _toggleFavorite() async {
    final uid = int.tryParse(widget.usuarioId) ?? 0;

    if (isFav) {
      await BaseDatos.eliminarFavorito(uid, widget.inmuebleId);
    } else {
      await BaseDatos.agregarFavorito(uid, widget.inmuebleId);
    }

    setState(() => isFav = !isFav);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFav ? MiTema.rojo : Colors.grey[400],
          size: 20,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MiTema.celeste),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _FadeInUpItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _FadeInUpItem({required this.child, required this.index});

  @override
  State<_FadeInUpItem> createState() => _FadeInUpItemState();
}

class _FadeInUpItemState extends State<_FadeInUpItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Pequeño delay escalonado basado en el índice (tope 300ms para que no tarde mucho si scrolleas rápido)
    final delay = Duration(milliseconds: (widget.index * 100).clamp(0, 500));

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _translate = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _translate, child: widget.child),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:lottie/lottie.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/utils/casting.dart';
import 'package:arrendaoco/services/api_service.dart';

class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _inmuebles = [];
  bool _isLoading = true;
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
    _cargarInmuebles();
  }

  Future<void> _cargarInmuebles() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/inmuebles/public-list');
      if (response.statusCode == 200) {
        // En Laravel Resource, los datos vienen en 'data'
        final List<dynamic> data = response.data['data'];
        setState(() {
          _inmuebles = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando inmuebles: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _aplicarFiltros() {
    return _inmuebles.where((i) {
      final titulo = (i['titulo'] ?? '').toString().toLowerCase();
      final desc = (i['descripcion'] ?? '').toString().toLowerCase();
      final cat = (i['tipo'] ?? '').toString();

      final coincideTexto =
          _busqueda.isEmpty ||
          titulo.contains(_busqueda.toLowerCase()) ||
          desc.contains(_busqueda.toLowerCase());

      final coincideCat =
          _categoriaSeleccionada == null ||
          _categoriaSeleccionada!.toLowerCase() == cat.toLowerCase();

      return coincideTexto && coincideCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER con buscador... (se mantiene igual hasta la lista)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                  onChanged: (value) {
                    EasyDebounce.debounce(
                      'search-debouncer',
                      const Duration(milliseconds: 500),
                      () {
                        if (mounted) setState(() => _busqueda = value.trim());
                      },
                    );
                  },
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
                          setState(
                            () => _categoriaSeleccionada = val ? cat : null,
                          );
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

          Expanded(
            child: _isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: 4,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 20),
                    itemBuilder: (ctx, i) => const StunningShimmerCard(),
                  )
                : _inmuebles.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _cargarInmuebles,
                    color: MiTema.celeste,
                    child: _buildList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.search_off_rounded,
                size: 80,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No encontramos resultados',
              style: TextStyle(
                color: MiTema.azul,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otra búsqueda o categoría',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final inmuebles = _aplicarFiltros();
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: inmuebles.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final i = inmuebles[index];
        final id = i['id'];
        final titulo = i['titulo'] ?? '';
        final direccion = i['direccion'] ?? '';
        final precio = Parser.toDouble(i['renta_mensual']);
        final tipo = i['tipo'] ?? '';
        final imagen = i['imagen_portada'] as String?;

        final habitaciones = Parser.paramInt(i['habitaciones']);
        final banos = Parser.paramInt(i['banos']);
        final metros = Parser.paramInt(i['metros']);

        return StunningCard(
              padding: EdgeInsets.zero,
              onTap: () {
                HapticFeedback.lightImpact();
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
                        tag: 'img_$id',
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: imagen != null
                              ? ImagenDinamica(
                                  ruta: imagen,
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
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tipo,
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
                            inmuebleId: id,
                            usuarioId: SesionActual.usuarioId!,
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                titulo,
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
                                direccion,
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
                              text: '$habitaciones hab',
                            ),
                            const SizedBox(width: 12),
                            _FeatureChip(
                              icon: Icons.bathtub_rounded,
                              text: '$banos baños',
                            ),
                            const SizedBox(width: 12),
                            _FeatureChip(
                              icon: Icons.square_foot_rounded,
                              text: '${metros}m²',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: (index * 50).clamp(0, 500).ms)
            .flipV(
              begin: 0.5,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutBack,
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
    try {
      final response = await ApiService().get('/favoritos');
      if (response.statusCode == 200) {
        final List<dynamic> favs = response.data['data'] ?? [];
        final isCurrentlyFav = favs.any((f) => f['id'] == widget.inmuebleId);
        if (mounted) setState(() => isFav = isCurrentlyFav);
      }
    } catch (e) {
      debugPrint('Error checking favorite: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.selectionClick();

    try {
      final response = await ApiService().post(
        '/favoritos/${widget.inmuebleId}/toggle',
      );
      if (response.statusCode == 200) {
        setState(() => isFav = !isFav);
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
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

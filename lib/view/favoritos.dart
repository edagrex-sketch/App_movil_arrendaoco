import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/theme/arrenda_colors.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:arrendaoco/utils/casting.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _favoritos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final response = await _api.get('/favoritos');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _favoritos = List<Map<String, dynamic>>.from(data);
            _cargando = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando favoritos: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _toggleFavorito(Map<String, dynamic> inmueble) async {
    HapticFeedback.lightImpact();
    // Optimistic UI update (optional, but better feel)
    setState(() {
      _favoritos.removeWhere((item) => item['id'] == inmueble['id']);
    });

    try {
      final response = await _api.post('/favoritos/${inmueble['id']}/toggle');
      if (response.statusCode != 200) {
        // Revert if failed
        _cargarDatos();
      }
    } catch (e) {
      debugPrint('Error eliminando favorito: $e');
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return _buildLoadingStateContent();
    if (_favoritos.isEmpty) return _buildEmptyStateContent();
    return _buildFavoritesGridContent();
  }

  Widget _buildLoadingStateContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) => const StunningShimmerCard(isGrid: true),
        itemCount: 6,
      ),
    );
  }

  Widget _buildEmptyStateContent() {
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MiTema.celeste.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Lottie.asset(
                  'assets/animations/empty.json',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.favorite_border_rounded, size: 60, color: Colors.grey[300]),
                ),
              ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              Text(
                'Aún no hay favoritos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: MiTema.azul,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
              const SizedBox(height: 12),
              Text(
                'Guarda los lugares que más te gusten para tenerlos siempre a mano.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
            ],
          ),
        ),
    );
  }

  Widget _buildFavoritesGridContent() {
    return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final inmueble = _favoritos[index];
          return _buildFavoriteCard(inmueble, index);
        },
        itemCount: _favoritos.length,
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> inmueble, int index) {
    final String titulo = inmueble['titulo'] ?? 'Inmueble';
    final double precio = Parser.toDouble(inmueble['renta_mensual']);
    final String categoria = (inmueble['tipo'] ?? 'Propiedad').toString().toUpperCase();
    final String? imagePath = inmueble['imagen_portada'];
    final String ubicacion = inmueble['direccion'] ?? 'Sin ubicación';

    return StunningCard(
      padding: EdgeInsets.zero,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleInmuebleScreen(
              inmueble: inmueble,
              usuarioId: SesionActual.usuarioId,
            ),
          ),
        );
        _cargarDatos(); // Actualizar al volver por si se desmarcó
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con Tag de Precio y Categoria
          Expanded(
            flex: 12,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: imagePath != null
                    ? ImagenDinamica(ruta: imagePath, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.home_work_outlined, color: Colors.grey[400], size: 40),
                      ),
                ),
                // Overlay Gradiente Inferior
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.5),
                        ],
                        stops: const [0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
                // Categoría Tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      categoria,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: MiTema.azul,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Botón Favorito (Toggle)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleFavorito(inmueble),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: MiTema.rojo,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                // Precio (Inferior)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${precio.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'al mes',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Detalles de Información
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: MiTema.azul,
                      height: 1.1,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: MiTema.celeste),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ubicacion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
}

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _favoritos = [];
  bool _cargando = true;
  StreamSubscription? _sub;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cargarDatos();
    _suscribirCambios();
  }

  void _suscribirCambios() {
    final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    _sub = Supabase.instance.client
        .from('favoritos')
        .stream(primaryKey: ['id'])
        .eq('usuario_id', uid)
        .listen((_) {
          _cargarDatos();
        });
  }

  Future<void> _cargarDatos() async {
    final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    final datos = await BaseDatos.obtenerFavoritos(uid);
    if (mounted) {
      setState(() {
        _favoritos = datos;
        _cargando = false;
        _controller.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Retornamos directamente el body porque el shell (InquilinoHome) ya tiene Scaffold/AppBar
    return _buildBody();
  }

  Widget _buildBody() {
    if (_cargando) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 6,
          itemBuilder: (context, index) =>
              const StunningShimmerCard(isGrid: true),
        ),
      );
    }

    if (_favoritos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.favorite_border_rounded,
                  size: 100,
                  color: Colors.grey[300],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Tu colección está vacía',
              style: TextStyle(
                fontSize: 22,
                color: MiTema.azul,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Explora y guarda los inmuebles que te encanten para verlos aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(
        top:
            100, // Espacio para el AppBar transparente del padre (aprox kToolbarHeight + safeArea)
        left: 16,
        right: 16,
        bottom: 16,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Ligeramente más anchas para evitar overflow
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _favoritos.length,
      itemBuilder: (context, index) {
        final inmueble = _favoritos[index];
        // Staggered animation
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              (1 / _favoritos.length) * index,
              1.0,
              curve: Curves.easeOutQuart,
            ),
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: _buildFavoritoCard(inmueble),
          ),
        );
      },
    );
  }

  Widget _buildFavoritoCard(Map<String, dynamic> inmueble) {
    final titulo = inmueble['titulo'] ?? 'Inmueble';
    final precio = inmueble['precio'] ?? 0;
    final categoria = inmueble['categoria'] ?? 'General';
    final imageUrlsRaw = (inmueble['rutas_imagen'] as String?) ?? '';
    final imageUrls = imageUrlsRaw.isNotEmpty ? imageUrlsRaw.split(',') : [];
    final primeraUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    return StunningCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleInmuebleScreen(
              inmueble: inmueble,
              usuarioId: SesionActual.usuarioId,
            ),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculamos alturas fijas basadas en el layout disponible
          final imageHeight = constraints.maxHeight * 0.65;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (primeraUrl != null)
                      ImagenDinamica(ruta: primeraUrl, fit: BoxFit.cover)
                    else
                      Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Price Tag overlay
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        '\$$precio/mes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Remove button overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final uid =
                              int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
                          if (uid > 0) {
                            await BaseDatos.eliminarFavorito(
                              uid,
                              inmueble['id'],
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
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
                            Icons.favorite_rounded,
                            color: MiTema.rojo,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        categoria.toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: MiTema.celeste,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        titulo.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: MiTema.azul,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

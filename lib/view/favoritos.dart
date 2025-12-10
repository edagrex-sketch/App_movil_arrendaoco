import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  List<Map<String, dynamic>> _favoritos = [];
  bool _cargando = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
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
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Center(child: CircularProgressIndicator(color: MiTema.celeste));
    }

    // Usamos _favoritos directamennte
    final favoritos = _favoritos;

    // ... rest of build ... (removing FutureBuilder wrapper)
    return _buildContent(favoritos);
  }

  Widget _buildContent(List<Map<String, dynamic>> favoritos) {
    if (favoritos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 60,
                color: MiTema.celeste,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin favoritos',
              style: TextStyle(
                fontSize: 20,
                color: MiTema.azul,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Guarda inmuebles para verlos aquí más tarde.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Favoritos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MiTema.azul,
                  ),
                ),
                Text(
                  '${favoritos.length} elementos guardados',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: favoritos.length,
              separatorBuilder: (c, i) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final inmueble = favoritos[index];
                final titulo = inmueble['titulo'] ?? '';
                final precio = inmueble['precio'] ?? 0;
                final categoria = inmueble['categoria'] ?? '';
                final imageUrlsRaw =
                    (inmueble['rutas_imagen'] as String?) ?? '';
                final imageUrls = imageUrlsRaw.isNotEmpty
                    ? imageUrlsRaw.split(',')
                    : [];
                final primeraUrl = imageUrls.isNotEmpty
                    ? imageUrls.first
                    : null;

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
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: primeraUrl != null
                            ? ImagenDinamica(
                                ruta: primeraUrl,
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.broken_image_rounded,
                                color: Colors.grey[400],
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoria.toString().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: MiTema.celeste,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          titulo.toString(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: MiTema.azul,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.favorite_rounded,
                                      color: MiTema.rojo,
                                    ),
                                    onPressed: () async {
                                      final uid =
                                          int.tryParse(
                                            SesionActual.usuarioId ?? '0',
                                          ) ??
                                          0;
                                      if (uid > 0) {
                                        await BaseDatos.eliminarFavorito(
                                          uid,
                                          inmueble['id'],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '\$$precio/mes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: MiTema.vino,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  // final FirestoreService _firestoreService = FirestoreService();
  late Future<List<Map<String, dynamic>>> _futureFavoritos;

  @override
  void initState() {
    super.initState();
    final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    _futureFavoritos = BaseDatos.obtenerFavoritos(uid);
  }

  void _recargarFavoritos() {
    setState(() {
      final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
      _futureFavoritos = BaseDatos.obtenerFavoritos(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureFavoritos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar favoritos'));
        }

        final favoritos = snapshot.data ?? [];

        if (favoritos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No tienes inmuebles guardados',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explora y guarda tus favoritos',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: MiTema.vino),
                  const SizedBox(width: 8),
                  Text(
                    'Inmuebles guardados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: MiTema.vino,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: favoritos.length,
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

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleInmuebleScreen(
                              inmueble: inmueble,
                              usuarioId: SesionActual.usuarioId,
                            ),
                          ),
                        ).then((_) => _recargarFavoritos());
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              if (primeraUrl != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: ImagenDinamica(
                                    ruta: primeraUrl,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.favorite,
                                      color: MiTema.rojo,
                                    ),
                                    onPressed: () async {
                                      final uid =
                                          int.tryParse(
                                            SesionActual.usuarioId!,
                                          ) ??
                                          0;
                                      final iid = inmueble['id'] as int;

                                      await BaseDatos.eliminarFavorito(
                                        uid,
                                        iid,
                                      );
                                      _recargarFavoritos();
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
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
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
                        ],
                      ),
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

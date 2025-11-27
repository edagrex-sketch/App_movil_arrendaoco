import 'dart:io';

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/view/registrar_inmueble.dart';
import 'package:arrendaoco/view/explorar.dart';
import 'package:arrendaoco/view/perfil.dart';
import 'package:arrendaoco/model/bd.dart';

class ArrendadorScreen extends StatefulWidget {
  final int usuarioId;

  const ArrendadorScreen({super.key, required this.usuarioId});

  @override
  State<ArrendadorScreen> createState() => _ArrendadorScreenState();
}

class _ArrendadorScreenState extends State<ArrendadorScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _InicioFeed(usuarioId: widget.usuarioId),
      const ExplorarScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ArrendaOco'),
        foregroundColor: MiTema.crema,
        backgroundColor: MiTema.vino,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),

      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrarInmuebleScreen(
                      propietarioId: widget.usuarioId,
                    ),
                  ),
                );
                setState(() {}); // reconstruye el feed para ver el nuevo
              },
              backgroundColor: MiTema.vino,
              icon: Icon(Icons.add_home_work_outlined, color: MiTema.blanco),
              label: Text('Publicar', style: TextStyle(color: MiTema.blanco)),
            )
          : null,

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: MiTema.vino,
          indicatorColor: MiTema.vino,
          iconTheme: MaterialStatePropertyAll(
            IconThemeData(color: MiTema.crema),
          ),
          labelTextStyle: MaterialStatePropertyAll(
            TextStyle(
              color: MiTema.crema,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: MiTema.crema),
              selectedIcon: Icon(Icons.home, color: MiTema.crema),
              label: 'Publicar',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined, color: MiTema.crema),
              selectedIcon: Icon(Icons.search, color: MiTema.crema),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: MiTema.crema),
              selectedIcon: Icon(Icons.person, color: MiTema.crema),
              label: 'Perfil',
            ),
          ],
        ),
      ),

      body: pages[_currentIndex],
    );
  }
}

class _InicioFeed extends StatefulWidget {
  final int usuarioId;

  const _InicioFeed({required this.usuarioId});

  @override
  State<_InicioFeed> createState() => _InicioFeedState();
}

class _InicioFeedState extends State<_InicioFeed> {
  late Future<List<Map<String, dynamic>>> _futureInmuebles;

  @override
  void initState() {
    super.initState();
    _futureInmuebles = _cargarInmuebles();
  }

  Future<List<Map<String, dynamic>>> _cargarInmuebles() async {
    final db = await BaseDatos.conecta();
    return db.query(
      'inmuebles',
      where: 'propietario_id = ?',
      whereArgs: [widget.usuarioId],
      orderBy: 'id DESC',
    );
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

        final inmuebles = snapshot.data ?? [];
        if (inmuebles.isEmpty) {
          return const Center(child: Text('Aún no has publicado inmuebles.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: inmuebles.length,
          itemBuilder: (context, index) {
            final i = inmuebles[index];
            final titulo = i['titulo'] ?? '';
            final descripcion = i['descripcion'] ?? '';
            final precio = i['precio'] ?? 0;
            final categoria = i['categoria'] ?? '';
            final rutas = (i['rutas_imagen'] as String?) ?? '';
            final primeraRuta =
                rutas.isNotEmpty ? rutas.split('|').first : null;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MiTema.vino,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoria,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

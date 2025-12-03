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
  State<ArrendadorScreen> createState() => ArrendadorScreenState();
}

class ArrendadorScreenState extends State<ArrendadorScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      InicioFeed(usuarioId: widget.usuarioId),
      const ExplorarScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      backgroundColor: MiTema.crema,
      appBar: AppBar(
        title: const Text('ArrendaOco'),
        backgroundColor: MiTema.azul,
        foregroundColor: MiTema.crema,
        centerTitle: true,
        iconTheme: IconThemeData(color: MiTema.crema),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones próximamente')),
              );
            },
            icon: Icon(
              Icons.notifications_outlined,
              color: MiTema.crema,
            ),
          ),
        ],
      ),
      floatingActionButton: currentIndex == 0
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
                setState(() {
                  // Reconstruye el feed para ver el nuevo inmueble
                });
              },
              backgroundColor: MiTema.celeste,
              icon: Icon(Icons.add_home_work_outlined, color: MiTema.blanco),
              label: Text(
                'Publicar',
                style: TextStyle(color: MiTema.blanco),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          iconTheme: MaterialStatePropertyAll(
            IconThemeData(color: Colors.white),
          ),
          labelTextStyle: MaterialStatePropertyAll(
            TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: Container(
          color: MiTema.azul,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: currentIndex,
            onDestinationSelected: (i) {
              setState(() {
                currentIndex = i;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Publicar',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
      body: pages[currentIndex],
    );
  }
}

class InicioFeed extends StatefulWidget {
  final int usuarioId;

  const InicioFeed({super.key, required this.usuarioId});

  @override
  State<InicioFeed> createState() => InicioFeedState();
}

class InicioFeedState extends State<InicioFeed> {
  late Future<List<Map<String, dynamic>>> futureInmuebles;

  @override
  void initState() {
    super.initState();
    futureInmuebles = cargarInmuebles();
  }

  Future<List<Map<String, dynamic>>> cargarInmuebles() async {
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
      future: futureInmuebles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // ignore: avoid_print
          print(snapshot.error);
          return const Center(child: Text('Error al cargar inmuebles'));
        }

        final inmuebles = snapshot.data ?? [];

        if (inmuebles.isEmpty) {
          return const Center(
            child: Text('Aún no has publicado inmuebles.'),
          );
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
            final rutas = i['rutas_imagen'] as String? ?? '';
            final primeraRuta =
                rutas.isNotEmpty ? rutas.split('|').first : null;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              color: MiTema.blanco,
              shadowColor: MiTema.celeste.withOpacity(0.3),
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
                          descripcion.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MiTema.negro,
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RegistrarInmuebleScreen(
                                      propietarioId: widget.usuarioId,
                                      // Más adelante puedes pasar el inmueble para edición real
                                    ),
                                  ),
                                );
                                setState(() {
                                  futureInmuebles = cargarInmuebles();
                                });
                              },
                              icon: Icon(
                                Icons.edit,
                                size: 18,
                                color: MiTema.azul,
                              ),
                              label: Text(
                                'Editar',
                                style: TextStyle(color: MiTema.azul),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: MiTema.blanco,
                                    title: Text(
                                      'Eliminar inmueble',
                                      style: TextStyle(color: MiTema.azul),
                                    ),
                                    content: const Text(
                                      '¿Seguro que quieres eliminar este inmueble?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          'Cancelar',
                                          style:
                                              TextStyle(color: MiTema.azul),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: MiTema.rojo,
                                        ),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmar == true) {
                                  final db = await BaseDatos.conecta();
                                  await db.delete(
                                    'inmuebles',
                                    where: 'id = ?',
                                    whereArgs: [i['id']],
                                  );
                                  setState(() {
                                    futureInmuebles = cargarInmuebles();
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Inmueble eliminado correctamente',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: Icon(
                                Icons.delete,
                                size: 18,
                                color: MiTema.rojo,
                              ),
                              label: Text(
                                'Eliminar',
                                style: TextStyle(color: MiTema.rojo),
                              ),
                            ),
                          ],
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

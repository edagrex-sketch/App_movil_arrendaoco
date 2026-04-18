import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/theme/arrenda_colors.dart';
import 'package:arrendaoco/view/registrar_inmueble.dart';
import 'package:arrendaoco/view/explorar.dart';
import 'package:arrendaoco/view/perfil.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/services/fcm_service.dart';
import 'package:arrendaoco/view/widgets/notification_badge.dart';
import 'package:arrendaoco/utils/casting.dart';
import 'package:arrendaoco/view/chats/chat_list_screen.dart';
import 'package:arrendaoco/view/roco_chat.dart';


class ArrendadorScreen extends StatefulWidget {
  final String usuarioId;

  const ArrendadorScreen({super.key, required this.usuarioId});

  @override
  State<ArrendadorScreen> createState() => ArrendadorScreenState();
}

class ArrendadorScreenState extends State<ArrendadorScreen> {
  int currentIndex = 0;
  final GlobalKey<InicioFeedState> _feedKey = GlobalKey<InicioFeedState>();

  @override
  void initState() {
    super.initState();
    final uid = int.tryParse(widget.usuarioId) ?? 0;
    if (uid > 0) {
      FCMService.initialize(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      InicioFeed(key: _feedKey, usuarioId: widget.usuarioId),
      const ExplorarScreen(),
      const ChatListScreen(), 
      const PerfilScreen(),
    ];

    return Scaffold(
      backgroundColor: ArrendaColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 12.0),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            color: Colors.white,
          ),
        ),
        leadingWidth: 56,
        title: const Text(
          'ArrendaOco',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryGradient,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          NotificationBadge(usuarioId: int.tryParse(widget.usuarioId) ?? 0),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          currentIndex == 0
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: AppGradients.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: ArrendaColors.error.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  heroTag: 'publishBtn',
                  elevation: 0,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrarInmuebleScreen(
                          propietarioId: widget.usuarioId,
                        ),
                      ),
                    );
                    if (result == true) {
                      _feedKey.currentState?.cargarInmuebles();
                    }
                  },
                  icon: const Icon(
                    Icons.add_location_alt_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Publicar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'rocoBtn',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RocoChatScreen()),

              );
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.pets_rounded, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: ArrendaColors.accent.withOpacity(0.15),
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => setState(() => currentIndex = i),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.grey[600]),
              selectedIcon: Icon(
                Icons.home_rounded,
                color: ArrendaColors.primary,
              ),
              label: 'Mis Propiedades',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined, color: Colors.grey[600]),
              selectedIcon: Icon(
                Icons.search_rounded,
                color: ArrendaColors.primary,
              ),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey[600]),
              selectedIcon: Icon(
                Icons.chat_bubble_rounded,
                color: ArrendaColors.primary,
              ),
              label: 'Mensajes',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.grey[600]),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: ArrendaColors.primary,
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
      body: SafeArea(child: pages[currentIndex]),
    );
  }
}

class InicioFeed extends StatefulWidget {
  final String usuarioId;

  const InicioFeed({super.key, required this.usuarioId});

  @override
  State<InicioFeed> createState() => InicioFeedState();
}

class InicioFeedState extends State<InicioFeed> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _inmuebles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    cargarInmuebles();
  }

  Future<void> cargarInmuebles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _api.get('/inmuebles');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _inmuebles = List<Map<String, dynamic>>.from(data);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando mis inmuebles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al conectar con el servidor';
        });
      }
    }
  }

  Future<void> _eliminarInmueble(int id) async {
    try {
      final response = await _api.delete('/inmuebles/$id');
      if (response.statusCode == 200) {
        cargarInmuebles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inmueble eliminado con éxito')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error eliminando inmueble: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: ArrendaColors.accent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: cargarInmuebles,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_inmuebles.isEmpty) {
      return RefreshIndicator(
        onRefresh: cargarInmuebles,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Icon(Icons.house_siding_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Aún no has publicado inmuebles',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cargarInmuebles,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _inmuebles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final i = _inmuebles[index];
          final titulo = i['titulo'] ?? '';
          final descripcion = i['descripcion'] ?? '';
          final precio = Parser.toDouble(i['renta_mensual']);
          final categoria = i['tipo'] ?? '';
          final primeraRuta = i['imagen_portada'];

          return StunningCard(
            padding: EdgeInsets.zero,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleInmuebleScreen(
                    inmueble: i,
                    usuarioId: widget.usuarioId,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: primeraRuta != null
                          ? ImagenDinamica(
                              ruta: primeraRuta,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          categoria.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              titulo.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ArrendaColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$${precio.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ArrendaColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        descripcion.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[200]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegistrarInmuebleScreen(
                                    propietarioId: widget.usuarioId,
                                    inmuebleId: i['id'].toString(),
                                    inmuebleData: i,
                                  ),
                                ),
                              );
                              if (result == true) {
                                cargarInmuebles();
                              }
                            },
                            icon: const Icon(
                              Icons.edit_rounded,
                              size: 20,
                              color: ArrendaColors.accent,
                            ),
                            label: const Text(
                              'Editar',
                              style: TextStyle(
                                color: ArrendaColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    'Eliminar propiedad',
                                    style: TextStyle(
                                      color: ArrendaColors.primary,
                                    ),
                                  ),
                                  content: const Text(
                                    '¿Estás seguro? Esta acción no se puede deshacer.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(
                                          color: ArrendaColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                                if (confirm == true) {
                                  final id = int.tryParse(i['id'].toString()) ?? 0;
                                  if (id > 0) {
                                    await _eliminarInmueble(id);
                                  }
                                }
                            },
                            icon: const Icon(
                              Icons.delete_rounded,
                              size: 20,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.grey),
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
      ),
    );
  }
}

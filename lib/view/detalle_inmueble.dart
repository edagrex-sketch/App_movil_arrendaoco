import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/map_preview_osm.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/services/api_service.dart';

import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:arrendaoco/utils/casting.dart';
import 'package:arrendaoco/view/checkout.dart';
import 'package:arrendaoco/view/chats/chat_screen.dart';
import 'package:arrendaoco/view/roco_chat.dart';

class DetalleInmuebleScreen extends StatefulWidget {
  final Map inmueble;
  final String? usuarioId;
  final bool scrollToReviews;
  final int?
  highlightResenaId; // Nuevo parámetro para resaltar reseña específica

  const DetalleInmuebleScreen({
    super.key,
    required this.inmueble,
    this.usuarioId,
    this.scrollToReviews = false,
    this.highlightResenaId,
  });

  @override
  State<DetalleInmuebleScreen> createState() => _DetalleInmuebleScreenState();
}

class _DetalleInmuebleScreenState extends State<DetalleInmuebleScreen> {
  final ApiService _api = ApiService();
  late PageController _pageController;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _resenas = [];
  double _promedioRating = 0.0;
  int _totalResenas = 0;
  bool _esFavorito = false;

  final ScrollController _scrollController = ScrollController();

  // Mapa para rastrear las GlobalKeys de cada reseña
  final Map<int, GlobalKey> _itemKeys = {};
  int? _highlightedResenaId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _highlightedResenaId = widget.highlightResenaId;

    _cargarResenas();
    _verificarFavorito();

    if (widget.scrollToReviews || widget.highlightResenaId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _scrollToObjective();
        });
      });
    }
  }

  Future<void> _verificarFavorito() async {
    if (SesionActual.usuarioId == null) return;
    try {
      final response = await _api.get('/favoritos');
      if (response.statusCode == 200) {
        final List<dynamic> favs = response.data['data'] ?? [];
        final isCurrentlyFav = favs.any(
          (f) => f['id'] == widget.inmueble['id'],
        );
        if (mounted) {
          setState(() {
            _esFavorito = isCurrentlyFav;
          });
        }
      }
    } catch (e) {
      debugPrint('Error verificando favorito: $e');
    }
  }

  void _scrollToObjective() {
    if (!mounted) return;

    if (_highlightedResenaId != null &&
        _itemKeys.containsKey(_highlightedResenaId)) {
      final key = _itemKeys[_highlightedResenaId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          alignment: 0.5,
        );

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _highlightedResenaId = null);
        });
        return;
      }
    }

    if (widget.scrollToReviews && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _cargarResenas() async {
    // Los datos del inmueble que recibimos de Explorar ya traen las reseñas.
    // Pero si queremos actualizarlas o si venimos de otra parte, podemos recargar el detalle.
    final id = widget.inmueble['id'];
    try {
      final response = await _api.get('/inmuebles/public-detail/$id');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (mounted) {
          setState(() {
            _resenas = List<Map<String, dynamic>>.from(data['resenas'] ?? []);
            _promedioRating =
                (data['promedio_calificacion'] as num?)?.toDouble() ?? 0.0;
            _totalResenas = data['total_resenas'] ?? 0;

            for (var r in _resenas) {
              final rid = r['id'] as int;
              if (!_itemKeys.containsKey(rid)) {
                _itemKeys[rid] = GlobalKey();
              }
            }
          });

          if (_highlightedResenaId != null) {
            Future.delayed(
              const Duration(milliseconds: 500),
              _scrollToObjective,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando reseñas: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ... Resto de métodos auxiliares (Maps, launch, etc) se mantienen ...
  Future<void> _abrirGoogleMaps(double lat, double lng) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Servicios de ubicación desactivados.'),
            ),
          );
        _lanzarMapaSoloDestino(lat, lng);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso de ubicación denegado.')),
            );
          _lanzarMapaSoloDestino(lat, lng);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisos denegados permanentemente.'),
            ),
          );
        _lanzarMapaSoloDestino(lat, lng);
        return;
      }
      Position position = await Geolocator.getCurrentPosition();
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=$lat,$lng&travelmode=driving',
      );
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir el mapa';
      }
    } catch (e) {
      if (mounted) _lanzarMapaSoloDestino(lat, lng);
    }
  }

  Future<void> _lanzarMapaSoloDestino(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el mapa.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inmueble = widget.inmueble;
    final titulo = inmueble['titulo'] ?? '';
    final descripcion = inmueble['descripcion'] ?? '';
    final precio = Parser.toDouble(inmueble['renta_mensual']);
    final categoria = inmueble['tipo'] ?? '';
    final disponible = (inmueble['estatus'] == 'disponible');
    final latitud = Parser.toDouble(inmueble['latitud']);
    final longitud = Parser.toDouble(inmueble['longitud']);

    // En Laravel API 'imagenes' es una lista de objetos {id, url}
    final List<dynamic> imgList = inmueble['imagenes'] ?? [];
    final imagenes = imgList.map((img) => img['url'].toString()).toList();

    // Si no hay imágenes en la lista pero hay portada, añadirla
    if (imagenes.isEmpty && inmueble['imagen_portada'] != null) {
      imagenes.add(inmueble['imagen_portada'].toString());
    }

    final camas = Parser.paramInt(inmueble['habitaciones']);
    final banos = Parser.paramInt(inmueble['banos']);
    final mediosBanos = Parser.paramInt(inmueble['medios_banos']);
    final banoCompartido = inmueble['bano_compartido'] == true ||
        inmueble['bano_compartido'] == 1 ||
        inmueble['bano_compartido'] == "1";
    final metros = Parser.paramInt(inmueble['metros']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (SesionActual.usuarioId != null)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _esFavorito
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: _esFavorito ? MiTema.rojo : Colors.white,
                ),
              ),
              onPressed: () async {
                final id = inmueble['id'];
                try {
                  final response = await _api.post('/favoritos/$id/toggle');
                  if (response.statusCode == 200) {
                    setState(() => _esFavorito = !_esFavorito);
                  }
                } catch (e) {
                  debugPrint('Error toggling favorite: $e');
                }
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            SizedBox(
              height: 350,
              width: double.infinity,
              child: Stack(
                children: [
                  if (imagenes.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentImageIndex = index),
                      itemCount: imagenes.length,
                      itemBuilder: (context, index) {
                        return ImagenDinamica(
                          ruta: imagenes[index],
                          fit: BoxFit.cover,
                          height: 350,
                          width: double.infinity,
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (imagenes.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imagenes.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? MiTema.celeste
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoria.toString().toUpperCase(),
                                style: TextStyle(
                                  color: MiTema.celeste,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                titulo.toString(),
                                style: TextStyle(
                                  height: 1.1,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: MiTema.azul,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${precio.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: MiTema.vino,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: disponible
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: disponible ? Colors.green : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                disponible ? 'Disponible' : 'Ocupado',
                                style: TextStyle(
                                  color: disponible
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    StunningCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.bed_rounded,
                            value: '$camas',
                            label: 'Hab.',
                          ),
                          _VerticalDivider(),
                          _StatItem(
                            icon: Icons.bathtub_outlined,
                            value: banos > 0
                                ? (mediosBanos > 0 ? '$banos + ½' : '$banos')
                                : (mediosBanos > 0 ? '½' : '0'),
                            label: 'Baños',
                          ),
                          _VerticalDivider(),
                          _StatItem(
                            icon: Icons.square_foot_rounded,
                            value: '$metros',
                            label: 'm²',
                          ),
                        ],
                      ),
                    ),
                    if (banoCompartido) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline_rounded,
                                size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Baño compartido',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Descripción',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MiTema.azul,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      descripcion.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Ubicación',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MiTema.azul,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _abrirGoogleMaps(latitud, longitud),
                      child: Stack(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: MapPreviewOsm(lat: latitud, lng: longitud),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions_rounded,
                                    size: 16,
                                    color: MiTema.celeste,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cómo llegar',
                                    style: TextStyle(
                                      color: MiTema.celeste,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: MiTema.celeste,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${latitud.toStringAsFixed(4)}, ${longitud.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildSeccionResenas(context),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pets, color: Colors.orange, size: 25),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Tienes dudas sobre esta casa?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  'Pregúntale a Roco, el experto local.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RocoChatScreen(
                                    inmuebleId: inmueble['id'],
                                    initialMessage: 'Roco, cuéntame de esta propiedad: ${inmueble['titulo']}',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Consultar a Roco'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Espacio para el botón flotante/inferior
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: disponible && SesionActual.usuarioId != null
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () async {
                          final proId = widget.inmueble['usuario_id'] ?? widget.inmueble['propietario_id'];
                          final inmuId = widget.inmueble['id'];
                          if (proId == null) return;
                          
                          try {
                            final response = await _api.post('/chats/iniciar/$proId/$inmuId');
                            if (response.statusCode == 200) {
                              final chatData = response.data['data'];
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatId: chatData['id'],
                                      otroUsuario: chatData['usuario_1'].toString() == SesionActual.usuarioId.toString() 
                                        ? chatData['usuario2'] 
                                        : chatData['usuario1'],
                                      inmueble: chatData['inmueble'],
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint('Error iniciando chat: $e');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: MiTema.azul, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Icon(Icons.chat_bubble_outline_rounded, color: MiTema.azul),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: StunningButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutScreen(inmueble: widget.inmueble),
                            ),
                          );
                        },
                        text: 'RENTAR AHORA',
                        icon: Icons.vpn_key_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : (SesionActual.usuarioId != null && 
             (widget.inmueble['usuario_id'] != null && widget.inmueble['usuario_id'].toString() != SesionActual.usuarioId.toString() ||
              widget.inmueble['propietario_id'] != null && widget.inmueble['propietario_id'].toString() != SesionActual.usuarioId.toString())
            ? Container(
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                child: StunningButton(
                   onPressed: () async {
                        final proId = widget.inmueble['usuario_id'] ?? widget.inmueble['propietario_id'];
                        final inmuId = widget.inmueble['id'];
                        if (proId == null) return;
                        
                        try {
                          final response = await _api.post('/chats/iniciar/$proId/$inmuId');
                          if (response.statusCode == 200) {
                            final chatData = response.data['data'];
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatId: chatData['id'],
                                    otroUsuario: chatData['usuario_1'].toString() == SesionActual.usuarioId.toString() 
                                      ? chatData['usuario2'] 
                                      : chatData['usuario1'],
                                    inmueble: chatData['inmueble'],
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint('Error iniciando chat: $e');
                        }
                      },
                  text: 'CONTACTAR AL DUEÑO',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
              ),
            )
            : null),
    );
  }

  Widget _buildSeccionResenas(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reseñas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: MiTema.azul,
              ),
            ),
            if (SesionActual.usuarioId != null)
              TextButton.icon(
                onPressed: () => _mostrarFormularioResena(),
                icon: Icon(Icons.edit_note_rounded, color: MiTema.celeste),
                label: Text(
                  'Escribir opinión',
                  style: TextStyle(
                    color: MiTema.celeste,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_totalResenas > 0)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _promedioRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: MiTema.azul,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEstrellas(_promedioRating, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Basado en $_totalResenas reseñas',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Sé el primero en opinar sobre este inmueble.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        const SizedBox(height: 20),
        ..._resenas.map((r) => _buildItemResena(r)),
      ],
    );
  }

  Widget _buildItemResena(Map r) {
    final int resenaId = r['id'] as int;
    final nombre = (r['usuario'] ?? 'Anónimo').toString();
    final rating = (r['puntuacion'] ?? 0) as int;
    final comentario = (r['comentario'] ?? '').toString();
    final fechaFormateada = (r['fecha'] ?? '').toString();

    final currentUid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    final esMia = (r['usuario_id'] != null && r['usuario_id'] == currentUid);

    final bool highlighted = _highlightedResenaId == resenaId;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      key: _itemKeys[resenaId],
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? Colors.amber[50] : Colors.white,
        border: highlighted ? Border.all(color: Colors.amber, width: 2) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (highlighted)
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (esMia)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Text('Eliminar'),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'eliminar') _eliminarResena(r['id']);
                  },
                  child: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _buildEstrellas(rating.toDouble(), size: 14),
          const SizedBox(height: 8),
          Text(
            comentario,
            style: TextStyle(color: Colors.grey[800], height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            fechaFormateada,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioResena() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormularioResenaSheet(
        inmuebleId: widget.inmueble['id'] as int,
        usuarioId: int.tryParse(SesionActual.usuarioId ?? '0') ?? 0,
        onResenaGuardada: () {},
      ),
    );
  }

  Future<void> _eliminarResena(int id) async {
    try {
      final response = await _api.delete('/resenas/$id');
      if (response.statusCode == 200) {
        _cargarResenas(); // Recargar
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Reseña eliminada')));
        }
      }
    } catch (e) {
      debugPrint('Error eliminando reseña: $e');
    }
  }

  Widget _buildEstrellas(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star_rounded, color: Colors.amber, size: size);
        } else if (index < rating && (rating - index) >= 0.5) {
          return Icon(Icons.star_half_rounded, color: Colors.amber, size: size);
        } else {
          return Icon(
            Icons.star_outline_rounded,
            color: Colors.grey[300],
            size: size,
          );
        }
      }),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: MiTema.celeste, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: MiTema.azul,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }
}

class _FormularioResenaSheet extends StatefulWidget {
  final int inmuebleId;
  final int usuarioId;
  final VoidCallback onResenaGuardada;
  const _FormularioResenaSheet({
    required this.inmuebleId,
    required this.usuarioId,
    required this.onResenaGuardada,
  });
  @override
  State<_FormularioResenaSheet> createState() => _FormularioResenaSheetState();
}

class _FormularioResenaSheetState extends State<_FormularioResenaSheet> {
  final ApiService _api = ApiService();
  int _puntuacion = 5;
  final TextEditingController _comentarioController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escribe una reseña',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: MiTema.azul,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => _puntuacion = index + 1),
                icon: Icon(
                  index < _puntuacion
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _comentarioController,
            decoration: InputDecoration(
              hintText: 'Comparte tu experiencia...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: StunningButton(
              onPressed: _isLoading ? null : _guardarResena,
              text: _isLoading ? 'Enviando...' : 'Publicar Reseña',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _guardarResena() async {
    if (_comentarioController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await _api.post(
        '/inmuebles/${widget.inmuebleId}/resenas',
        data: {
          'puntuacion': _puntuacion,
          'comentario': _comentarioController.text,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        widget.onResenaGuardada();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Reseña guardada con éxito!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error guardando reseña: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/map_preview_osm.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/services/api_service.dart';

import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:arrendaoco/utils/casting.dart';
import 'package:arrendaoco/view/ver_contrato_solicitud.dart';
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
  bool _tieneRentaActiva = false;
  Map<String, dynamic>? _inmuebleActual;

  final ScrollController _scrollController = ScrollController();

  // Mapa para rastrear las GlobalKeys de cada reseña
  final Map<int, GlobalKey> _itemKeys = {};
  int? _highlightedResenaId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _highlightedResenaId = widget.highlightResenaId;
    _inmuebleActual = Map<String, dynamic>.from(widget.inmueble);

    _cargarResenas();
    _verificarFavorito();
    _verificarRentasActivas();

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

  Future<void> _verificarRentasActivas() async {
    if (SesionActual.usuarioId == null) return;
    try {
      final response = await _api.get('/contratos');
      if (response.statusCode == 200) {
        final List<dynamic> rentas = response.data['data'] ?? [];
        final hasActive = rentas.any((r) =>
            ['activo', 'activa', 'pendiente_aprobacion', 'esperando_pago']
                .contains(r['estado']));
        if (mounted) {
          setState(() {
            _tieneRentaActiva = hasActive;
          });
        }
      }
    } catch (e) {
      debugPrint('Error verificando rentas: $e');
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
            _inmuebleActual = Map<String, dynamic>.from(data);
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
    if (_inmuebleActual == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final inmueble = _inmuebleActual!;
    final titulo = inmueble['titulo'] ?? '';
    final descripcion = inmueble['descripcion'] ?? '';
    final precio = Parser.toDouble(inmueble['renta_mensual']);
    final categoria = inmueble['tipo'] ?? '';
    final disponible = (inmueble['estatus'] == 'disponible');
    final latitud = Parser.toDouble(inmueble['latitud']);
    final longitud = Parser.toDouble(inmueble['longitud']);

    final List<dynamic> imgList = inmueble['imagenes'] ?? [];
    final imagenes = imgList.map((img) => img['url'].toString()).toList();

    if (imagenes.isEmpty && inmueble['imagen_portada'] != null) {
      imagenes.add(inmueble['imagen_portada'].toString());
    }

    final metros = Parser.paramInt(inmueble['metros']);
    final camas = Parser.paramInt(inmueble['habitaciones']);
    final banos = Parser.paramInt(inmueble['banos']);
    final mediosBanos = Parser.paramInt(inmueble['medios_banos']);
    final banoCompartido = inmueble['bano_compartido'] == true ||
        inmueble['bano_compartido'] == 1 ||
        inmueble['bano_compartido'] == "1";
    
    // Nuevos campos de paridad
    final tieneEstacionamiento = (inmueble['tiene_estacionamiento'] == true || inmueble['tiene_estacionamiento'] == 1);
    final estacionamientoCount = Parser.paramInt(inmueble['estacionamiento']);
    final permiteMascotas = (inmueble['permite_mascotas'] == true || inmueble['permite_mascotas'] == 1);
    
    // Procesar Tipos de Mascotas (List o String JSON)
    final List<String> tiposMascotas = inmueble['tipos_mascotas'] is List 
        ? List<String>.from(inmueble['tipos_mascotas']) 
        : (inmueble['tipos_mascotas'] is String ? List<String>.from(jsonDecode(inmueble['tipos_mascotas'])) : []);

    final estadoMobiliario = inmueble['estado_mobiliario'] ?? 'No especificado';
    final esAmueblado = (estadoMobiliario != 'No amueblado' && estadoMobiliario != 'Sin muebles' && estadoMobiliario != 'No especificado');
    
    // Procesar Mapa de Pagos de Servicios (Manejo robusto de tipos)
    Map<String, dynamic> rawPagos = {};
    final rawData = inmueble['pago_servicio'];
    
    if (rawData is Map) {
      rawPagos = Map<String, dynamic>.from(rawData);
    } else if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) {
          rawPagos = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('Error decodificando pago_servicio: $e');
      }
    }
    
    final List<String> serviciosPropietario = [];
    final List<String> serviciosInquilino = [];
    
    rawPagos.forEach((servicio, responsable) {
      if (responsable == null) return;
      final resp = responsable.toString().trim().toLowerCase();
      
      // Si dice Inquilino, se va al inquilino. Cualquier otra cosa (Arrendador, Propietario, Dueño, etc.) al propietario.
      if (resp.contains('inquilino')) {
        serviciosInquilino.add(servicio);
      } else if (resp.isNotEmpty) {
        serviciosPropietario.add(servicio);
      }
    });

    // Fallback: Si el mapa de pagos está vacío pero hay servicios_incluidos (legacy), usarlos
    if (serviciosPropietario.isEmpty && serviciosInquilino.isEmpty) {
      final legacy = inmueble['servicios_incluidos'];
      if (legacy is List) {
        serviciosPropietario.addAll(List<String>.from(legacy));
      }
    }

    final momentoPago = inmueble['momento_pago'] ?? 'No especificado';
    final duracionContrato = inmueble['duracion_contrato_meses'] ?? 0;
    final diasTolerancia = inmueble['dias_tolerancia'] ?? 0;

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
                    const SizedBox(height: 16),
                    
                    // Nueva sección de Amueblado y Estacionamiento más clara
                    Row(
                      children: [
                        Expanded(
                          child: _AmenityCard(
                            icon: Icons.chair_rounded,
                            label: 'Mobiliario',
                            value: esAmueblado ? 'Amueblado' : 'Sin muebles',
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AmenityCard(
                            icon: Icons.directions_car_rounded,
                            label: 'Cajones',
                            value: estacionamientoCount > 0 
                              ? '$estacionamientoCount lugar${estacionamientoCount > 1 ? "es" : ""}' 
                              : 'No incluido',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    if (permiteMascotas)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFD),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pets_rounded, size: 16, color: MiTema.celeste),
                                const SizedBox(width: 8),
                                const Text(
                                  'MASCOTAS PERMITIDAS:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF7D94B5),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tiposMascotas.map((m) => _PetChip(label: m)).toList(),
                            ),
                          ],
                        ),
                      ),
                    
                    if (banoCompartido)
                      Wrap(
                        children: [
                          _FeatureChip(
                            icon: Icons.people_outline_rounded,
                            label: 'Baño compartido',
                            color: Colors.blue[700]!,
                            bgColor: Colors.blue[50]!,
                          ),
                        ],
                      ),
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
                    
                    // TABLA DE SERVICIOS PROPIETARIO VS INQUILINO
                    Text(
                      'Servicios del Inmueble',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MiTema.azul,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildServiciosTable(serviciosPropietario, serviciosInquilino),
                    
                    const SizedBox(height: 30),
                    
                    // SECCION CONTRATO
                    Text(
                      'Condiciones del contrato',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MiTema.azul,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StunningCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _ContractRow(
                            label: 'Duración mínima', 
                            value: '$duracionContrato meses', 
                            icon: Icons.calendar_today_rounded
                          ),
                          const Divider(),
                          _ContractRow(
                            label: 'Fecha de pago', 
                            value: momentoPago, 
                            icon: Icons.payments_rounded
                          ),
                          const Divider(),
                          _ContractRow(
                            label: 'Tolerancia', 
                            value: '$diasTolerancia días', 
                            icon: Icons.timer_rounded
                          ),
                        ],
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
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () async {
                          final inmu = _inmuebleActual ?? widget.inmueble;
                          final proId = inmu['usuario']?['id'] ?? 
                                        inmu['propietario']?['id'] ??
                                        inmu['arrendador']?['id'] ??
                                        inmu['usuario_id'] ?? 
                                        inmu['propietario_id'];
                          final inmuId = inmu['id'];
                          
                          if (proId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se encontró información del propietario. Intenta de nuevo.')),
                            );
                            return;
                          }

                          if (proId.toString() == SesionActual.usuarioId.toString()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No puedes iniciar un chat contigo mismo')),
                            );
                            return;
                          }
                          
                          LottieLoading.showLoadingDialog(context, message: 'Conectando con el propietario...');
                          
                          try {
                            final response = await _api.post('/chats/iniciar/$proId/$inmuId');
                            if (mounted) LottieLoading.hideLoadingDialog(context);
                            
                            if (response.statusCode == 200 || response.statusCode == 201) {
                              final chatData = response.data['data'];
                              final otroUser = chatData['receptor'] ?? chatData['otro_usuario'] ?? {
                                'id': proId,
                                'nombre': 'Propietario',
                              };

                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatId: chatData['id'],
                                      otroUsuario: otroUser,
                                      inmueble: Map<String, dynamic>.from(widget.inmueble),
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              LottieLoading.hideLoadingDialog(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al conectar: $e')),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(color: MiTema.azul, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: MiTema.azul, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Contactar',
                              style: TextStyle(
                                color: MiTema.azul,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: !SesionActual.esPropietario && widget.usuarioId != null
            ? Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _tieneRentaActiva
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.orange[800]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ya tienes una renta activa o solicitud en proceso. Finaliza tu renta actual para solicitar otra.',
                              style: TextStyle(
                                  color: Colors.orange[900],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: disponible
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VerContratoSolicitudScreen(
                                    inmueble: inmueble,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MiTema.azul,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor: MiTema.azul.withOpacity(0.4),
                      ),
                      child: Text(
                        disponible ? 'Rentar ahora' : 'No disponible',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            )
            : StunningButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerContratoSolicitudScreen(inmueble: widget.inmueble),
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

  Widget _buildServiciosTable(List<String> prop, List<String> inq) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7), // Color crema de la imagen
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Cabecera
            Row(
              children: [
                Expanded(
                  child: _buildTableheader(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'PAGA PROPIETARIO',
                    tag: 'INCLUIDO',
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.5)),
                Expanded(
                  child: _buildTableheader(
                    icon: Icons.error_outline_rounded,
                    label: 'PAGA INQUILINO',
                    tag: 'EXTRA',
                  ),
                ),
              ],
            ),
            // Cuerpo
            Container(
              color: Colors.white.withOpacity(0.5),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildServiceList(prop, isOwner: true),
                    ),
                    Container(width: 1, color: const Color(0xFFF3E5C2)),
                    Expanded(
                      child: _buildServiceList(inq, isOwner: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableheader({required IconData icon, required String label, required String tag}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E293B)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(List<String> services, {required bool isOwner}) {
    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('-', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: services.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: const Color(0xFFF3E5C2).withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Icon(
              isOwner ? Icons.check_rounded : Icons.close_rounded, 
              size: 16, 
              color: isOwner ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _PetChip extends StatelessWidget {
  final String label;
  const _PetChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final String nombre;

  const _ServiceItem({required this.nombre});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.check_circle_outline_rounded;
    String low = nombre.toLowerCase();
    
    if (low.contains('wifi') || low.contains('internet')) icon = Icons.wifi_rounded;
    else if (low.contains('agua')) icon = Icons.water_drop_rounded;
    else if (low.contains('luz') || low.contains('electricidad')) icon = Icons.lightbulb_outline_rounded;
    else if (low.contains('gas')) icon = Icons.propane_tank_outlined;
    else if (low.contains('limpieza')) icon = Icons.cleaning_services_rounded;
    else if (low.contains('seguridad')) icon = Icons.security_rounded;
    else if (low.contains('tv') || low.contains('cable')) icon = Icons.tv_rounded;

    return Container(
      width: (MediaQuery.of(context).size.width - 100) / 2, // Mitad de la tarjeta aprox
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: MiTema.celeste.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: MiTema.celeste, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nombre,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MiTema.azul.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AmenityCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MiTema.azul), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _FeatureChip({required this.icon, required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _ContractRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ContractRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: MiTema.azul.withOpacity(0.6), size: 20),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: MiTema.azul)),
        ],
      ),
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

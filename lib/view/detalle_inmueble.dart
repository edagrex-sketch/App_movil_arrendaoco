import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/map_preview_osm.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

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
  late PageController _pageController;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _resenas = [];
  double _promedioRating = 0.0;
  int _totalResenas = 0;
  bool _esFavorito = false;

  late StreamSubscription<List<Map<String, dynamic>>> _resenasSubscription;

  final ScrollController _scrollController = ScrollController();

  // Mapa para rastrear las GlobalKeys de cada reseña
  final Map<int, GlobalKey> _itemKeys = {};
  int? _highlightedResenaId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _highlightedResenaId = widget.highlightResenaId;

    _iniciarEscuchaResenas();
    _verificarFavorito();

    // Lógica para scroll automático diferido
    if (widget.scrollToReviews || widget.highlightResenaId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Delay para permitir que Supabase cargue y la UI renderize los items
        Future.delayed(const Duration(milliseconds: 1000), () {
          _scrollToObjective();
        });
      });
    }
  }

  void _scrollToObjective() {
    if (!mounted) return;

    // Prioridad: Ir a reseña específica
    if (_highlightedResenaId != null &&
        _itemKeys.containsKey(_highlightedResenaId)) {
      final key = _itemKeys[_highlightedResenaId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          alignment: 0.5, // Centrar en pantalla
        );

        // Quitar highlight después de unos segundos
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _highlightedResenaId = null);
        });
        return;
      }
    }

    // Fallback: Ir a la sección general de reseñas
    if (widget.scrollToReviews && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _verificarFavorito() async {
    final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    if (uid == 0) return;
    final iid = widget.inmueble['id'] as int;
    final esFav = await BaseDatos.esFavorito(uid, iid);
    if (mounted) {
      setState(() {
        _esFavorito = esFav;
      });
    }
  }

  void _iniciarEscuchaResenas() {
    final inmuebleId = widget.inmueble['id'];
    _resenasSubscription = Supabase.instance.client
        .from('resenas')
        .stream(primaryKey: ['id'])
        .eq('inmueble_id', inmuebleId)
        .order('fecha', ascending: false)
        .listen((data) {
          if (mounted) {
            setState(() {
              _resenas = data;
              // Asignar keys estables a las reseñas
              for (var r in _resenas) {
                final id = r['id'] as int;
                if (!_itemKeys.containsKey(id)) {
                  _itemKeys[id] = GlobalKey();
                }
              }
              _calcularResumen();
            });

            // Si estábamos esperando datos para hacer scroll, intentarlo de nuevo
            if (_highlightedResenaId != null) {
              Future.delayed(
                const Duration(milliseconds: 500),
                _scrollToObjective,
              );
            }
          }
        });
  }

  void _calcularResumen() {
    if (_resenas.isEmpty) {
      _promedioRating = 0.0;
      _totalResenas = 0;
      return;
    }
    double suma = 0;
    for (var r in _resenas) {
      suma += (r['rating'] as num).toDouble();
    }
    _promedioRating = suma / _resenas.length;
    _totalResenas = _resenas.length;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _resenasSubscription.cancel();
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
    final precio = inmueble['precio'] ?? 0;
    final categoria = inmueble['categoria'] ?? '';
    final disponible =
        inmueble['disponible'] == true || (inmueble['disponible'] as int?) == 1;
    final latitud = (inmueble['latitud'] as num?)?.toDouble() ?? 0.0;
    final longitud = (inmueble['longitud'] as num?)?.toDouble() ?? 0.0;
    final rutasRaw = inmueble['rutas_imagen'] as String? ?? '';
    final rutas = rutasRaw.isEmpty ? [] : rutasRaw.split(',');
    final imagenes = rutas;
    final camas = inmueble['camas'] ?? 2;
    final banos = inmueble['banos'] ?? 1;
    final metros = inmueble['tamano'] ?? '80';

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
                final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
                final iid = inmueble['id'] as int;
                if (_esFavorito) {
                  await BaseDatos.eliminarFavorito(uid, iid);
                } else {
                  await BaseDatos.agregarFavorito(uid, iid);
                }
                setState(() => _esFavorito = !_esFavorito);
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
                            label: 'Camas',
                          ),
                          _VerticalDivider(),
                          _StatItem(
                            icon: Icons.bathtub_outlined,
                            value: '$banos',
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                    'Based on $_totalResenas reviews',
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
    final nombre = (r['usuario_nombre'] ?? 'Anónimo').toString();
    final rating = (r['rating'] ?? 0) as int;
    final comentario = (r['comentario'] ?? '').toString();
    final fechaRaw = (r['fecha'] ?? '').toString();
    String fechaFormateada = fechaRaw;
    if (fechaRaw.length >= 16) {
      fechaFormateada = fechaRaw.substring(0, 16).replaceAll('T', ' ');
    }

    final respuesta = (r['respuesta'] as String? ?? '');
    final currentNombre = SesionActual.nombre.trim();
    final resenaNombre = nombre.trim();

    final currentUid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    final esMia =
        ((r['usuario_id'] != null && r['usuario_id'] == currentUid) ||
        (currentNombre.isNotEmpty && currentNombre == resenaNombre));
    final propietarioId = (widget.inmueble['propietario_id'] as int?) ?? 0;
    final soyPropietario = (currentUid != 0 && currentUid == propietarioId);

    final bool highlighted = _highlightedResenaId == resenaId;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      key:
          _itemKeys[resenaId], // Asignamos la GlobalKey que creamos en el listener
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.amber[50]
            : Colors.white, // Color de highlight suave
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

          if (respuesta.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E7FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.business_center_rounded,
                        size: 16,
                        color: MiTema.azul,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Respuesta del Propietario',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: MiTema.azul,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    respuesta,
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey[800]),
                  ),
                ],
              ),
            ),

          // SECCION CHAT (Mensajes ilimitados)
          _buildChatSection(resenaId),

          if (esMia || soyPropietario)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: StunningButton(
                onPressed: () => _mostrarDialogoChat(resenaId),
                text: 'Ver conversación / Responder',
                backgroundColor: MiTema.celeste,
                textColor: Colors.white,
                isSmall: true,
                icon: Icons.chat_bubble_outline_rounded,
              ),
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

  // ================== CHAT IMPLEMENTATION ==================

  Widget _buildChatSection(int resenaId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: BaseDatos.obtenerMensajesResena(resenaId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Si falla (ej. tabla no existe), ocultamos silenciosamente o mostramos error sutil
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final mensajes = snapshot.data!;
        return Column(
          children: mensajes.map((msg) {
            final esMio =
                msg['usuario_id'] ==
                int.tryParse(SesionActual.usuarioId ?? '0');
            return Container(
              margin: const EdgeInsets.only(top: 8, left: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: esMio
                    ? MiTema.celeste.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: esMio
                      ? MiTema.celeste.withOpacity(0.3)
                      : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        msg['usuario_nombre'] ?? 'Usuario',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: esMio ? MiTema.celeste : Colors.grey[800],
                        ),
                      ),
                      Text(
                        _formatearFechaCorta(msg['fecha']),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg['mensaje'] ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatearFechaCorta(dynamic fecha) {
    if (fecha == null) return '';
    try {
      final dt = DateTime.parse(fecha.toString());
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  void _mostrarDialogoChat(int resenaId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Escribe un mensaje...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context);

              try {
                await BaseDatos.enviarMensajeResena(
                  resenaId: resenaId,
                  usuarioId: int.parse(SesionActual.usuarioId!),
                  usuarioNombre: SesionActual.nombre,
                  mensaje: controller.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mensaje enviado')),
                  );
                }

                // NOTIFICAR
                try {
                  final currentUid =
                      int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
                  final propietarioId =
                      (widget.inmueble['propietario_id'] as int?) ?? 0;

                  final resenaObj = _resenas.firstWhere(
                    (r) => r['id'] == resenaId,
                    orElse: () => {},
                  );
                  final autorId = resenaObj.isNotEmpty
                      ? (resenaObj['usuario_id'] as int?)
                      : 0;

                  int? targetId;
                  if (currentUid == propietarioId)
                    targetId = autorId;
                  else if (currentUid == autorId)
                    targetId = propietarioId;

                  if (targetId != null &&
                      targetId != 0 &&
                      targetId != currentUid) {
                    String tituloNoti = 'Nueva respuesta';
                    if (currentUid == propietarioId) {
                      tituloNoti = 'Respuesta del Propietario';
                    } else {
                      tituloNoti =
                          'Mensaje de ${SesionActual.nombre.isEmpty ? "Usuario" : SesionActual.nombre}';
                    }

                    await NotificacionesService.notificarRespuestaResena(
                      usuarioDestinoId: targetId,
                      nombreInmueble: (widget.inmueble['titulo'] ?? 'Propiedad')
                          .toString(),
                      resenaId: resenaId,
                      mensajeChat: controller.text.trim(),
                      tituloPersonalizado: tituloNoti,
                    );
                  }
                } catch (_) {}
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al enviar')),
                  );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MiTema.azul,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // Mantenemos _eliminarResena abajo...
  Future<void> _eliminarResena(int id) async {
    await BaseDatos.eliminarResena(id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reseña eliminada')));
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
  int _rating = 5;
  final _comentarioCtrl = TextEditingController();
  bool _enviando = false;

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
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating
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
            controller: _comentarioCtrl,
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
              onPressed: _enviando ? null : _guardarResena,
              text: _enviando ? 'Enviando...' : 'Publicar Reseña',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _guardarResena() async {
    if (_comentarioCtrl.text.trim().isEmpty) return;
    setState(() => _enviando = true);
    try {
      final resena = {
        'inmueble_id': widget.inmuebleId,
        'usuario_id': widget.usuarioId,
        'usuario_nombre': SesionActual.nombre,
        'rating': _rating,
        'comentario': _comentarioCtrl.text.trim(),
        'fecha': DateTime.now().toIso8601String(),
      };

      // INSERTAR Y OBTENER ID
      final nuevoId = await BaseDatos.insertarResena(resena);

      widget.onResenaGuardada();
      if (mounted) Navigator.pop(context);

      // Enviar Notificación al Propietario (Arrendador)
      // Aqui necesitamos el ID del propietario del inmueble.
      // Como no lo tenemos directo en props de este widget, lo ideal es pasarlo.
      // Pero 'DetalleInmuebleScreen' lo tiene.
      // Solución rápida: Asumimos que la BD trigger o el padre maneja esto.

      // MEJOR: Enviamos la notificación aqui mismo usando un servicio helper que busque el propietario si hace falta,
      // O simplemente asumimos que en el flujo real deberíamos tener el dato.
      // Voy a llamar al servicio asumiendo que el padre lo gestiona o lo dejamos aqui:

      // Para efectos de demo, llamaré NotificacionesService,
      // PERO necesito inmuebleId y el ID del dueño.
      // Como este widget sheet es hijo, no tiene acceso directo fácil al mapa 'inmueble' completo si no se lo pasamos.
      // Pasaré la responsabilidad al padre (DetalleScreen) de notificar si es necesario,
      // PERO ya habíamos puesto lógica en DetalleInmueble antes. La recupero.

      // Recuperando lógica de notificación desde el contexto padre o global:
      // (Verificar implementación en DetalleInmuebleScreen donde se llama a este sheet)

      // ... En DetalleInmuebleScreen._mostrarFormularioResena ...
      // Ah, ahí no pase el callback de notificación.
      // Lo haré directo aqui buscando el propietario:

      final inmuebleData = await BaseDatos.obtenerInmueblePorId(
        widget.inmuebleId,
      );
      if (inmuebleData != null) {
        final propietarioId = inmuebleData['propietario_id'] as int;
        final nombreInmueble = inmuebleData['titulo']; // o direccion
        final autoresNombre = SesionActual.nombre;

        await NotificacionesService.notificarNuevaResena(
          propietarioId: propietarioId,
          inmuebleId: widget.inmuebleId,
          nombreInmueble: nombreInmueble,
          autorNombre: autoresNombre,
          comentario: _comentarioCtrl.text.trim(),
          resenaId: nuevoId, // ¡AQUI ESTA LA CLAVE para el deep linking!
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar reseña')),
        );
      }
    }
  }
}

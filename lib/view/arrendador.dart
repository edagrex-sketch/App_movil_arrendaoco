import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/theme/arrenda_colors.dart';
import 'package:arrendaoco/view/registrar_inmueble.dart';
import 'package:arrendaoco/view/explorar.dart';
import 'package:arrendaoco/view/perfil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/services/fcm_service.dart';
import 'package:arrendaoco/view/widgets/notification_badge.dart';
import 'package:arrendaoco/utils/casting.dart';
import 'package:arrendaoco/widgets/premium_navbar.dart';
import 'package:arrendaoco/widgets/animated_rocco_fab.dart';
import 'package:arrendaoco/view/solicitudes_renta_screen.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/services/firebase_chat_service.dart';
import 'dart:async';

class ArrendadorScreen extends StatefulWidget {
  final String usuarioId;

  const ArrendadorScreen({super.key, required this.usuarioId});

  @override
  State<ArrendadorScreen> createState() => ArrendadorScreenState();
}

class ArrendadorScreenState extends State<ArrendadorScreen> {
  int currentIndex = 0;
  final GlobalKey<InicioFeedState> _feedKey = GlobalKey<InicioFeedState>();
  final List<String> _titulos = ['Propiedades', 'Explorar', 'Perfil'];

  @override
  void initState() {
    super.initState();
    final uid = int.tryParse(widget.usuarioId) ?? 0;
    if (uid > 0) FCMService.initialize(uid);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _vincularCuentaStripe() async {
    final ApiService api = ApiService();
    try {
      final res = await api.get('/stripe/onboarding-link');
      if (res.statusCode == 200 && res.data['url'] != null) {
        final url = Uri.parse(res.data['url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Configuración de Pagos'),
                content: const Text('¿Has completado la vinculación con Stripe?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aún no')),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _verificarEstadoStripe();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: ArrendaColors.primary, foregroundColor: Colors.white),
                    child: const Text('Verificar'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error Stripe: $e');
    }
  }

  Future<void> _verificarEstadoStripe() async {
    final ApiService api = ApiService();
    try {
      final res = await api.get('/stripe/check-status');
      if (res.statusCode == 200 && (res.data['completed'] ?? false)) {
        setState(() => SesionActual.stripeOnboardingCompleted = true);
      }
    } catch (e) {
      debugPrint('Error status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      InicioFeed(key: _feedKey, usuarioId: widget.usuarioId),
      const ExplorarScreen(),
      const PerfilScreen(),
    ];

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain, color: Colors.white),
            ),
            title: Text(_titulos[currentIndex], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
            flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryGradient)),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [NotificationBadge(usuarioId: int.tryParse(widget.usuarioId) ?? 0)],
          ),
          bottomNavigationBar: PremiumFloatingNavBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => setState(() => currentIndex = i),
            items: const [
              StunningNavItem(icon: Icons.home_work_outlined, selectedIcon: Icons.home_work_rounded, label: 'Propiedades'),
              StunningNavItem(icon: Icons.search_outlined, selectedIcon: Icons.search_rounded, label: 'Explorar'),
              StunningNavItem(icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: 'Perfil'),
            ],
          ),
          body: SafeArea(child: pages[currentIndex]),
        ),
        const AnimatedRoccoFab(),
      ],
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
  StreamSubscription? _refreshSub;

  @override
  void initState() {
    super.initState();
    cargarInmuebles();
    _initRealtime();
  }

  void _initRealtime() {
    _refreshSub = FirebaseChatService.globalRefreshStream.listen((event) {
      if (mounted) {
        debugPrint('🔄 REFRESH REALTIME: $event');
        cargarInmuebles();
      }
    });
  }

  @override
  void dispose() {
    _refreshSub?.cancel();
    super.dispose();
  }

  Future<void> cargarInmuebles() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await _api.get('/inmuebles');
      if (mounted && response.statusCode == 200) {
        // Manejar tanto si viene envuelto en 'data' como si es la lista directa
        final dynamic rawData = response.data;
        List<dynamic> data = [];
        if (rawData is Map && rawData.containsKey('data')) {
          data = rawData['data'] ?? [];
        } else if (rawData is List) {
          data = rawData;
        }

        final myId = widget.usuarioId.toString().trim();
        final sessionUid = SesionActual.usuarioId?.toString().trim();

        setState(() {
          // Intentar filtrar primero de forma estricta
          var filtered = List<Map<String, dynamic>>.from(data).where((i) {
            final pId = (i['propietario_id'] ?? i['usuario_id'] ?? i['arrendador_id'] ?? i['user_id'] ?? '').toString().trim();
            final pNombre = (i['propietario_nombre'] ?? i['vendedor_nombre'] ?? '').toString().toLowerCase().trim();
            final miNombre = SesionActual.nombre.toLowerCase().trim();

            if (pId == myId || pId == sessionUid || pId == SesionActual.publicId) return true;
            if (miNombre.isNotEmpty && pNombre == miNombre) return true;
            return false;
          }).toList();

          // Si el filtro estricto da 0 pero hay datos, y el usuario es el dueño legítimo (según lo que reporta),
          // mostramos la lista completa para evitar que se quede en blanco, 
          // ya que el endpoint /inmuebles en modo Arrendador debería estar pre-filtrado por el servidor
          // o al menos darnos lo que el usuario espera ver.
          if (filtered.isEmpty && data.isNotEmpty) {
            _inmuebles = List<Map<String, dynamic>>.from(data);
          } else {
            _inmuebles = filtered;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'Error al conectar con el servidor'; });
    }
  }

  Future<void> _eliminarInmueble(int id) async {
    try {
      final response = await _api.delete('/inmuebles/$id');
      if (response.statusCode == 200) {
        cargarInmuebles();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inmueble eliminado con éxito')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Eliminada la animación de carga según solicitud
    }

    if (_errorMessage != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_errorMessage!), const SizedBox(height: 16), ElevatedButton(onPressed: cargarInmuebles, child: const Text('Reintentar'))]));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!SesionActual.stripeOnboardingCompleted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configura tus pagos primero.')));
             return;
          }
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrarInmuebleScreen(propietarioId: widget.usuarioId)));
          if (result == true) cargarInmuebles();
        },
        backgroundColor: ArrendaColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('PUBLICAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: cargarInmuebles,
        child: _inmuebles.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _inmuebles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildInmuebleCard(_inmuebles[index]),
                );
              },
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
      const Icon(Icons.house_siding_rounded, size: 80, color: Colors.grey),
      const SizedBox(height: 16),
      const Center(child: Text('Aún no has publicado inmuebles', style: TextStyle(color: Colors.grey))),
    ]);
  }

  Widget _buildInmuebleCard(Map<String, dynamic> i) {
    final titulo = i['titulo'] ?? 'Propiedad';
    final precio = Parser.toDouble(i['renta_mensual']);
    final estatus = (i['estatus'] ?? i['estado'] ?? 'DISPONIBLE').toString().toUpperCase();
    final isRentado = estatus == 'RENTADO';

    return StunningCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetalleInmuebleScreen(inmueble: i, usuarioId: widget.usuarioId))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ImagenDinamica(ruta: i['imagen_portada'] ?? i['imagen'], height: 200, width: double.infinity, fit: BoxFit.cover),
          Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: isRentado ? Colors.orange : ArrendaColors.primary, borderRadius: BorderRadius.circular(12)), child: Text(estatus, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
        ]),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ArrendaColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis)), Text('\$${precio.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ArrendaColors.accent))]),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(i['direccion'] ?? 'S/D', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))]),
            const SizedBox(height: 16),
            Row(children: [
              _buildFeatureItem(Icons.king_bed_outlined, i['habitaciones']?.toString() ?? '0'),
              const SizedBox(width: 15),
              _buildFeatureItem(Icons.bathtub_outlined, i['banos']?.toString() ?? '0'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: ArrendaColors.accent), 
                onPressed: () {
                  if (isRentado) {
                    LottieFeedback.showError(context, message: 'No se puede editar un inmueble con renta activa.');
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrarInmuebleScreen(propietarioId: widget.usuarioId, inmuebleId: i['id'].toString(), inmuebleData: i))).then((_) => cargarInmuebles());
                }
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
                onPressed: () {
                  if (isRentado) {
                    LottieFeedback.showError(context, message: 'No se puede eliminar un inmueble que está rentado actualmente.');
                    return;
                  }
                  _confirmarEliminar(i);
                }
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildFeatureItem(IconData icon, String value) => Row(children: [Icon(icon, size: 18, color: Colors.blueGrey), const SizedBox(width: 6), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))]);

  Future<void> _confirmarEliminar(Map<String, dynamic> i) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Eliminar Propiedad'), content: const Text('¿Estás seguro de eliminar este inmueble?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí'))]));
    if (ok == true) _eliminarInmueble(int.tryParse(i['id'].toString()) ?? 0);
  }
}

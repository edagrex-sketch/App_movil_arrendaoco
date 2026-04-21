import 'package:flutter/material.dart';
import 'package:arrendaoco/services/pusher_service.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_renta.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';

import 'package:arrendaoco/theme/arrenda_colors.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';

class MisRentasScreen extends StatefulWidget {
  const MisRentasScreen({super.key});

  @override
  State<MisRentasScreen> createState() => _MisRentasScreenState();
}

class _MisRentasScreenState extends State<MisRentasScreen> {
  List<Map<String, dynamic>> _rentas = [];
  List<Map<String, dynamic>> _eventos = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  int _currentRentIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _initRealtime();
  }

  void _initRealtime() {
    final usuarioId = SesionActual.usuarioId;
    final uid = int.tryParse(usuarioId ?? '0') ?? 0;
    
    if (uid > 0) {
      // Iniciar el servicio de oídos globales
      PusherService().init(onMessageReceived: (_) {}, chatId: 'global').then((_) {
        PusherService().listenToPersonalUpdates(
          usuarioId: uid,
          onRentalUpdated: (contratoId, nuevoEstatus) {
            if (mounted) {
              // Si nos avisan que algo cambió, refrescamos todo el tablero
              _refreshData();
              // Opcional: Mostrar una notificación pequeña en pantalla
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tu renta #$contratoId ahora está $nuevoEstatus'),
                  backgroundColor: MiTema.celeste,
                ),
              );
            }
          },
        );
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final usuarioId = SesionActual.usuarioId;
    final uid = int.tryParse(usuarioId ?? '0') ?? 0;

    try {
      final rentas = await BaseDatos.obtenerRentasPorInquilino(uid);
      final eventos = await BaseDatos.obtenerEventosPorUsuario(uid);

      if (mounted) {
        setState(() {
          _rentas = rentas;
          _eventos = eventos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: ArrendaColors.accent),
      );
    }

    // Filtrar por estado
    // Filtrar por estado real del servidor
    final solicitudes = _rentas
        .where((r) => 
          r['estado'] == 'pendiente_aprobacion' || 
          r['estado'] == 'esperando_pago' ||
          r['estado'] == 'pendiente'
        )
        .toList();
        
    final activas = _rentas.where((r) => r['estado'] == 'activa').toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Sección de Rentas (Solicitudes y Activas)
          if (_rentas.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: [
                // 1. SOLICITUDES PENDIENTES
                if (solicitudes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_unread_rounded,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Solicitudes Pendientes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: MiTema.azul,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: solicitudes.length,
                    itemBuilder: (context, index) =>
                        _buildSolicitudCard(solicitudes[index]),
                  ),
                  const SizedBox(height: 30),
                ],

                // 2. RENTAS ACTIVAS
                if (activas.isNotEmpty) ...[
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MiTema.azul.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.home_work_rounded,
                            color: MiTema.azul,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tus Rentas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: MiTema.azul,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activas.length,
                    itemBuilder: (context, index) {
                      return _buildRentaCard(activas[index]);
                    },
                  ),
                ],
              ],
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _aceptarRenta(int id, int arrendadorId) async {
    await BaseDatos.actualizarEstadoRenta(id, 'activa');

    // Notify landlord
    await BaseDatos.crearNotificacion(
      usuarioId: arrendadorId,
      titulo: 'Renta Aceptada',
      mensaje: 'El inquilino ha aceptado la solicitud de renta.',
    );

    // Refresh visual state
    if (mounted) {
      _refreshData();
      await NotificacionesService.mostrarNotificacion(
        titulo: 'Solicitud Aceptada',
        cuerpo: 'Has aceptado la solicitud de renta correctamente.',
      );
      LottieFeedback.showSuccess(context, message: '¡Renta activada!');
    }
  }

  Future<void> _rechazarRenta(int id, int arrendadorId) async {
    await BaseDatos.actualizarEstadoRenta(id, 'rechazada');
    await BaseDatos.crearNotificacion(
      usuarioId: arrendadorId,
      titulo: 'Renta Rechazada',
      mensaje: 'El inquilino ha rechazado la solicitud de renta.',
    );

    if (mounted) {
      _refreshData();
      LottieFeedback.showError(context, message: 'Solicitud rechazada');
    }
  }

  Widget _buildSolicitudCard(Map<String, dynamic> renta) {
    final titulo = renta['inmueble_titulo'] ?? 'Propiedad';
    final m = renta['monto_mensual'];
    final double monto = double.tryParse(m?.toString() ?? '0') ?? 0.0;
    final arrendador = renta['arrendador_nombre'] ?? 'Arrendador';
    final rutasRaw = (renta['rutas_imagen'] as String?) ?? '';
    final imageUrls = rutasRaw.isNotEmpty ? rutasRaw.split(',') : [];
    final primeraUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con gradiente de "Solicitud"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'NUEVA INVITACIÓN DE RENTA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen circular grande
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: primeraUrl != null
                        ? ImagenDinamica(ruta: primeraUrl, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[100],
                            child: Icon(Icons.home, color: Colors.grey[400]),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MiTema.azul,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enviada por $arrendador',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money_rounded,
                            color: MiTema.vino,
                            size: 20,
                          ),
                          Text(
                            monto.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: MiTema.vino,
                            ),
                          ),
                          Text(
                            '/mes',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Acciones
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'ESPERANDO APROBACIÓN DEL DUEÑO',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentaCard(Map<String, dynamic> renta) {
    final titulo = renta['inmueble_titulo'] ?? '';
    final direccion = renta['inmueble_direccion'] ?? 'Sin dirección';
    final m = renta['monto_mensual'];
    final double monto = double.tryParse(m?.toString() ?? '0') ?? 0.0;
    final diaPago = renta['dia_pago'] ?? 19;
    final estado = renta['estado'] ?? 'activa';
    final rutasRaw = (renta['rutas_imagen'] as String?) ?? '';
    final imageUrls = rutasRaw.isNotEmpty ? rutasRaw.split(',') : [];
    final primeraUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
    
    final fechaInicio = renta['fecha_inicio'] ?? '-';
    final fechaFin = renta['fecha_fin'] ?? '-';
    final arrendadorNombre = renta['arrendador_nombre'] ?? 'Propietario';
    final arrendadorFoto = renta['arrendador_foto'] as String?;

    final esActiva = estado == 'activa';
    final esCancelada = estado == 'cancelada' || estado == 'finalizada' || estado == 'rechazada';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetalleRentaScreen(rentaId: renta['id'].toString()),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen Header con Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: primeraUrl != null
                      ? ImagenDinamica(ruta: primeraUrl, height: 160, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 160, color: Colors.grey[200]),
                ),
                if (esCancelada)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Cancelada', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MiTema.azul),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.red[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          direccion,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // GRID DE INFORMACIÓN (Clon de la Web)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildMiniInfo('RENTA MENSUAL', '\$${monto.toStringAsFixed(2)}'),
                            const SizedBox(width: 20),
                            _buildMiniInfo('DÍA DE PAGO', diaPago.toString()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildMiniInfo('INICIO RENTA', fechaInicio),
                            const SizedBox(width: 20),
                            _buildMiniInfo('FIN RENTA', fechaFin),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DUEÑO
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: ImagenDinamica(ruta: arrendadorFoto ?? '', width: 28, height: 28, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Propietario', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            Text(arrendadorNombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // BOTONES
                  ElevatedButton(
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleRentaScreen(rentaId: renta['id'].toString()),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MiTema.azul,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ver Propiedad'),
                  ),
                  if (esCancelada) ... [
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('Renta cancelada/finalizada', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: MiTema.azul)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 50,
                color: MiTema.celeste,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes rentas activas',
              style: TextStyle(
                color: MiTema.azul,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las invitaciones de renta aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(List<Map<String, dynamic>> events) {
    final firstDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
      ),
      itemCount: daysInMonth + startWeekday,
      itemBuilder: (context, index) {
        if (index < startWeekday) return const SizedBox();

        final day = index - startWeekday + 1;
        final isToday =
            day == DateTime.now().day &&
            _selectedDate.month == DateTime.now().month &&
            _selectedDate.year == DateTime.now().year;

        return Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isToday ? MiTema.celeste : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.grey[700],
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            // Dots for events
            if (_hasEventOnDay(
              day,
              _selectedDate.month,
              _selectedDate.year,
              events,
            ))
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : MiTema.vino,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final titulo = evento['titulo'] ?? '';
    final fechaRaw = evento['fecha'] ?? '';
    DateTime? dateObj = DateTime.tryParse(fechaRaw);
    final dayStr = dateObj != null ? dateObj.day.toString() : '';
    final monthStr = dateObj != null ? _getMonthShortName(dateObj.month) : '';

    return StunningCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MiTema.celeste.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  dayStr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MiTema.celeste,
                  ),
                ),
                Text(
                  monthStr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: MiTema.azul,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: MiTema.azul,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
            onPressed: () async {
              await BaseDatos.eliminarEvento(evento['id'] as int);
              _refreshData();
            },
          ),
        ],
      ),
    );
  }

  bool _hasEventOnDay(
    int day,
    int month,
    int year,
    List<Map<String, dynamic>> events,
  ) {
    for (var e in events) {
      final fecha = DateTime.tryParse(e['fecha'].toString());
      if (fecha != null &&
          fecha.day == day &&
          fecha.month == month &&
          fecha.year == year) {
        return true;
      }
    }
    return false;
  }

  void _mostrarFormularioEvento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormularioEventoSheet(),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }

  String _getMonthShortName(int month) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    return months[month - 1];
  }

  Widget _buildEventList() {
    if (_eventos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No hay eventos este mes',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _eventos.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildEventoCard(_eventos[index]);
      },
    );
  }
}

class _FormularioEventoSheet extends StatefulWidget {
  @override
  State<_FormularioEventoSheet> createState() => _FormularioEventoSheetState();
}

class _FormularioEventoSheetState extends State<_FormularioEventoSheet> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime _fechaEvento = DateTime.now();
  bool _guardando = false;

  Future<void> _guardar() async {
    if (_tituloController.text.isEmpty) return;
    setState(() => _guardando = true);

    final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    await BaseDatos.agregarEvento({
      'usuario_id': uid,
      'titulo': _tituloController.text,
      'descripcion': _descripcionController.text,
      'fecha': _fechaEvento.toIso8601String(),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard padding
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nuevo Recordatorio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MiTema.azul,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          StunningTextField(
            controller: _tituloController,
            label: 'Título',
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 16),
          StunningTextField(
            controller: _descripcionController,
            label: 'Descripción (Opcional)',
            icon: Icons.description_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Fecha:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: MiTema.azul,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaEvento,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: MiTema.azul,
                            onPrimary: Colors.white,
                            onSurface: MiTema.azul,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _fechaEvento = picked);
                  }
                },
                icon: Icon(Icons.calendar_today_rounded, color: MiTema.celeste),
                label: Text(
                  '${_fechaEvento.day}/${_fechaEvento.month}/${_fechaEvento.year}',
                  style: TextStyle(
                    color: MiTema.azul,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          StunningButton(
            onPressed: _guardando ? null : _guardar,
            text: _guardando ? 'GUARDANDO...' : 'GUARDAR EVENTO',
            icon: _guardando ? null : Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }
}

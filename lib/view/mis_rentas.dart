import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_renta.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'package:arrendaoco/theme/arrenda_colors.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';

class MisRentasScreen extends StatefulWidget {
  const MisRentasScreen({super.key});

  @override
  State<MisRentasScreen> createState() => _MisRentasScreenState();
}

class _MisRentasScreenState extends State<MisRentasScreen> {
  Stream<List<Map<String, dynamic>>>? _rentasStream;
  Stream<List<Map<String, dynamic>>>? _eventosStream;

  DateTime _selectedDate = DateTime.now();
  int _currentRentIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final usuarioId = SesionActual.usuarioId;
    final uid = int.tryParse(usuarioId ?? '0') ?? 0;

    setState(() {
      // Stream de Rentas (Inquilino)
      _rentasStream = Supabase.instance.client
          .from('rentas')
          .stream(primaryKey: ['id'])
          .eq('inquilino_id', uid)
          .order('fecha_inicio', ascending: false)
          .map(
            (list) => list,
          ) // Passthrough simple necesario a veces para casting
          .asyncMap((list) async {
            // Enriquecer datos con relaciones (Inmueble, Arrendador)
            final enrichedList = <Map<String, dynamic>>[];
            for (var r in list) {
              final rentaId = r['id'];
              final fullData = await BaseDatos.obtenerRentaPorId(rentaId);
              if (fullData != null) {
                enrichedList.add(fullData);
              }
            }
            return enrichedList;
          });

      // Stream Calendario
      _eventosStream = Supabase.instance.client
          .from('calendario')
          .stream(primaryKey: ['id'])
          .eq('usuario_id', uid)
          .order('fecha', ascending: true);
    });
  }

  Widget build(BuildContext context) {
    return _rentasStream == null
        ? Center(child: CircularProgressIndicator(color: ArrendaColors.accent))
        : SingleChildScrollView(
            child: Column(
              children: [
                // Sección de Rentas (Solicitudes y Activas)
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _rentasStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: MiTema.celeste,
                          ),
                        ),
                      );
                    }

                    final todasLasRentas = snapshot.data ?? [];

                    // Filtrar por estado
                    final solicitudes = todasLasRentas
                        .where((r) => r['estado'] == 'pendiente')
                        .toList();
                    final activas = todasLasRentas
                        .where((r) => r['estado'] == 'activa')
                        .toList();

                    if (todasLasRentas.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Column(
                      children: [
                        // 1. SOLICITUDES PENDIENTES
                        if (solicitudes.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mark_email_unread_rounded,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Solicitudes Pendientes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: MiTema.azul,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: solicitudes.length,
                            itemBuilder: (context, index) =>
                                _buildSolicitudCard(solicitudes[index]),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 2. RENTAS ACTIVAS (Carousel)
                        if (activas.isNotEmpty) ...[
                          SizedBox(
                            height: 340,
                            child: PageView.builder(
                              controller: PageController(viewportFraction: 0.9),
                              onPageChanged: (index) {
                                setState(() => _currentRentIndex = index);
                              },
                              itemCount: activas.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: _buildRentaCard(activas[index]),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (activas.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                activas.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentRentIndex == index
                                        ? MiTema.celeste
                                        : Colors.grey[300],
                                  ),
                                ),
                              ),
                            ),
                        ] else if (solicitudes.isEmpty) ...[
                          // Si no hay activas ni solicitudes (pero la lista total no estaba vacía - caso rechazada?)
                          _buildEmptyState(),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // CALENDARIO PREMIUM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: MiTema.vino,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Calendario de Pagos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MiTema.azul,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _eventosStream,
                    builder: (context, snapshot) {
                      final events = snapshot.data ?? [];
                      return Column(
                        children: [
                          // Header Calendario
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.chevron_left_rounded,
                                    color: MiTema.azul,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(
                                        _selectedDate.year,
                                        _selectedDate.month - 1,
                                      );
                                    });
                                  },
                                ),
                                Text(
                                  '${_getMonthName(_selectedDate.month).toUpperCase()} ${_selectedDate.year}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: MiTema.azul,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.chevron_right_rounded,
                                    color: MiTema.azul,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(
                                        _selectedDate.year,
                                        _selectedDate.month + 1,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          _buildCalendarGrid(events),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Lista de Eventos / Pagos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        color: MiTema.celeste,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Próximos Eventos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MiTema.azul,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _eventosStream,
                  builder: (context, snapshot) {
                    final eventos = snapshot.data ?? [];

                    // TODO: Aquí podríamos mezclar con los días de pago de las rentas activas
                    // Pero por ahora mostramos los eventos reales

                    if (eventos.isEmpty) {
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
                      itemCount: eventos.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildEventoCard(eventos[index]);
                      },
                    );
                  },
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
    final monto = renta['monto_mensual'] ?? 0;
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
                            '$monto',
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
                  child: OutlinedButton(
                    onPressed: () => _rechazarRenta(
                      renta['id'] as int,
                      renta['arrendador_id'] as int,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Rechazar',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _aceptarRenta(
                      renta['id'] as int,
                      renta['arrendador_id'] as int,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: MiTema.azul,
                      shadowColor: MiTema.azul.withOpacity(0.4),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'ACEPTAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
    final monto = renta['monto_mensual'] ?? 0;
    final diaPago = renta['dia_pago'] ?? 1;
    final estado = renta['estado'] ?? 'activa';
    final rutasRaw = (renta['rutas_imagen'] as String?) ?? '';
    final imageUrls = rutasRaw.isNotEmpty ? rutasRaw.split(',') : [];
    final primeraUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    final esActiva = estado == 'activa';

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
        margin: const EdgeInsets.only(bottom: 12, top: 12),
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
            // Imagen Header
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    child: primeraUrl != null
                        ? ImagenDinamica(ruta: primeraUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey[200]),
                  ),
                ),
                // Badge Estado
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: esActiva ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: esActiva
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MiTema.azul,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MiTema.celeste.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: MiTema.celeste,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Día de corte',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Día $diaPago de cada mes',
                            style: TextStyle(
                              fontSize: 14,
                              color: MiTema.azul,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monto Mensual',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '\$$monto',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: MiTema.vino,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppGradients.accentGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: MiTema.celeste.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
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

import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_renta.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/services/pusher_service.dart';

import 'package:arrendaoco/widgets/stunning_widgets.dart';

import 'package:arrendaoco/theme/app_gradients.dart';
import 'dart:async';
import 'package:arrendaoco/services/notificaciones_service.dart';

class GestionarRentasScreen extends StatefulWidget {
  const GestionarRentasScreen({super.key});

  @override
  State<GestionarRentasScreen> createState() => _GestionarRentasScreenState();
}

class _GestionarRentasScreenState extends State<GestionarRentasScreen> {
  List<Map<String, dynamic>> _rentas = [];
  List<Map<String, dynamic>> _eventos = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();

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
      PusherService().init(onMessageReceived: (_) {}, chatId: 'global').then((_) {
        PusherService().listenToPersonalUpdates(
          usuarioId: uid,
          onRentalUpdated: (contratoId, nuevoEstatus) {
            if (mounted) {
              _refreshData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Actualización en Renta #$contratoId: $nuevoEstatus'),
                  backgroundColor: MiTema.azul,
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
      final rentas = await BaseDatos.obtenerRentasPorArrendador(uid);
      final eventos = await BaseDatos.obtenerEventosPorUsuario(uid);

      if (mounted) {
        setState(() {
          _rentas = rentas;
          _eventos = eventos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error refrescando datos: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initCalendarStream() {
    // Ya no es necesario con el nuevo flujo de datos
  }

  double _calcularIngresosTotales(List<Map<String, dynamic>> rentas) {
    double total = 0;
    for (var renta in rentas) {
      if (renta['estado'] == 'activa') {
        final m = renta['monto_mensual'];
        final double monto = double.tryParse(m?.toString() ?? '0') ?? 0.0;
        total += monto;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryGradient,
          ),
        ),
        title: const Text(
          'Dashboard Arrendador',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            tooltip: 'Eliminar TODAS las rentas',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¿Eliminar TODO?'),
                  content: const Text(
                    'Esta acción borrará todas tus rentas, pagos y eventos asociados. No se puede deshacer.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'ELIMINAR',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
                await BaseDatos.eliminarTodasLasRentas(uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Todas las rentas eliminadas'),
                    ),
                  );
                  _refreshData();
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Nuevo evento',
            onPressed: () => _mostrarFormularioEvento(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: MiTema.celeste))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI CARDS
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Ingresos Mensuales',
                            '\$${_calcularIngresosTotales(_rentas).toStringAsFixed(0)}',
                            Icons.attach_money_rounded,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Rentas Activas',
                            '${_rentas.where((r) => r['estado'] == 'activa').length}',
                            Icons.home_work_rounded,
                            MiTema.celeste,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de Rentas (Horizontal Scroll)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tus Propiedades',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MiTema.azul,
                          ),
                        ),
                        TextButton(
                          onPressed: _mostrarFormularioNuevaRenta,
                          child: Text(
                            '+ Nueva Renta',
                            style: TextStyle(
                              color: MiTema.vino,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_rentas.isEmpty)
                    _buildEmptyState()
                  else
                    SizedBox(
                      height: 360,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _rentas.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: 280,
                              child: _buildRentaCard(_rentas[index]),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // CALENDARIO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: MiTema.azul,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Calendario de Cobros',
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
                    child: Column(
                      children: [
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
                        _buildCalendarGrid(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lista de Eventos (Timeline)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Acciones Pendientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MiTema.azul,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_eventos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      child: Text(
                        'No hay acciones pendientes.',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  else
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _eventos.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildEventoCard(_eventos[index]);
                      },
                    ),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioNuevaRenta,
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppGradients.accentGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: MiTema.celeste.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.add_home_work_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'NUEVA RENTA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: MiTema.azul,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MiTema.celeste.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_home_work_rounded,
                size: 40,
                color: MiTema.celeste,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes propiedades',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MiTema.azul,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera renta ahora.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentaCard(Map<String, dynamic> renta) {
    final titulo = renta['inmueble_titulo'] ?? '';
    final inquilino = renta['inquilino_nombre'] ?? 'Sin asignar';
    final m = renta['monto_mensual'];
    final double monto = double.tryParse(m?.toString() ?? '0') ?? 0.0;
    final estado = renta['estado'] ?? 'activa';
    final rutasRaw = (renta['rutas_imagen'] as String?) ?? '';
    final imageUrls = rutasRaw.isNotEmpty ? rutasRaw.split(',') : [];
    final primeraUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    final esActiva = estado == 'activa';
    final esRechazada = estado == 'rechazada';

    Color badgeColor = esActiva
        ? Colors.green
        : (esRechazada ? Colors.red : Colors.orange);

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
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Imagen Header
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    child: primeraUrl != null
                        ? ImagenDinamica(ruta: primeraUrl, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[100],
                            child: Icon(Icons.home, color: Colors.grey[300]),
                          ),
                  ),
                ),
                // Badge Estado
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
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
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: badgeColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Info Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MiTema.azul,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          inquilino,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[100], height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Renta mensual',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${monto.toString()}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: MiTema.vino,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: MiTema.celeste.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: MiTema.celeste,
                        ),
                      ),
                    ],
                  ),
                  if (esActiva) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[400],
                          backgroundColor: Colors.red[50],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.block_rounded, size: 18),
                        label: const Text(
                          'Finalizar Contrato',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _confirmarTerminarRenta(renta),
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

  Widget _buildCalendarGrid() {
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
        childAspectRatio: 1.0,
      ),
      itemCount: daysInMonth + startWeekday,
      itemBuilder: (context, index) {
        if (index < startWeekday) return const SizedBox();
        final day = index - startWeekday + 1;
        final isToday =
            day == DateTime.now().day &&
            _selectedDate.month == DateTime.now().month &&
            _selectedDate.year == DateTime.now().year;

        // Aquí podríamos checar eventos para poner puntitos
        // final hasEvent = ...

        return Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: isToday ? AppGradients.accentGradient : null,
              borderRadius: BorderRadius.circular(12),
              border: isToday ? null : Border.all(color: Colors.transparent),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isToday ? Colors.white : Colors.grey[700],
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
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

  void _mostrarFormularioEvento(BuildContext context) {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    DateTime fechaSeleccionada = DateTime.now();
    String tipoSeleccionado = 'accion';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nueva Acción',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MiTema.azul,
                ),
              ),
              const SizedBox(height: 24),
              StunningTextField(
                controller: tituloController,
                label: 'Título',
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 16),
              StunningTextField(
                controller: descripcionController,
                label: 'Descripción (opcional)',
                icon: Icons.description_rounded,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: tipoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Tipo de evento',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: Icon(
                            Icons.category_rounded,
                            color: MiTema.celeste,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'accion',
                            child: Text('Acción'),
                          ),
                          DropdownMenuItem(
                            value: 'recordatorio',
                            child: Text('Recordatorio'),
                          ),
                          DropdownMenuItem(
                            value: 'visita',
                            child: Text('Visita programada'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            tipoSeleccionado = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setModalState(() {
                              fechaSeleccionada = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[500]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Fecha: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              StunningButton(
                onPressed: () async {
                  if (tituloController.text.trim().isEmpty) {
                    return;
                  }

                  final usuarioId = SesionActual.usuarioId;
                  if (usuarioId == null) return;

                  final uid = int.tryParse(usuarioId) ?? 0;
                  await BaseDatos.agregarEvento({
                    'usuario_id': uid,
                    'titulo': tituloController.text.trim(),
                    'descripcion': descripcionController.text.trim(),
                    'fecha': fechaSeleccionada.toIso8601String(),
                    'tipo': tipoSeleccionado,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    _refreshData();
                  }
                },
                text: 'GUARDAR ACCIÓN',
              ),
            ],
          ),
        );
      },
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

  void _mostrarFormularioNuevaRenta() async {
    final parentContext = context;
    final usuarioId = SesionActual.usuarioId;
    if (usuarioId == null) return;

    // Obtener inmuebles del arrendador
    final uid = int.tryParse(usuarioId) ?? 0;
    final inmuebles = await BaseDatos.obtenerInmueblesPorPropietario(uid);

    if (!mounted) return;

    if (inmuebles.isEmpty) {
      if (mounted) {
        LottieFeedback.showError(
          context,
          message: 'Primero debes publicar un inmueble',
        );
      }
      return;
    }

    final inquilinoIdController = TextEditingController();
    final montoController = TextEditingController();
    final diaPagoController = TextEditingController(text: '5');
    String? inmuebleSeleccionado;
    DateTime fechaInicio = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva Renta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MiTema.azul,
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Inmueble',
                            border: OutlineInputBorder(),
                          ),
                          value: inmuebleSeleccionado,
                          items: inmuebles.map((i) {
                            return DropdownMenuItem<String>(
                              value: (i['id']).toString(),
                              child: Text(i['titulo'].toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              inmuebleSeleccionado = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: inquilinoIdController,
                          decoration: const InputDecoration(
                            labelText: 'ID del Inquilino',
                            hintText: 'Ej: 15',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: montoController,
                          decoration: const InputDecoration(
                            labelText: 'Monto Mensual',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: diaPagoController,
                          decoration: const InputDecoration(
                            labelText: 'Día de Pago',
                            hintText: '1-31',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: Icon(
                            Icons.calendar_today,
                            color: MiTema.azul,
                          ),
                          title: const Text('Fecha de Inicio'),
                          subtitle: Text(
                            '${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}',
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fechaInicio,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setModalState(() {
                                fechaInicio = picked;
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validaciones iniciales
                      if (inmuebleSeleccionado == null) {
                        FocusScope.of(context).unfocus();
                        LottieFeedback.showError(
                          context,
                          message: 'Selecciona un inmueble',
                        );
                        return;
                      }

                      final inquilinoId = int.tryParse(
                        inquilinoIdController.text.trim(),
                      );
                      if (inquilinoId == null) {
                        FocusScope.of(context).unfocus();
                        LottieFeedback.showError(
                          context,
                          message: 'ID de inquilino inválido',
                        );
                        return;
                      }

                      final monto = double.tryParse(
                        montoController.text.trim(),
                      );
                      if (monto == null || monto <= 0) {
                        FocusScope.of(context).unfocus();
                        LottieFeedback.showError(
                          context,
                          message: 'Monto inválido',
                        );
                        return;
                      }

                      final diaPago = int.tryParse(
                        diaPagoController.text.trim(),
                      );
                      if (diaPago == null || diaPago < 1 || diaPago > 31) {
                        FocusScope.of(context).unfocus();
                        LottieFeedback.showError(
                          context,
                          message: 'Día de pago inválido (1-31)',
                        );
                        return;
                      }

                      // Mostrar Loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (c) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );

                      try {
                        // 1. Validar Usuario (Async)
                        final usuarioData = await BaseDatos.obtenerUsuario(
                          inquilinoId,
                        );

                        // Cerrar Loading antes de validar resultado
                        if (context.mounted) Navigator.pop(context);

                        if (usuarioData == null) {
                          if (context.mounted)
                            LottieFeedback.showError(
                              context,
                              message: 'Usuario no encontrado',
                            );
                          return;
                        }
                        if (usuarioData['rol'] != 'inquilino') {
                          if (context.mounted)
                            LottieFeedback.showError(
                              context,
                              message: 'El usuario no es inquilino',
                            );
                          return;
                        }

                        // Volver a mostrar Loading para la creación
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (c) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }

                        // 2. Operaciones BD
                        final iid = int.tryParse(inmuebleSeleccionado!) ?? 0;

                        // Crear
                        final rentaId = await BaseDatos.crearRenta({
                          'inmueble_id': iid,
                          'arrendador_id': uid,
                          'inquilino_id': inquilinoId,
                          'fecha_inicio': fechaInicio.toIso8601String(),
                          'fecha_fin': fechaInicio
                              .add(const Duration(days: 365))
                              .toIso8601String(), // Default 1 year
                          'monto_mensual': monto,
                          'dia_pago': diaPago,
                          'deposito': monto, // Default 1 month
                          'estado': 'pendiente',
                        });

                        // Pagos
                        await BaseDatos.generarPagosMensuales(
                          rentaId,
                          fechaInicio,
                          12,
                          monto,
                        );

                        // Notificaciones
                        await BaseDatos.crearNotificacion(
                          usuarioId: inquilinoId,
                          titulo: 'Solicitud de Renta',
                          mensaje:
                              'Nueva solicitud de renta por \$$monto. Revisa tus rentas.',
                          tipo: 'renta',
                        );

                        await BaseDatos.crearNotificacion(
                          usuarioId: uid,
                          titulo: 'Solicitud Enviada',
                          mensaje:
                              'Solicitud enviada al inquilino correctamente.',
                          tipo: 'sistema',
                        );

                        // Notificación local inmediata
                        await NotificacionesService.mostrarNotificacion(
                          titulo: 'Renta Creada',
                          cuerpo:
                              'La solicitud de renta ha sido creada exitosamente.',
                        );

                        // 3. Éxito: Cerrar Todo y Feedback
                        if (context.mounted)
                          Navigator.pop(context); // Cerrar Loading
                        if (context.mounted)
                          Navigator.pop(context); // Cerrar Formulario

                        if (parentContext.mounted) {
                          _refreshData(); // Llamada al método de la clase State
                          LottieFeedback.showSuccess(
                            parentContext,
                            message: 'Renta creada exitosamente',
                          );
                        }
                      } catch (e) {
                        // 4. Error: Cerrar Todo y Feedback
                        debugPrint('Error: $e');
                        // Intenta cerrar loading si está abierto (puede fallar si no estaba abierto, pero Navigator.pop es seguro usualmente si checkeamos canPop o solo pop)
                        // Asumimos que loading estaba abierto.
                        if (context.mounted)
                          Navigator.pop(context); // Cerrar Loading
                        if (context.mounted)
                          Navigator.pop(context); // Cerrar Formulario

                        if (parentContext.mounted) {
                          LottieFeedback.showError(
                            parentContext,
                            message: 'Error: ${e.toString()}',
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MiTema.celeste,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Crear Renta'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmarTerminarRenta(Map<String, dynamic> renta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Finalizar Contrato?'),
        content: const Text(
          'Esta acción dará de baja la renta actual y notificará al inquilino. ¿Estás seguro de que deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              await _terminarRenta(renta);
            },
            child: const Text(
              'Finalizar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _terminarRenta(Map<String, dynamic> renta) async {
    try {
      final rentaId = renta['id'];
      final inquilinoId = renta['inquilino_id'];

      // 1. Actualizar estado en BD
      await BaseDatos.actualizarEstadoRenta(rentaId, 'finalizada');

      // 2. Notificar al inquilino (Push local si procede, y BD)
      if (inquilinoId != null) {
        await BaseDatos.crearNotificacion(
          usuarioId: inquilinoId,
          titulo: 'Renta Finalizada',
          mensaje:
              'El arrendador ha finalizado el contrato de renta de "${renta['inmueble_titulo']}".',
          tipo: 'renta_finalizada',
        );
      }

      if (mounted) {
        // 3. Feedback visual
        LottieFeedback.showSuccess(
          context,
          message: 'Contrato finalizado correctamente',
        );
        // 4. Refrescar lista
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        LottieFeedback.showError(context, message: 'Error al finalizar: $e');
      }
    }
  }
}

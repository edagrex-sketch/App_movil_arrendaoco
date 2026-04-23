import 'package:flutter/material.dart';
import 'package:arrendaoco/services/firebase_chat_service.dart';
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
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/utils/casting.dart';
import 'package:arrendaoco/theme/arrenda_colors.dart';
import 'package:arrendaoco/view/solicitudes_renta_screen.dart';

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
  String _selectedCategory = 'Todas';
  StreamSubscription? _refreshSub;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _initRealtime();
  }

  void _initRealtime() {
    _refreshSub = FirebaseChatService.globalRefreshStream.listen((event) {
      if (mounted) {
        debugPrint('🔄 REFRESH RENTAS: $event');
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _refreshSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final ApiService api = ApiService();
    try {
      final responseContratos = await api.get('/contratos');
      final responseEventos = await BaseDatos.obtenerEventosPorUsuario(int.tryParse(SesionActual.usuarioId ?? '0') ?? 0);
      if (mounted) {
        setState(() {
          if (responseContratos.statusCode == 200) {
            _rentas = List<Map<String, dynamic>>.from(responseContratos.data['data'] ?? []);
          }
          _eventos = List<Map<String, dynamic>>.from(responseEventos);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calcularIngresosTotales(List<Map<String, dynamic>> rentas) {
    double total = 0;
    for (var renta in rentas) {
      if (renta['estado'] == 'activa') {
        final double monto = Parser.toDouble(renta['monto_mensual']);
        total += monto;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final todas = _rentas;
    final activas = _rentas.where((r) => r['estado'] == 'activa').toList();
    final porFirmar = _rentas.where((r) => r['estado'] == 'disponible').toList();
    final solicitudes = _rentas.where((r) => r['estado'] == 'pendiente_aprobacion').toList();

    List<Map<String, dynamic>> itemsParaMostrar = [];
    if (_selectedCategory == 'Todas') itemsParaMostrar = todas;
    else if (_selectedCategory == 'Activas') itemsParaMostrar = activas;
    else if (_selectedCategory == 'Por Firmar') itemsParaMostrar = porFirmar;
    else if (_selectedCategory == 'Solicitudes') itemsParaMostrar = solicitudes;

    return Scaffold(
      backgroundColor: ArrendaColors.background,
      body: _isLoading
          ? const Center(child: LottieFeedback(type: FeedbackType.success, message: 'Analizando tus rentas...'))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    stretch: true,
                    backgroundColor: ArrendaColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(gradient: AppGradients.primaryGradient),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            const Text('Balance General', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              '\$${_calcularIngresosTotales(_rentas).toStringAsFixed(0)} MXN',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                              child: Text('${activas.length} Rentas Activas', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(icon: const Icon(Icons.add_task_rounded), onPressed: () => _mostrarFormularioEvento(context)),
                    ],
                  ),
                  
                  // FILTROS (DISEÑO MOVIDO DE ARRENDADOR)
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Row(children: [
                        _buildFilterChip('Todas', Icons.grid_view_rounded, todas.length),
                        _buildFilterChip('Activas', Icons.house_rounded, activas.length),
                        _buildFilterChip('Por Firmar', Icons.description_rounded, porFirmar.length),
                        _buildFilterChip('Solicitudes', Icons.notification_important_rounded, solicitudes.length),
                      ]),
                    ),
                  ),

                  if (itemsParaMostrar.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No hay rentas en esta categoría', style: TextStyle(color: Colors.grey[400])),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildRentaCard(itemsParaMostrar[index]),
                          ),
                          childCount: itemsParaMostrar.length,
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: ArrendaColors.primary, size: 24),
                          const SizedBox(width: 10),
                          const Text('Planificador de Cobros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ArrendaColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1))),
                                Text('${_getMonthName(_selectedDate.month).toUpperCase()} ${_selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, color: ArrendaColors.primary)),
                                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1))),
                              ],
                            ),
                          ),
                          _buildCalendarGrid(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (_eventos.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Text('Acciones Pendientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ArrendaColors.primary)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildEventoCard(_eventos[index])),
                          childCount: _eventos.length,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, int count) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ArrendaColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? ArrendaColors.primary : Colors.grey[200]!),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Text(count.toString(), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey[400])),
          ]
        ]),
      ),
    );
  }

  Widget _buildRentaCard(Map<String, dynamic> renta) {
    final titulo = renta['inmueble_titulo'] ?? renta['inmueble']?['titulo'] ?? 'Propiedad';
    final inquilino = renta['inquilino_nombre'] ?? renta['inquilino']?['nombre'] ?? 'Sin inquilino';
    final precio = Parser.toDouble(renta['monto_mensual']);
    final estado = (renta['estado'] ?? 'activa').toString();
    final fotoPropiedad = renta['rutas_imagen'] ?? renta['inmueble_imagen'] ?? (renta['inmueble'] is Map ? renta['inmueble']['imagen_portada'] : null);
    
    Color statusColor = Colors.green;
    String statusText = 'RENTADO';
    
    if (estado == 'pendiente_aprobacion') { 
      statusColor = Colors.orange; 
      statusText = 'ACEPTAR RESERVA'; 
    } else if (estado == 'disponible') { 
      statusColor = Colors.blue; 
      statusText = 'DESCARGAR PDF'; 
    } else if (estado == 'pdf_descargado') { 
      statusColor = Colors.indigo; 
      statusText = 'POR ACTIVAR'; 
    } else if (estado == 'finalizada' || estado == 'finalizado') {
      statusColor = Colors.grey;
      statusText = 'FINALIZADA';
    } else if (estado == 'rechazada' || estado == 'rechazado') {
      statusColor = Colors.red;
      statusText = 'RECHAZADA';
    } else if (estado == 'activa' || estado == 'activo') {
      statusColor = Colors.green;
      statusText = 'RENTADO';
    }

    return StunningCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetalleRentaScreen(rentaId: renta['id'].toString())),
        ).then((_) => _refreshData());
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del inmueble mas grande (130px de ancho)
            Container(
              width: 130,
              height: 120, // Aseguramos una altura mínima mayor
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                child: Hero(
                  tag: 'renta_img_${renta['id']}',
                  child: ImagenDinamica(
                    ruta: fotoPropiedad?.toString() ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      titulo,
                      maxLines: 2, // Permitir 2 líneas para ver mejor el título
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ArrendaColors.primary, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person_pin_rounded, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  inquilino,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${precio.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ArrendaColors.accent),
                        ),
                      ],
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

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.0),
      itemCount: daysInMonth + startWeekday,
      itemBuilder: (context, index) {
        if (index < startWeekday) return const SizedBox();
        final day = index - startWeekday + 1;
        final isToday = day == DateTime.now().day && _selectedDate.month == DateTime.now().month && _selectedDate.year == DateTime.now().year;
        return Center(
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: isToday ? AppGradients.accentGradient : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(color: isToday ? Colors.white : Colors.grey[700], fontWeight: isToday ? FontWeight.bold : FontWeight.w500, fontSize: 14),
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
            decoration: BoxDecoration(color: ArrendaColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(dayStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ArrendaColors.primary)),
                Text(monthStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ArrendaColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ArrendaColors.primary))),
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
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Nueva Acción', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ArrendaColors.primary)),
              const SizedBox(height: 24),
              StunningTextField(controller: tituloController, label: 'Título', icon: Icons.title_rounded),
              const SizedBox(height: 16),
              StunningTextField(controller: descripcionController, label: 'Descripción (opcional)', icon: Icons.description_rounded),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: tipoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Tipo de evento',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.category_rounded, color: ArrendaColors.primary),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'accion', child: Text('Acción')),
                          DropdownMenuItem(value: 'recordatorio', child: Text('Recordatorio')),
                          DropdownMenuItem(value: 'visita', child: Text('Visita programada')),
                        ],
                        onChanged: (value) => setModalState(() => tipoSeleccionado = value!),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: fechaSeleccionada, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (picked != null) setModalState(() => fechaSeleccionada = picked);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[400]!)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.grey),
                              const SizedBox(width: 12),
                              Text('Fecha: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  if (tituloController.text.trim().isEmpty) return;
                  final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
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

  void _mostrarFormularioNuevaRenta() async {
    final parentContext = context;
    final uid = int.tryParse(SesionActual.usuarioId ?? '0') ?? 0;
    final inmuebles = await BaseDatos.obtenerInmueblesPorPropietario(uid);

    if (!mounted) return;
    if (inmuebles.isEmpty) {
      LottieFeedback.showError(context, message: 'Primero debes publicar un inmueble');
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nueva Renta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ArrendaColors.primary)),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Inmueble', border: OutlineInputBorder()),
                          value: inmuebleSeleccionado,
                          items: inmuebles.map((i) => DropdownMenuItem<String>(value: (i['id']).toString(), child: Text(i['titulo'].toString()))).toList(),
                          onChanged: (value) => setModalState(() => inmuebleSeleccionado = value),
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: inquilinoIdController, decoration: const InputDecoration(labelText: 'ID del Inquilino', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        TextField(controller: montoController, decoration: const InputDecoration(labelText: 'Monto Mensual', prefixText: '\$', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        TextField(controller: diaPagoController, decoration: const InputDecoration(labelText: 'Día de Pago (1-31)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.calendar_today, color: ArrendaColors.primary),
                          title: const Text('Fecha de Inicio'),
                          subtitle: Text('${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}'),
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: fechaInicio, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (picked != null) setModalState(() => fechaInicio = picked);
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
                      if (inmuebleSeleccionado == null || inquilinoIdController.text.isEmpty) return;
                      final inquilinoId = int.tryParse(inquilinoIdController.text);
                      final monto = double.tryParse(montoController.text);
                      final diaPago = int.tryParse(diaPagoController.text);
                      if (inquilinoId == null || monto == null || diaPago == null) return;

                      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.white)));
                      try {
                        final usuarioData = await BaseDatos.obtenerUsuario(inquilinoId);
                        if (context.mounted) Navigator.pop(context);
                        if (usuarioData == null || usuarioData['rol'] != 'inquilino') {
                          if (context.mounted) LottieFeedback.showError(context, message: 'Inquilino no válido');
                          return;
                        }

                        final rentaId = await BaseDatos.crearRenta({
                          'inmueble_id': int.parse(inmuebleSeleccionado!),
                          'arrendador_id': uid,
                          'inquilino_id': inquilinoId,
                          'fecha_inicio': fechaInicio.toIso8601String(),
                          'fecha_fin': fechaInicio.add(const Duration(days: 365)).toIso8601String(),
                          'monto_mensual': monto,
                          'dia_pago': diaPago,
                          'deposito': monto,
                          'estado': 'pendiente',
                        });
                        await BaseDatos.generarPagosMensuales(rentaId, fechaInicio, 12, monto);
                        if (context.mounted) Navigator.pop(context); // Close form
                        if (parentContext.mounted) {
                          _refreshData();
                          LottieFeedback.showSuccess(parentContext, message: 'Solicitud enviada');
                        }
                      } catch (e) {
                         if (context.mounted) Navigator.pop(context); 
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: ArrendaColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Crear Renta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        content: const Text('Se dará de baja la renta actual. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(context); _terminarRenta(renta); }, child: const Text('Finalizar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Future<void> _terminarRenta(Map<String, dynamic> renta) async {
    try {
      await BaseDatos.actualizarEstadoRenta(renta['id'], 'finalizada');
      if (mounted) {
        LottieFeedback.showSuccess(context, message: 'Finalizada');
        _refreshData();
      }
    } catch (e) {
      if (mounted) LottieFeedback.showError(context, message: 'Error: $e');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.add_home_work_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Sin propiedades en gestión', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }

  String _getMonthShortName(int month) {
    const months = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    return months[month - 1];
  }
}

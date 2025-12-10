import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarioInquilinoScreen extends StatefulWidget {
  const CalendarioInquilinoScreen({super.key});

  @override
  State<CalendarioInquilinoScreen> createState() =>
      _CalendarioInquilinoScreenState();
}

class _CalendarioInquilinoScreenState extends State<CalendarioInquilinoScreen> {
  late Stream<List<Map<String, dynamic>>> _eventosStream;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final usuarioId = SesionActual.usuarioId;
    final uid = int.tryParse(usuarioId ?? '0') ?? 0;
    _eventosStream = Supabase.instance.client
        .from('calendario')
        .stream(primaryKey: ['id'])
        .eq('usuario_id', uid)
        .order('fecha', ascending: true);
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
          'Calendario de Visitas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendario simple
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
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
                  Row(
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
                  const SizedBox(height: 20),
                  _buildCalendarGrid(),
                ],
              ),
            ),

            // Lista de eventos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.event_note_rounded, color: MiTema.vino, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Próximas visitas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: MiTema.vino,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _eventosStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: MiTema.celeste),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final eventos = snapshot.data ?? [];
                final eventosVisita = eventos
                    .where((e) => e['tipo'] == 'visita')
                    .toList();

                if (eventosVisita.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes visitas programadas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: eventosVisita.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final evento = eventosVisita[index];
                    return _buildEventoCard(evento);
                  },
                );
              },
            ),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioEvento,
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
              Icon(Icons.add_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'AGENDAR VISITA',
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth + startWeekday,
      itemBuilder: (context, index) {
        if (index < startWeekday) {
          return const SizedBox();
        }

        final day = index - startWeekday + 1;
        final isToday =
            day == DateTime.now().day &&
            _selectedDate.month == DateTime.now().month &&
            _selectedDate.year == DateTime.now().year;

        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isToday ? MiTema.celeste : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday
                ? null
                : Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: isToday ? Colors.white : Colors.grey[700],
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final titulo = evento['titulo'] ?? '';
    final descripcion = evento['descripcion'] ?? '';
    final fechaRaw = evento['fecha'] ?? '';

    // Parse Date for nicer display
    DateTime? dateObj = DateTime.tryParse(fechaRaw);
    final dayStr = dateObj != null ? dateObj.day.toString() : '';
    final monthStr = dateObj != null ? _getMonthShortName(dateObj.month) : '';

    return StunningCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 70,
              decoration: BoxDecoration(
                color: MiTema.celeste.withOpacity(0.1),
                border: Border(right: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayStr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: MiTema.celeste,
                    ),
                  ),
                  Text(
                    monthStr.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MiTema.azul,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: MiTema.azul,
                      ),
                    ),
                    if (descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.grey[400]),
              onPressed: () async {
                await BaseDatos.eliminarEvento(evento['id'] as int);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioEvento() {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    DateTime fechaSeleccionada = DateTime.now();

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
                'Agendar Visita',
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
                  return InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaSeleccionada,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: MiTema.celeste,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Fecha: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
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
                    'tipo': 'visita',
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                text: 'GUARDAR VISITA',
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
}

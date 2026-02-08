import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'dart:async';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalleRentaScreen extends StatefulWidget {
  final String rentaId;

  const DetalleRentaScreen({super.key, required this.rentaId});

  @override
  State<DetalleRentaScreen> createState() => _DetalleRentaScreenState();
}

class _DetalleRentaScreenState extends State<DetalleRentaScreen> {
  late Future<Map<String, dynamic>?> _futureRenta;
  late Stream<List<Map<String, dynamic>>> _pagosStream;

  @override
  void initState() {
    super.initState();
    final rId = int.tryParse(widget.rentaId) ?? 0;
    _futureRenta = BaseDatos.obtenerRentaPorId(rId);
    _pagosStream = Supabase.instance.client
        .from('pagos_renta')
        .stream(primaryKey: ['id'])
        .eq('contrato_id', rId)
        .order('fecha_limite', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    final usuarioId = SesionActual.usuarioId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryGradient,
          ),
        ),
        title: const Text(
          'Detalles del Contrato',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _futureRenta,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final renta = snapshot.data;
          if (renta == null) {
            return const Center(child: Text('Renta no encontrada'));
          }

          final esArrendador = usuarioId == renta['arrendador_id'];
          final monto = renta['monto_mensual'] ?? 0;
          final diaPago = renta['dia_pago'] ?? 0;
          final estado = renta['estado'] ?? 'activa';
          final inmuebleTitulo = renta['inmueble_titulo'] ?? 'Inmueble';
          final imageUrlsRaw = (renta['rutas_imagen'] as String?) ?? '';
          final imageUrls = imageUrlsRaw.isNotEmpty
              ? imageUrlsRaw.split(',')
              : [];
          final primeraUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

          final otraParte = esArrendador
              ? renta['inquilino_nombre']
              : renta['arrendador_nombre'];
          final otraParteLabel = esArrendador ? 'Inquilino' : 'Arrendador';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    if (primeraUrl != null)
                      Hero(
                        tag: 'renta_img_${renta['id']}',
                        child: ImagenDinamica(
                          ruta: primeraUrl,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 250,
                        width: double.infinity,
                        color: MiTema.azul.withOpacity(0.1),
                        child: Icon(Icons.home, size: 80, color: MiTema.azul),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
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
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Text(
                        inmuebleTitulo,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.attach_money_rounded,
                                label: 'Mensualidad',
                                value: '\$$monto',
                                color: MiTema.vino,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.calendar_today_rounded,
                                label: 'Día de Pago',
                                value: 'Día $diaPago',
                                color: MiTema.celeste,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.person_rounded,
                          label: otraParteLabel,
                          value: otraParte.toString(),
                          color: MiTema.azul,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: estado == 'activa'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: estado == 'activa'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                estado == 'activa'
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                color: estado == 'activa'
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Estado: ${estado.toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: estado == 'activa'
                                      ? Colors.green
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Historial de Pagos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: MiTema.azul,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _pagosStream,
                          builder: (context, pagoSnapshot) {
                            if (pagoSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: MiTema.celeste,
                                ),
                              );
                            }

                            final pagos = pagoSnapshot.data ?? [];

                            if (pagos.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'No hay pagos registrados aún.',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pagos.length,
                              separatorBuilder: (c, i) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final pago = pagos[index];
                                return _buildPagoCard(pago, esArrendador);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MiTema.azul,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagoCard(Map<String, dynamic> pago, bool esArrendador) {
    final mes = pago['mes'] ?? '';
    final anio = pago['anio'] ?? 0;
    final monto = pago['monto'] ?? 0;
    final estado = pago['estado'] ?? 'pendiente';
    final fechaPago = pago['fecha_pago'];

    Color estadoColor;
    IconData estadoIcon;
    switch (estado) {
      case 'pagado':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'atrasado':
        estadoColor = Colors.red;
        estadoIcon = Icons.error;
        break;
      default:
        estadoColor = Colors.orange;
        estadoIcon = Icons.pending;
    }

    return StunningCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(estadoIcon, color: estadoColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$mes $anio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: MiTema.azul,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$$monto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MiTema.vino,
                    fontSize: 14,
                  ),
                ),
                if (fechaPago != null)
                  Text(
                    'Pagado el ${DateTime.parse(fechaPago).day}/${DateTime.parse(fechaPago).month}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          if (esArrendador && estado == 'pendiente')
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.check_rounded, color: Colors.white),
                onPressed: () async {
                  await BaseDatos.actualizarEstadoPago(
                    pago['id'] as int,
                    'pagado',
                    DateTime.now().toIso8601String(),
                  );
                  if (mounted) {
                    LottieFeedback.showSuccess(
                      context,
                      message: 'Pago registrado correctamente',
                    );
                  }
                },
              ),
            )
          else if (estado == 'pagado')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: const Text(
                'PAGADO',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

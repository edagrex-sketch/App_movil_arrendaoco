import 'dart:io';
import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';

class DetalleRentaScreen extends StatefulWidget {
  final int rentaId;

  const DetalleRentaScreen({super.key, required this.rentaId});

  @override
  State<DetalleRentaScreen> createState() => _DetalleRentaScreenState();
}

class _DetalleRentaScreenState extends State<DetalleRentaScreen> {
  late Future<Map<String, dynamic>?> _futureRenta;
  late Future<List<Map<String, dynamic>>> _futurePagos;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    _futureRenta = BaseDatos.obtenerRentaPorId(widget.rentaId);
    _futurePagos = BaseDatos.obtenerPagosPorRenta(widget.rentaId);
  }

  @override
  Widget build(BuildContext context) {
    final usuarioId = SesionActual.usuarioId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalle de Renta'),
        backgroundColor: MiTema.azul,
        foregroundColor: MiTema.crema,
        centerTitle: true,
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
          final titulo = renta['inmueble_titulo'] ?? '';
          final monto = renta['monto_mensual'] ?? 0;
          final diaPago = renta['dia_pago'] ?? 0;
          final estado = renta['estado'] ?? 'activa';
          final rutas = (renta['rutas_imagen'] as String?) ?? '';
          final primeraRuta = rutas.isNotEmpty ? rutas.split('|').first : null;

          final otraParte = esArrendador
              ? renta['inquilino_nombre']
              : renta['arrendador_nombre'];
          final otraParteLabel = esArrendador ? 'Inquilino' : 'Arrendador';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (primeraRuta != null)
                  Image.file(
                    File(primeraRuta),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: MiTema.azul,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.attach_money,
                        label: 'Monto Mensual',
                        value: '\$$monto',
                        color: MiTema.vino,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.calendar_today,
                        label: 'Día de Pago',
                        value: 'Día $diaPago de cada mes',
                        color: MiTema.celeste,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.person,
                        label: otraParteLabel,
                        value: otraParte.toString(),
                        color: MiTema.azul,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.info_outline,
                        label: 'Estado',
                        value: estado.toUpperCase(),
                        color: estado == 'activa' ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Historial de Pagos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: MiTema.azul,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _futurePagos,
                        builder: (context, pagoSnapshot) {
                          if (pagoSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final pagos = pagoSnapshot.data ?? [];

                          if (pagos.isEmpty) {
                            return const Text('No hay pagos registrados');
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pagos.length,
                            itemBuilder: (context, index) {
                              final pago = pagos[index];
                              return _buildPagoCard(pago, esArrendador);
                            },
                          );
                        },
                      ),
                    ],
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: estadoColor.withOpacity(0.2),
          child: Icon(estadoIcon, color: estadoColor),
        ),
        title: Text(
          '$mes $anio',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$$monto'),
            if (fechaPago != null)
              Text(
                'Pagado: ${DateTime.parse(fechaPago).day}/${DateTime.parse(fechaPago).month}/${DateTime.parse(fechaPago).year}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: esArrendador && estado == 'pendiente'
            ? IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () async {
                  await BaseDatos.actualizarEstadoPago(
                    pago['id'] as int,
                    'pagado',
                    DateTime.now().toIso8601String(),
                  );
                  setState(() => _cargarDatos());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pago marcado como pagado')),
                    );
                  }
                },
              )
            : null,
      ),
    );
  }
}

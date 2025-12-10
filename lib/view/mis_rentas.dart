import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/detalle_renta.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';

class MisRentasScreen extends StatefulWidget {
  const MisRentasScreen({super.key});

  @override
  State<MisRentasScreen> createState() => _MisRentasScreenState();
}

class _MisRentasScreenState extends State<MisRentasScreen> {
  late Future<List<Map<String, dynamic>>> _futureRentas;

  @override
  void initState() {
    super.initState();
    _cargarRentas();
  }

  void _cargarRentas() {
    final usuarioId = SesionActual.usuarioId;
    if (usuarioId != null) {
      final uid = int.tryParse(usuarioId) ?? 0;
      _futureRentas = BaseDatos.obtenerRentasPorInquilino(uid);
    } else {
      _futureRentas = Future.value([]);
    }
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
          'Mis Rentas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureRentas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: MiTema.celeste),
            );
          }

          final rentas = snapshot.data ?? [];

          if (rentas.isEmpty) {
            return Center(
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
                      Icons.home_work_outlined,
                      size: 60,
                      color: MiTema.celeste,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No tienes rentas activas',
                    style: TextStyle(
                      fontSize: 20,
                      color: MiTema.azul,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Espera a que un arrendador te vincule',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: rentas.length,
            separatorBuilder: (c, i) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final renta = rentas[index];
              return _buildRentaCard(renta);
            },
          );
        },
      ),
    );
  }

  Widget _buildRentaCard(Map<String, dynamic> renta) {
    final titulo = renta['inmueble_titulo'] ?? '';
    final arrendador = renta['arrendador_nombre'] ?? '';
    final monto = renta['monto_mensual'] ?? 0;
    final diaPago = renta['dia_pago'] ?? 0;
    final estado = renta['estado'] ?? 'activa';

    final rutasRaw = (renta['rutas_imagen'] as String?) ?? '';
    final imageUrls = rutasRaw.isNotEmpty ? rutasRaw.split(',') : [];
    final primeraUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    Color estadoColor;
    Color estadoBg;
    IconData estadoIcon;

    switch (estado) {
      case 'activa':
        estadoColor = Colors.green[700]!;
        estadoBg = Colors.green[50]!;
        estadoIcon = Icons.check_circle_rounded;
        break;
      case 'finalizada':
        estadoColor = Colors.grey[600]!;
        estadoBg = Colors.grey[100]!;
        estadoIcon = Icons.archive_rounded;
        break;
      default:
        estadoColor = Colors.orange[800]!;
        estadoBg = Colors.orange[50]!;
        estadoIcon = Icons.warning_rounded;
    }

    return StunningCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetalleRentaScreen(rentaId: renta['id'].toString()),
          ),
        ).then((_) => setState(() => _cargarRentas()));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: primeraUrl != null
                    ? ImagenDinamica(ruta: primeraUrl, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: estadoColor.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, size: 14, color: estadoColor),
                      const SizedBox(width: 6),
                      Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MiTema.azul,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$$monto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: MiTema.vino,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: MiTema.celeste.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: MiTema.azul,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Arrendador',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    arrendador,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: MiTema.azul,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 24, color: Colors.grey[300]),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Día de Pago',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Día $diaPago',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: MiTema.azul,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: MiTema.celeste,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: StunningButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleRentaScreen(
                            rentaId: renta['id'].toString(),
                          ),
                        ),
                      ).then((_) => setState(() => _cargarRentas()));
                    },
                    text: 'VER DETALLES',
                    icon: Icons.visibility_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

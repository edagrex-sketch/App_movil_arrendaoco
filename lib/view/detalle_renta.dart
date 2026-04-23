import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/theme/arrenda_colors.dart';
import 'dart:async';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/view/solicitudes_renta_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/services/pusher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetalleRentaScreen extends StatefulWidget {
  final String rentaId;

  const DetalleRentaScreen({super.key, required this.rentaId});

  @override
  State<DetalleRentaScreen> createState() => _DetalleRentaScreenState();
}

class _DetalleRentaScreenState extends State<DetalleRentaScreen> {
  late Future<Map<String, dynamic>?> _futureRenta;
  late Future<List<Map<String, dynamic>>> _futurePagos;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    final rId = int.tryParse(widget.rentaId) ?? 0;
    _futureRenta = BaseDatos.obtenerRentaPorId(rId);
    _futurePagos = BaseDatos.obtenerPagosDeRenta(rId);
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

          final esArrendador = (usuarioId?.toString() == renta['arrendador_id']?.toString()) ||
                               (usuarioId?.toString() == renta['propietario_id']?.toString());
          final montoRaw = renta['monto_mensual'];
          final monto = double.tryParse(montoRaw?.toString() ?? '0') ?? 0.0;
          final diaPago = renta['dia_pago'] ?? 5;
          final estado = renta['estado'] ?? 'activa';
          final inmuebleTitulo = renta['inmueble_titulo'] ?? 'Inmueble';
          final primeraUrl = renta['rutas_imagen'] as String?;

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
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20, left: 20, right: 20,
                      child: Text(
                        inmuebleTitulo,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4)],
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
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildInfoCard(icon: Icons.attach_money_rounded, label: 'Mensualidad', value: '\$${monto.toStringAsFixed(0)}', color: MiTema.vino)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInfoCard(icon: Icons.calendar_today_rounded, label: 'Día de Pago', value: 'Día $diaPago', color: MiTema.celeste)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(icon: Icons.person_rounded, label: otraParteLabel, value: otraParte.toString(), color: MiTema.azul, fullWidth: true),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: estado == 'activa' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: estado == 'activa' ? Colors.green : Colors.grey),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(estado == 'activa' ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: estado == 'activa' ? Colors.green : Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                 'Estado: ${
                                   estado == 'activa' || estado == 'activo' ? 'ACTIVA' : 
                                   estado == 'pendiente_aprobacion' ? 'PENDIENTE DE APROBACIÓN' :
                                   estado == 'disponible' ? 'ESPERANDO FIRMA' :
                                   estado == 'pdf_descargado' ? 'PAGO RETENIDO' :
                                   estado == 'finalizada' || estado == 'finalizado' ? 'FINALIZADA' :
                                   estado == 'rechazada' || estado == 'rechazado' ? 'RECHAZADA' : estado.toUpperCase()
                                 }', 
                                 style: TextStyle(fontWeight: FontWeight.bold, color: estado == 'activa' || estado == 'activo' ? Colors.green : Colors.grey[700])
                               ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildControlPanel(context, renta),
                        const SizedBox(height: 32),
                        Text(
                          'Historial de Pagos',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: MiTema.azul),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _futurePagos,
                          builder: (context, pagoSnapshot) {
                            if (pagoSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(color: MiTema.celeste));
                            }
                            final pagos = pagoSnapshot.data ?? [];
                            if (pagos.isEmpty) {
                              return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay pagos registrados aún.', style: TextStyle(color: Colors.grey))));
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pagos.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 12),
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

  Widget _buildControlPanel(BuildContext context, Map<String, dynamic> renta) {
    final estado = renta['estado'] ?? 'pendiente_aprobacion';
    final esArrendador = (SesionActual.usuarioId?.toString() == renta['arrendador_id']?.toString()) ||
                         (SesionActual.usuarioId?.toString() == renta['propietario_id']?.toString());

    if (!esArrendador) return _buildTenantStatus(estado);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gestión de Solicitud', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ArrendaColors.primary)),
        const SizedBox(height: 16),
        if (estado == 'pendiente_aprobacion') _buildStep1(renta),
        if (estado == 'disponible') _buildStep2(renta),
        if (estado == 'pdf_descargado') _buildStep3(renta),
        if (estado == 'activa' || estado == 'activo') _buildActiveStatus(),
      ],
    );
  }

  Widget _buildTenantStatus(String estado) {
    String msg = "Tu solicitud está siendo revisada";
    IconData icon = Icons.timer_outlined;
    if (estado == 'pendiente_firma') { msg = "Contrato listo para firmar"; icon = Icons.edit_document; }
    if (estado == 'pendiente_activacion') { msg = "Esperando activación del dueño"; icon = Icons.hourglass_bottom; }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withOpacity(0.2))),
      child: Row(children: [Icon(icon, color: Colors.blue), const SizedBox(width: 12), Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)))]),
    );
  }

  Widget _buildStep1(Map<String, dynamic> renta) {
    return Column(
      children: [
        const Text('PASO 1: Aprobar Reservación', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ElevatedButton.icon(onPressed: _procesando ? null : () => _procesarSolicitud(context, renta['id'], 'aprobado'), icon: const Icon(Icons.check), label: const Text('APROBAR'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: _procesando ? null : () => _procesarSolicitud(context, renta['id'], 'rechazada'), icon: const Icon(Icons.close), label: const Text('RECHAZAR'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)))),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2(Map<String, dynamic> renta) {
    return Column(
      children: [
        const Text('PASO 2: Firma de Contrato', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: () => _descargarContrato(renta['id']), icon: const Icon(Icons.download), label: const Text('DESCARGAR CONTRATO PDF')),
        const SizedBox(height: 12),
        const Text('Una vez firmado, súbelo aquí:', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: () => _subirContrato(renta['id']), icon: const Icon(Icons.upload_file), label: const Text('SUBIR CONTRATO FIRMADO'), style: ElevatedButton.styleFrom(backgroundColor: ArrendaColors.accent)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _procesarSolicitud(context, renta['id'], 'pdf_descargado'),
            icon: const Icon(Icons.verified_rounded),
            label: const Text('CONFIRMAR FIRMA Y CONTINUAR'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(Map<String, dynamic> renta) {
    return Column(
      children: [
        const Text('PASO 3: Activación Final', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
        const SizedBox(height: 12),
        const Text('El pago ya fue retenido y el contrato está arriba.', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _procesarSolicitud(context, renta['id'], 'activa'), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white), child: const Text('ACTIVAR RENTA AHORA'))),
      ],
    );
  }

  Widget _buildActiveStatus() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
      child: const Row(children: [Icon(Icons.verified, color: Colors.green), SizedBox(width: 12), Text('Esta renta está ACTIVA', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
    );
  }

  Future<void> _procesarSolicitud(BuildContext context, dynamic id, String nuevoEstado) async {
    setState(() => _procesando = true);
    try {
      await BaseDatos.actualizarEstadoRenta(int.parse(id.toString()), nuevoEstado);
      if (mounted) {
        String msg = 'Estado actualizado';
        if (nuevoEstado == 'aprobado' || nuevoEstado == 'disponible') msg = '¡Aprobado! Ahora el inquilino debe firmar el contrato.';
        if (nuevoEstado == 'rechazada' || nuevoEstado == 'rechazado') msg = 'Solicitud rechazada correctamente.';
        if (nuevoEstado == 'activa' || nuevoEstado == 'activo') msg = '¡Renta activada con éxito!';
        if (nuevoEstado == 'pdf_descargado') msg = '¡Contrato firmado! El pago inicial ha sido validado.';
        
        LottieFeedback.showSuccess(context, message: msg);
        setState(() {
          _futureRenta = BaseDatos.obtenerRentaPorId(int.parse(id.toString()));
          _procesando = false;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _procesando = false);
    }
  }

  Future<void> _descargarContrato(dynamic id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    // Intentar abrir con el token en la URL si el backend lo soporta, o simplemente abrir la URL
    // Nota: Para una descarga protegida real en móvil, se prefiere descargar con Dio y guardar.
    final url = Uri.parse('${ApiService.defaultBaseUrl}/contratos/$id/descargar-pdf?token=$token');
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo contrato en el navegador...')));
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la URL')));
      }
    }
  }

  Future<void> _subirContrato(dynamic id) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (image == null) return;

    setState(() => _procesando = true);
    
    try {
      final ApiService api = ApiService();
      final formData = FormData.fromMap({
        'archivo': await MultipartFile.fromFile(image.path, filename: 'contrato_$id.jpg'),
      });
      
      final response = await api.post('/contratos/$id/subir-firmado', data: formData);
      
      if (mounted) {
        if (response.statusCode == 200) {
          LottieFeedback.showSuccess(context, message: '¡Contrato subido y activado!');
          setState(() {
            _futureRenta = BaseDatos.obtenerRentaPorId(int.parse(id.toString()));
            _procesando = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir el archivo')));
          setState(() => _procesando = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _procesando = false);
      }
    }
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value, required Color color, bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MiTema.azul), overflow: TextOverflow.ellipsis)])),
        ],
      ),
    );
  }

  Widget _buildPagoCard(Map<String, dynamic> pago, bool esArrendador) {
    final mesNum = pago['mes'] ?? 0;
    final anio = pago['anio'] ?? 0;
    final monto = double.tryParse(pago['monto']?.toString() ?? '0') ?? 0.0;
    final estado = pago['estatus'] ?? 'pendiente';
    const meses = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    final mesNombre = (mesNum >= 1 && mesNum <= 12) ? meses[mesNum] : 'Mes $mesNum';
    Color c = estado == 'pagado' ? Colors.green : (estado == 'vencido' ? Colors.red : Colors.orange);
    return StunningCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(estado == 'pagado' ? Icons.check_circle : Icons.pending, color: c, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$mesNombre $anio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: MiTema.azul)), Text('\$${monto.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: MiTema.vino, fontSize: 14))])),
          if (esArrendador && estado == 'pendiente') IconButton(icon: const Icon(Icons.check_rounded, color: Colors.green), onPressed: () async { await BaseDatos.actualizarEstadoPago(pago['id'] as int, 'pagado', DateTime.now().toIso8601String()); cargarPagos(); }),
        ],
      ),
    );
  }

  void cargarPagos() {
    setState(() {
      _futurePagos = BaseDatos.obtenerPagosDeRenta(int.parse(widget.rentaId));
    });
  }
}

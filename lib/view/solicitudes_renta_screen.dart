import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/utils/casting.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SolicitudesRentaScreen extends StatefulWidget {
  const SolicitudesRentaScreen({super.key});

  @override
  State<SolicitudesRentaScreen> createState() => _SolicitudesRentaScreenState();
}

class _SolicitudesRentaScreenState extends State<SolicitudesRentaScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _solicitudes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/contratos');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        // Filtrar solo las solicitudes pendientes donde YO soy el arrendador
        final myId = SesionActual.usuarioId ?? '0';
        
        setState(() {
          _solicitudes = List<Map<String, dynamic>>.from(data).where((c) {
            final isOwner = c['arrendador_id'].toString() == myId.toString() ||
                            c['propietario_id'].toString() == myId.toString();
            return (c['estado'] == 'pendiente_aprobacion' || c['estado'] == 'pendiente') && isOwner;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando solicitudes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _gestionarSolicitud(int contratoId, String nuevoEstado) async {
    try {
      final response = await _api.put('/contratos/$contratoId', data: {'estado': nuevoEstado});
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nuevoEstado == 'activa' ? '¡Solicitud Aceptada!' : 'Solicitud Rechazada'),
              backgroundColor: nuevoEstado == 'activa' ? Colors.green : Colors.red,
            ),
          );
          _cargarSolicitudes();
        }
      }
    } catch (e) {
      debugPrint('Error gestionando solicitud: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Solicitudes de Renta', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: MiTema.azul,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _solicitudes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _solicitudes.length,
                  itemBuilder: (context, index) {
                    final sol = _solicitudes[index];
                    return _buildSolicitudCard(sol);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tienes solicitudes pendientes',
            style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> sol) {
    final inquilino = sol['inquilino_nombre'] ?? 'Desconocido';
    final inmueble = sol['inmueble_titulo'] ?? 'Inmueble';
    final monto = Parser.toDouble(sol['monto_mensual']);
    final imagen = sol['rutas_imagen'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: StunningCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: MiTema.celeste.withOpacity(0.1),
                child: Icon(Icons.person, color: MiTema.celeste),
              ),
              title: Text(inquilino, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Interesado en: $inmueble'),
              trailing: Text('\$${monto.toStringAsFixed(0)}', 
                style: TextStyle(fontWeight: FontWeight.w900, color: MiTema.vino, fontSize: 18)),
            ),
            if (imagen != null)
               ImagenDinamica(ruta: imagen, height: 120, width: double.infinity, fit: BoxFit.cover),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _gestionarSolicitud(sol['id'], 'rechazada'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('RECHAZAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _gestionarSolicitud(sol['id'], 'activa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('ACEPTAR RENTA'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

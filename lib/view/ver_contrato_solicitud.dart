import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/view/widgets/stripe_pay_screen.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:intl/intl.dart';
import 'package:arrendaoco/view/arrendador.dart';
import 'package:arrendaoco/view/inquilino_home.dart';
import 'package:arrendaoco/model/sesion_actual.dart';

class VerContratoSolicitudScreen extends StatefulWidget {
  final Map inmueble;

  const VerContratoSolicitudScreen({super.key, required this.inmueble});

  @override
  State<VerContratoSolicitudScreen> createState() => _VerContratoSolicitudScreenState();
}

class _VerContratoSolicitudScreenState extends State<VerContratoSolicitudScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map? _contratoData;

  @override
  void initState() {
    super.initState();
    _cargarPreContrato();
  }

  Future<void> _cargarPreContrato() async {
    try {
      final id = widget.inmueble['id'].toString();
      final response = await _api.get('/inmuebles/$id/ver-contrato');
      if (response.statusCode == 200) {
        setState(() {
          _contratoData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar contrato: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _iniciarPagoStripe() async {
    LottieLoading.showLoadingDialog(context, message: 'Iniciando pasarela segura...');
    try {
      final response = await _api.post('/inmuebles/${widget.inmueble['id']}/rentar');
      if (mounted) LottieLoading.hideLoadingDialog(context);

      if (response.statusCode == 200 && response.data['stripe_url'] != null) {
        final urlString = response.data['stripe_url'];

        if (kIsWeb) {
          // Si es WEB, usamos url_launcher (obligatorio por seguridad del navegador)
          final url = Uri.parse(urlString);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            if (mounted) Navigator.pop(context);
          }
        } else {
          // Si es MÓVIL, usamos el WebView nativo premium
          final success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => StripePayScreen(
                url: urlString,
                title: 'Reserva de Propiedad',
              ),
            ),
          );

          if (success == true && mounted) {
            final esPropietario = SesionActual.esPropietario;
            
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => esPropietario 
                  ? ArrendadorScreen(usuarioId: SesionActual.usuarioId.toString())
                  : InquilinoHomeScreen(
                      usuarioId: SesionActual.usuarioId.toString(),
                      initialIndex: 0, // Ir a Propiedades (Mis Rentas)
                    ),
              ),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        LottieLoading.hideLoadingDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al conectar con Stripe: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final inmuebleData = _contratoData!['inmueble'];
    final inquilinoData = _contratoData!['inquilino'];
    final fechaInicio = _contratoData!['fecha_inicio'];
    final fechaFin = _contratoData!['fecha_fin'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contrato de Arrendamiento', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: MiTema.azul,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(inmuebleData),
            const SizedBox(height: 30),
            _buildCuerpoContrato(inmuebleData, inquilinoData, fechaInicio, fechaFin),
            const SizedBox(height: 40),
            _buildFooter(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Al continuar, autorizas la validación de fondos de \$${inmuebleData['renta_mensual']} MXN.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            StunningButton(
              onPressed: _iniciarPagoStripe,
              text: 'CONFIRMAR Y PAGAR',
              icon: Icons.security_rounded,
              backgroundColor: MiTema.vino,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map data) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ImagenDinamica(ruta: widget.inmueble['imagen_portada'] ?? '', width: 80, height: 80, fit: BoxFit.cover),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['titulo'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MiTema.azul)),
              Text('Renta Mensual: \$${data['renta_mensual']} MXN', style: TextStyle(color: MiTema.celeste, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildCuerpoContrato(Map inmueble, Map inquilino, String inicio, String fin) {
    final fechaActual = _contratoData!['fecha_actual'] ?? inicio;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'CONTRATO DE ARRENDAMIENTO TEMPORAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: MiTema.azul,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _contractText(
            'El presente contrato de arrendamiento temporal (en adelante, el "Contrato") es celebrado en Ocosingo en fecha $fechaActual.',
          ),
          const SizedBox(height: 15),
          _sectionTitle('ENTRE'),
          _contractText(
            '${inmueble['propietario_nombre']}, actuando en su propio nombre y derecho. De aquí en adelante el “Arrendador”.',
          ),
          _contractText('- Y -'),
          _contractText(
            '${inquilino['nombre']}, actuando en su propio nombre y derecho. De aquí en adelante el “Inquilino”.',
          ),
          const SizedBox(height: 10),
          _contractText(
            'Estos serán considerados individualmente como la “Parte” y conjuntamente como las “Partes”. En virtud de lo anterior, las Partes deciden suscribir este Contrato, el cual se regirá de conformidad con lo indicado en las siguientes Cláusulas:',
          ),
          const Divider(height: 40),
          _sectionTitle('CLÁUSULAS'),
          
          _clause(
            '1. OBJETO DEL CONTRATO Y FINALIDAD DE USO',
            'Mediante este Contrato, el Arrendador acepta alquilar al Inquilino la propiedad localizada en ${inmueble['direccion']}.\n'
            'La propiedad arrendada comprende ${inmueble['area']} metros cuadrados, con ${inmueble['habitaciones']} habitación(es) y ${inmueble['banos']} baño(s) completo(s).\n'
            'La propiedad se destinará única y exclusivamente con fines habitacionales, sin que el Inquilino pueda utilizarla para una finalidad diferente sin permiso expreso por escrito por parte del Arrendador.',
          ),

          _clause(
            '2. CONDICIONES DEL INMUEBLE Y ENTREGABLES',
            'Cerradura e ingreso: ${inmueble['compartida']}\n'
            'Estacionamiento: ${inmueble['estacionamiento']}\n'
            'Mobiliario: El estado del mobiliario es declarado como "${inmueble['mobiliario']}".',
          ),

          _clause(
            '3. DURACIÓN Y RENTA',
            'Este Contrato tendrá una duración de ${inmueble['duracion']} a contar de manera oficial a partir del $inicio.\n'
            'Por la ocupación del inmueble, el Inquilino se compromete a pagar mensualmente al Arrendador la cantidad de \$${inmueble['renta_mensual']} MXN (la "Renta").\n'
            'Este pago deberá realizarse oportunamente según se acuerde en las políticas de ArrendaOco, dentro del plazo establecido para cada ciclo mensual.\n'
            'Se estipula la entrega inicial de \$${inmueble['deposito']} MXN por concepto de Depósito en Garantía para asegurar el cumplimiento del presente contrato.',
          ),

          _clause(
            '4. RÉGIMEN DE SERVICIOS',
            'En cuanto a los servicios básicos ligados a la propiedad, las Partes acuerdan que los servicios de: ${inmueble['servicios_inquilino']} correrán por cuenta del Inquilino.',
          ),

          _clause(
            '5. NORMAS DE CONVIVENCIA Y USO',
            'Mascotas: ${inmueble['mascotas_permitidas']} Tipos admitidos preferentemente: ${inmueble['mascotas_detalles']}.\n'
            'Queda terminantemente prohibido almacenar materiales peligrosos, inflamables o desarrollar actividades ilícitas que atenten contra la seguridad y la moral del entorno.',
          ),

          _clause(
            '6. CLÁUSULAS ADICIONALES DEL PROPIETARIO',
            '${inmueble['clausulas_adicionales']}',
          ),

          _clause(
            '7. INTERMEDIACIÓN TECNOLÓGICA (EXENCIÓN DE RESPONSABILIDAD)',
            'Ambas Partes reconocen que la plataforma ArrendaOco actúa única y exclusivamente como un intermediario tecnológico, sin adquirir la figura de representante legal o responsable solidario de ninguna de las partes.\n'
            'ArrendaOco queda exonerado de cualquier responsabilidad derivada del estado físico del inmueble, impagos o discrepancias de convivencia. Cualquier conflicto legal deberá ser resuelto directamente entre el Arrendador y el Inquilino conforme a la jurisdicción de la ubicación de la propiedad.',
          ),

          const SizedBox(height: 20),
          _contractText(
            'Leído y aceptado electrónicamente por ambas Partes, este documento constata y ratifica su completa voluntad mutua de apegarse a los términos estipulados.',
          ),

          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _signatureBlock('Arrendador', inmueble['propietario_nombre']),
              _signatureBlock('Inquilino', inquilino['nombre']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signatureBlock(String label, String name) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          const SizedBox(height: 8),
          Text(
            'Firma del $label',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: MiTema.azul,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _contractText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[800],
          height: 1.6,
          fontFamily: 'serif',
        ),
      ),
    );
  }

  Widget _clause(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.5,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.verified_user_rounded, color: MiTema.celeste, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Documento generado digitalmente por ArrendaOco\nValidado con tecnología Stripe',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

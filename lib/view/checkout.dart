import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart';
import 'package:arrendaoco/widgets/lottie_feedback.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/utils/casting.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arrendaoco/view/inquilino_home.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  final Map inmueble;

  const CheckoutScreen({super.key, required this.inmueble});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _api = ApiService();
  String _selectedMethod = 'card';
  bool _isLoading = false;

  late double _renta;
  late double _deposito;
  late double _total;

  @override
  void initState() {
    super.initState();
    _renta = Parser.toDouble(widget.inmueble['renta_mensual']);
    _deposito = Parser.toDouble(widget.inmueble['deposito']);
    _total = _renta + _deposito;
  }

  Future<void> _confirmarReserva() async {
    setState(() => _isLoading = true);
    LottieLoading.showLoadingDialog(context, message: 'Preparando pago seguro...');

    try {
      final response = await _api.post(
        '/inmuebles/${widget.inmueble['id']}/rentar',
        data: {
          'inquilino_id': SesionActual.usuarioId,
          'fecha_inicio': DateTime.now().toIso8601String(),
          'renta_mensual': _renta,
          'deposito': _deposito,
          'metodo_pago': _selectedMethod,
        },
      );

      if (mounted) {
        LottieLoading.hideLoadingDialog(context);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = response.data;
          final String? stripeUrl = data['stripe_url'];

          if (stripeUrl != null && stripeUrl.isNotEmpty) {
            // Abrir pasarela de Stripe
            final uri = Uri.parse(stripeUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              
              // Mostrar feedback de que debe completar el pago
              if (mounted) {
                _mostrarModalVerificacionPago(data['contrato_id']);
              }
            } else {
              throw 'No se pudo abrir la pasarela de pago';
            }
          } else {
            // Si por alguna razón no hay URL, procedemos como éxito (aunque no debería pasar)
            await LottieFeedback.showSuccess(
              context,
              message: '¡Solicitud enviada! El propietario revisará tu renta.',
            );
            _finalizarCheckout();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data['message'] ?? 'Error al procesar la renta',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        LottieLoading.hideLoadingDialog(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarModalVerificacionPago(dynamic contratoId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('💡 Paso final'),
        content: const Text(
          'Completa el pago en la ventana que se abrió. Una vez terminado, tu solicitud será enviada automáticamente al propietario.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _finalizarCheckout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: MiTema.azul,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _finalizarCheckout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => InquilinoHomeScreen(
          usuarioId: SesionActual.usuarioId.toString(),
          initialIndex: 1, // Ir directamente a Rentas
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Finalizar Renta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: MiTema.azul,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildResumenInmueble(),
            const SizedBox(height: 20),
            _buildMetodosPago(),
            const SizedBox(height: 20),
            _buildDesgloseCostos(),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StunningButton(
                onPressed: _isLoading ? null : _confirmarReserva,
                text: 'PAGAR Y RESERVAR',
                icon: Icons.check_circle_rounded,
                backgroundColor: MiTema.rojo,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenInmueble() {
    final imgUrl = widget.inmueble['imagen_portada'] ?? widget.inmueble['imagen'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ImagenDinamica(
              ruta: imgUrl ?? '',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.inmueble['titulo'] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MiTema.azul,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.inmueble['tipo'] ?? '',
                  style: TextStyle(
                    color: MiTema.celeste,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arrendador: ${widget.inmueble['propietario']?['nombre'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildMetodosPago() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona Método de Pago',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003049),
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption(
            id: 'card',
            icon: Icons.credit_card_rounded,
            title: 'Tarjeta de Crédito / Débito',
            subtitle: 'Visa, Mastercard, Amex',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            id: 'oxxo',
            icon: Icons.storefront_rounded,
            title: 'Efectivo (OXXO Pay)',
            subtitle: 'Paga en cualquier sucursal',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            id: 'spei',
            icon: Icons.account_balance_rounded,
            title: 'Transferencia SPEI',
            subtitle: 'Confirmación instantánea',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedMethod == id;
    
    return StunningCard(
      padding: const EdgeInsets.all(16),
      onTap: () => setState(() => _selectedMethod = id),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isSelected ? MiTema.azul : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: MiTema.celeste)
          else
            Icon(Icons.radio_button_off_rounded, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildDesgloseCostos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StunningCard(
        child: Column(
          children: [
            _buildCostRow('1er Mes de Renta', _renta),
            if (_deposito > 0) ...[
              const SizedBox(height: 12),
              _buildCostRow('Depósito (Reembolsable)', _deposito),
            ],
            const SizedBox(height: 12),
            _buildCostRow('Comisión ArrendaOco', 0, isFree: true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL A PAGAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: MiTema.azul,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        Text(
          isFree ? 'GRATIS' : '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isFree ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}

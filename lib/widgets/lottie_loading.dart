import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget reutilizable para mostrar animaciones de carga con Lottie
class LottieLoading extends StatelessWidget {
  final String? animationPath;
  final double size;
  final String? message;
  final bool showOverlay;
  final Color? overlayColor;

  const LottieLoading({
    super.key,
    this.animationPath,
    this.size = 150,
    this.message,
    this.showOverlay = false,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Lottie.asset(
      animationPath ?? 'assets/animations/loading.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        animation,
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              decoration: TextDecoration
                  .none, // Evita subrayado amarillo si no hay Scaffold
              fontFamily: 'Inter', // Si usas esa fuente
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showOverlay) {
      return Container(
        color: overlayColor ?? Colors.black.withOpacity(0.3), // Fondo más sutil
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }

    return Center(child: content);
  }

  /// Muestra un diálogo de carga con animación Lottie
  static void showLoadingDialog(
    BuildContext context, {
    String? message,
    String? animationPath,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => WillPopScope(
        onWillPop: () async => barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: LottieLoading(
              animationPath: animationPath,
              message: message,
              size: 80,
            ),
          ),
        ),
      ),
    );
  }

  /// Cierra el diálogo de carga
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

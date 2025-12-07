import 'package:flutter/material.dart';

enum FeedbackType { success, error }

/// Widget para mostrar animaciones de feedback (éxito/error) con Lottie
class LottieFeedback extends StatefulWidget {
  final FeedbackType type;
  final String message;
  final VoidCallback? onComplete;
  final Duration duration;
  final double size;

  const LottieFeedback({
    super.key,
    required this.type,
    required this.message,
    this.onComplete,
    this.duration = const Duration(milliseconds: 2500),
    this.size = 200,
  });

  @override
  State<LottieFeedback> createState() => _LottieFeedbackState();

  /// Muestra un diálogo de feedback con animación
  static Future<void> show(
    BuildContext context, {
    required FeedbackType type,
    required String message,
    Duration duration = const Duration(milliseconds: 2500),
    VoidCallback? onComplete,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: LottieFeedback(
          type: type,
          message: message,
          duration: duration,
          onComplete: () {
            Navigator.of(context).pop();
            onComplete?.call();
          },
        ),
      ),
    );
  }

  /// Muestra feedback de éxito
  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 2500),
    VoidCallback? onComplete,
  }) {
    return show(
      context,
      type: FeedbackType.success,
      message: message,
      duration: duration,
      onComplete: onComplete,
    );
  }

  /// Muestra feedback de error
  static Future<void> showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(milliseconds: 2500),
    VoidCallback? onComplete,
  }) {
    return show(
      context,
      type: FeedbackType.error,
      message: message,
      duration: duration,
      onComplete: onComplete,
    );
  }
}

class _LottieFeedbackState extends State<LottieFeedback> {
  @override
  void initState() {
    super.initState();

    // Auto-cerrar después de la duración especificada
    Future.delayed(widget.duration, () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case FeedbackType.success:
        return Colors.white;
      case FeedbackType.error:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícono animado en lugar de Lottie
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.type == FeedbackType.success
                        ? const Color.fromARGB(
                            255,
                            102,
                            155,
                            188,
                          ).withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                  ),
                  child: Icon(
                    widget.type == FeedbackType.success
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: widget.size * 0.7,
                    color: widget.type == FeedbackType.success
                        ? const Color.fromARGB(255, 102, 155, 188)
                        : Colors.red,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

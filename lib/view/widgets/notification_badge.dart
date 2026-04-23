import 'package:flutter/material.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/view/notificaciones_screen.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';
import 'dart:async';

class NotificationBadge extends StatefulWidget {
  final int usuarioId;
  final Color? color;

  const NotificationBadge({super.key, required this.usuarioId, this.color});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _count = 0;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchCount();
    // Escuchar el stream de tiempo real
    _subscription = NotificacionesService.onNotificationReceived.listen((_) {
      _fetchCount();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchCount() async {
    try {
      final newCount = await BaseDatos.contarNoLeidas(widget.usuarioId);
      if (mounted) {
        setState(() {
          _count = newCount;
        });
      }
    } catch (e) {
      debugPrint('Error actualizando badge: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    NotificacionesScreen(usuarioId: widget.usuarioId),
              ),
            );
            // Cuando volvemos de la pantalla de notificaciones (donde se marcan como leídas)
            _fetchCount();
          },
          icon: Icon(
            Icons.notifications_outlined,
            color: widget.color ?? Colors.white,
            size: 28,
          ),
        ),
        if (_count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _count > 9 ? '9+' : _count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

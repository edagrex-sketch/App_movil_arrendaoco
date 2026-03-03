import 'package:flutter/material.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/view/notificaciones_screen.dart';

class NotificationBadge extends StatelessWidget {
  final int usuarioId;
  final Color? color;

  const NotificationBadge({super.key, required this.usuarioId, this.color});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: BaseDatos.contarNoLeidas(usuarioId),
      builder: (context, snapshot) {
        int count = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificacionesScreen(usuarioId: usuarioId),
                  ),
                );
              },
              icon: Icon(
                Icons.notifications_outlined,
                color: color ?? Colors.white,
                size: 28,
              ),
            ),
            if (count > 0)
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
                    count > 9 ? '9+' : count.toString(),
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
      },
    );
  }
}

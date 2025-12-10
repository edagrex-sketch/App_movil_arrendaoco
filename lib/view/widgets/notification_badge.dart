import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arrendaoco/view/notificaciones_screen.dart';

class NotificationBadge extends StatelessWidget {
  final int usuarioId;
  final Color? color;

  const NotificationBadge({super.key, required this.usuarioId, this.color});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('notificaciones')
          .stream(primaryKey: ['id'])
          .eq('usuario_id', usuarioId)
          .order('id'),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          // Filtrar no leídas localmente si el stream devuelve todo
          // O confiar en que el stream se actualiza.
          // Nota: .eq('leida', 0) podría no funcionar con .stream() si modificamos 'leida' y queremos que desaparezca de la lista
          // Mejor traer todas (limitado) y contar.
          final notifs = snapshot.data!;
          count = notifs.where((n) => (n['leida'] as int? ?? 0) == 0).length;
        }

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

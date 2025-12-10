import 'package:flutter/material.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';

class NotificacionesScreen extends StatefulWidget {
  final int usuarioId;

  const NotificacionesScreen({super.key, required this.usuarioId});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  bool _cargando = true;
  List<Map<String, dynamic>> _notificaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => _cargando = true);
    try {
      final data = await BaseDatos.obtenerNotificaciones(widget.usuarioId);
      if (mounted) {
        setState(() {
          _notificaciones = data;
          _cargando = false;
        });
        _marcarTodasComoLeidas();
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
      print('Error cargando notificaciones: $e');
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    await BaseDatos.marcarTodasComoLeidas(widget.usuarioId);
  }

  Future<void> _eliminarNotificacion(int id) async {
    try {
      await BaseDatos.eliminarNotificacion(id);
      setState(() {
        _notificaciones.removeWhere((n) => n['id'] == id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar notificación')),
      );
    }
  }

  Future<void> _manejarTapNotificacion(Map<String, dynamic> notif) async {
    final tipo = notif['tipo'];
    final refId = notif['referencia_id'];

    print('🔵 Tap en notificación: Tipo=$tipo, RefId=$refId');

    if (tipo == 'resena') {
      if (refId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay detalles disponibles para esta notificación antigua',
            ),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final refIdInt = (refId is int)
            ? refId
            : int.tryParse(refId.toString());
        if (refIdInt == null) throw Exception('ID inválido');

        // ESTRATEGIA DUAL:
        // 1. Intentar tratarlo como ID de RESEÑA (Lógica nueva "minuciosa")
        final resenaData = await BaseDatos.obtenerResenaPorId(refIdInt);

        if (resenaData != null) {
          // ¡Éxito! Es una reseña nueva. Obtenemos el inmueble padre.
          final inmuebleId = resenaData['inmueble_id'] as int;
          final inmueble = await BaseDatos.obtenerInmueblePorId(inmuebleId);

          if (context.mounted) Navigator.pop(context); // Cerrar loader

          if (inmueble != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleInmuebleScreen(
                  inmueble: inmueble,
                  scrollToReviews: true,
                  highlightResenaId: refIdInt, // ¡La magia visual!
                ),
              ),
            );
          } else {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('La propiedad ya no existe')),
              );
          }
          return;
        }

        // 2. FALLBACK: Si no encontramos reseña, asumir que es una notificación vieja que apuntaba directo al inmueble
        print(
          '⚠️ No se encontró reseña con ID $refIdInt. Intentando buscar como Inmueble directo (Fallback)',
        );
        final inmuebleDirecto = await BaseDatos.obtenerInmueblePorId(refIdInt);

        if (context.mounted) Navigator.pop(context); // Cerrar loader

        if (inmuebleDirecto != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleInmuebleScreen(
                inmueble: inmuebleDirecto,
                scrollToReviews: true,
                // Sin highlight específico porque es notificación vieja
              ),
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El contenido ya no está disponible'),
              ),
            );
          }
        }
      } catch (e) {
        print('🔴 Error abriendo notificación: $e');
        if (context.mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cargar la información')),
          );
        }
      }
    } else {
      // Feedback para otros tipos de notificaciones sin acción definida aún
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta notificación es solo informativa.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: MiTema.celeste))
          : _notificaciones.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notificaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = _notificaciones[index];
                final titulo = notif['titulo'] ?? 'Notificación';
                final mensaje = notif['mensaje'] ?? '';
                final fechaStr = notif['fecha'] as String?;
                final tipo = notif['tipo'];
                final fecha = fechaStr != null
                    ? DateTime.parse(fechaStr)
                    : DateTime.now();

                IconData iconData = Icons.notifications_rounded;
                Color iconColor = MiTema.azul;

                if (tipo == 'resena') {
                  iconData = Icons.comment_rounded;
                  iconColor = MiTema.celeste;
                } else if (tipo == 'pago') {
                  iconData = Icons.payment_rounded;
                  iconColor = Colors.green;
                } else if (tipo == 'renta') {
                  iconData = Icons.home_work_rounded;
                  iconColor = MiTema.vino;
                }

                return Dismissible(
                  key: Key(notif['id'].toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _eliminarNotificacion(notif['id']),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete_outline, color: Colors.red[700]),
                  ),
                  child: StunningCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => _manejarTapNotificacion(notif),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: iconColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        titulo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(fecha),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mensaje,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}

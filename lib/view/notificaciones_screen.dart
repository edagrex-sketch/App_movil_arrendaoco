import 'package:flutter/material.dart';
import 'package:arrendaoco/model/bd.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/view/detalle_inmueble.dart';
import 'package:arrendaoco/services/notificaciones_service.dart';
import 'dart:async';
import 'dart:convert'; // Para posibles payloads
import 'package:arrendaoco/view/chats/chat_screen.dart';
import 'package:arrendaoco/view/mis_rentas.dart';
import 'package:arrendaoco/view/gestionar_rentas.dart';
import 'package:arrendaoco/model/sesion_actual.dart';

class NotificacionesScreen extends StatefulWidget {
  final int usuarioId;

  const NotificacionesScreen({super.key, required this.usuarioId});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen>
    with SingleTickerProviderStateMixin {
  bool _cargando = true;
  List<Map<String, dynamic>> _notificaciones = [];
  late AnimationController _controller;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cargarNotificaciones();

    // Tiempo real: Escuchar si llega una nueva notificación mientras estamos aquí
    _subscription = NotificacionesService.onNotificationReceived.listen((_) {
      _cargarNotificaciones();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => _cargando = true);
    try {
      final data = await BaseDatos.obtenerNotificaciones(widget.usuarioId);
      if (mounted) {
        setState(() {
          _notificaciones = data.where((n) => n['leida'] == false || n['leida'] == 0).toList();
          _cargando = false;
          _controller.forward(from: 0);
        });
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
      NotificacionesService.refrescarBadge();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar notificación')),
      );
    }
  }

  Future<void> _manejarTapNotificacion(Map<String, dynamic> notif) async {
    final tipo = notif['tipo'];
    final refId = notif['referencia_id'];
    final id = notif['id'];

    print('🔵 Tap en notificación: Tipo=$tipo, RefId=$refId');

    // MARCAR COMO LEÍDA Y QUITAR DE LA LISTA
    if (id != null) {
      BaseDatos.marcarComoLeida(id);
      setState(() {
        _notificaciones.removeWhere((n) => n['id'] == id);
      });
      // Notificar al badge
      NotificacionesService.refrescarBadge();
    }

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
    } else if (tipo == 'mensaje') {
      final chatIdInt = int.tryParse(refId?.toString() ?? '');
      if (chatIdInt != null) {
        // En un escenario ideal, traeríamos los datos del chat. Por ahora, navegamos.
        // Si no tenemos los datos del 'otroUsuario', el ChatScreen intentará cargarlos o fallará graciosamente.
        // Mockup del otro usuario (se cargará por API en el initState del chat si falta algo)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatIdInt,
              otroUsuario: const {'nombre': 'Usuario'}, // Fallback
            ),
          ),
        );
      }
    } else if (tipo == 'pago' || tipo == 'renta') {
      if (SesionActual.esPropietario) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GestionarRentasScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MisRentasScreen()),
        );
      }
    } else if (tipo == 'inmueble') {
      final inmuebleId = int.tryParse(refId?.toString() ?? '');
      if (inmuebleId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleInmuebleScreen(
              inmueble: {'id': inmuebleId},
            ),
          ),
        );
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryGradient,
          ),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: MiTema.celeste))
          : _notificaciones.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/empty.json',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.notifications_off_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Estás al día',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: MiTema.azul,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No tienes nuevas notificaciones',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
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

                // Animated List Item
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      (1 / _notificaciones.length) * index,
                      1.0,
                      curve: Curves.easeOutQuart,
                    ),
                  ),
                );

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: Dismissible(
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
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red[700],
                        ),
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
                                  child: Icon(
                                    iconData,
                                    color: iconColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              titulo,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            _formatDate(fecha),
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 11,
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
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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

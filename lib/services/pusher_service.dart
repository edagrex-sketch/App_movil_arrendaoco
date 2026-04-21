// ESTE ARCHIVO HA SIDO MIGRADO A FIREBASE PARA MEJORAR LA ESTABILIDAD
// Se mantiene la clase para evitar errores de referencia en otras pantallas.
import 'package:arrendaoco/services/firebase_chat_service.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final _firebase = FirebaseChatService();

  // Mantenemos los métodos pero redirigimos a Firebase
  Future<void> init({
    required Function(dynamic) onMessageReceived,
    required String chatId,
  }) async {
    // El chat ahora se inicializa directamente desde ChatScreen con Firebase
  }

  Future<void> listenToInmuebles({
    required Function(int inmuebleId, String estatus) onStatusChanged,
  }) async {
    await _firebase.listenToInmuebles(onStatusChanged: onStatusChanged);
  }

  Future<void> listenToPersonalUpdates({
    required int usuarioId,
    required Function(int contratoId, String nuevoEstatus) onRentalUpdated,
  }) async {
    await _firebase.listenToPersonalUpdates(
      usuarioId: usuarioId, 
      onRentalUpdated: onRentalUpdated
    );
  }

  Future<void> disconnect({String? channel}) async {
    // Firebase no necesita desconexión manual de canales por ID
  }
}

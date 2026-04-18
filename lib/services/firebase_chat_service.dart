import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colección principal: chats
  // Documento: ID del chat
  // Subcolección: mensajes

  /// Obtiene los mensajes de un chat en tiempo real
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Envía un mensaje a Firestore
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    String? inmuebleId,
  }) async {
    try {
      final now = DateTime.now();
      
      // 1. Crear/Actualizar el documento del chat (Metadata)
      await _firestore.collection('chats').doc(chatId).set({
        'last_message': text,
        'last_message_at': Timestamp.fromDate(now),
        'usuario_1': senderId,
        'usuario_2': receiverId,
        'inmueble_id': inmuebleId,
        'updated_at': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      // 2. Agregar el mensaje a la subcolección
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensajes')
          .add({
        'sender_id': senderId,
        'text': text,
        'created_at': Timestamp.fromDate(now),
        'leido': false,
      });

      debugPrint('✅ Mensaje enviado a Firebase');
    } catch (e) {
      debugPrint('❌ Error enviando mensaje a Firebase: $e');
      rethrow;
    }
  }

  /// Crea un ID único para el chat basado en los dos usuarios
  String getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // Ordenar para que siempre sea el mismo ID sin importar quién inicie
    return ids.join('_');
  }
}

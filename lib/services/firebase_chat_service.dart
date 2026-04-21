import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseChatService {
  static final FirebaseChatService _instance = FirebaseChatService._internal();
  factory FirebaseChatService() => _instance;
  FirebaseChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene los mensajes de un chat en tiempo real desde Firestore
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId.toString())
        .collection('mensajes')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'created_at': (data['created_at'] as Timestamp?)?.toDate().toString() ?? DateTime.now().toString(),
        };
      }).toList();
    });
  }

  /// Sincroniza un mensaje de Laravel hacia Firebase para tiempo real
  Future<void> syncLaravelMessage(String chatId, Map<String, dynamic> msg) async {
    try {
      final String msgId = msg['id'].toString();
      await _firestore
          .collection('chats')
          .doc(chatId.toString())
          .collection('mensajes')
          .doc(msgId)
          .set({
        'id': msgId,
        'chat_id': chatId,
        'sender_id': msg['sender_id'],
        'contenido': msg['contenido'],
        'tipo': msg['tipo'] ?? 'texto',
        'created_at': FieldValue.serverTimestamp(),
        'sender': msg['sender'],
        'parent': msg['parent'],
      });

      await _firestore.collection('chats').doc(chatId.toString()).set({
        'last_message': msg['contenido'],
        'last_sender_id': msg['sender_id'],
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Firebase Sync Error: $e');
    }
  }

  /// ESCUCHAR ESTATUS DE INMUEBLES (Implementación vía Firebase)
  Future<void> listenToInmuebles({
    required Function(int inmuebleId, String estatus) onStatusChanged,
  }) async {
    // Usamos una colección 'global_updates' para cambios de estatus
    _firestore.collection('updates').doc('inmuebles').snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        onStatusChanged(data['inmuebleId'] ?? 0, data['nuevoEstatus'] ?? '');
      }
    });
  }

  /// ESCUCHAR RENTAS PERSONALES (Implementación vía Firebase)
  Future<void> listenToPersonalUpdates({
    required int usuarioId,
    required Function(int contratoId, String nuevoEstatus) onRentalUpdated,
  }) async {
    _firestore.collection('users').doc(usuarioId.toString()).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('last_rental_update')) {
          final rentalData = data['last_rental_update'];
          onRentalUpdated(rentalData['contratoId'] ?? 0, rentalData['nuevoEstatus'] ?? '');
        }
      }
    });
  }

  // Compatibilidad con chat_detalle.dart
  Stream<QuerySnapshot> getRawMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId.toString())
        .collection('mensajes')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Compatibilidad con chat_detalle.dart
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    String? inmuebleId,
  }) async {
    final now = DateTime.now();
    await _firestore.collection('chats').doc(chatId).set({
      'last_message': text,
      'last_message_at': Timestamp.fromDate(now),
      'usuario_1': senderId,
      'usuario_2': receiverId,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('chats').doc(chatId).collection('mensajes').add({
      'sender_id': senderId,
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
      'leido': false,
    });
  }

  String getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }
}

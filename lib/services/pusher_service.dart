import 'dart:convert';
import 'package:arrendaoco/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  
  static const String _appKey = 'ekufgj3wwtrgkohxpiy8';

  Future<void> init({
    required Function(dynamic) onMessageReceived,
    required String chatId,
  }) async {
    final api = ApiService();
    final baseUrl = api.currentBaseUrl;
    final uri = Uri.parse(baseUrl);
    final host = uri.host;
    const port = 8080;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      await _pusher.init(
        apiKey: _appKey,
        cluster: "us2", // Valor por defecto necesario para la lib
        useTLS: false,
        // Nota: Para Reverb custom host, la lib usa proxy o configuraciones internas
        // En versiones recientes, si no detecta host, se puede pasar via cluster "" 
        // pero lo más seguro es dejar los callbacks primero:
        onConnectionStateChange: (currentState, previousState) {
          debugPrint("Pusher Connection State: $currentState");
        },
        onError: (message, code, dynamic e) {
          debugPrint("Pusher Connection Error: $message (code: $code)");
        },
        onEvent: (PusherEvent event) {
          if (event.channelName == "private-chat.$chatId" && 
              event.eventName == "App\\Events\\MessageSent") {
            debugPrint("Pusher Event: MessageSent");
            if (event.data != null) {
              final data = jsonDecode(event.data.toString());
              onMessageReceived(data['mensaje']);
            }
          }
        },
        onAuthorizer: (channelName, socketId, options) async {
          // Lógica de autorización para canales privados
          final authUrl = "${baseUrl.replaceAll('/api', '')}/broadcasting/auth";
          final response = await api.client.post(
            authUrl,
            data: {
              'socket_id': socketId,
              'channel_name': channelName,
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            ),
          );
          return response.data;
        },
      );

      await _pusher.subscribe(channelName: "private-chat.$chatId");
      await _pusher.connect();
      debugPrint("Conectando a Reverb en $host:$port...");
    } catch (e) {
      debugPrint("Error inicializando Pusher: $e");
    }
  }

  Future<void> disconnect(String chatId) async {
    try {
      await _pusher.unsubscribe(channelName: "private-chat.$chatId");
      await _pusher.disconnect();
      debugPrint("Desconectado de Pusher.");
    } catch (e) {
      debugPrint("Error al desconectar: $e");
    }
  }
}

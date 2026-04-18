import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiService {
  static const String _baseUrlKey = 'custom_api_url';
  
  /// IP real de tu PC en la red WiFi local.
  static const String _lanIp = '192.168.1.116';
  
  /// Puerto que está usando el servidor de PHP/Laravel
  static const String _port = '8003';

  /// Variable para forzar modo emulador si la detección falla.
  static const bool _forceEmulator = false;

  static String get defaultBaseUrl {
    // 10.0.2.2 es la IP especial en Android para acceder al localhost del PC.
    // Usamos _lanIp para dispositivos físicos.
    
    // Por ahora, para no complicar con Future en un getter estático, 
    // dejamos la lógica preparada para que el usuario pueda cambiarla 
    // o detectarla en el constructor.
    final host = _forceEmulator ? '10.0.2.2' : _lanIp; 
    return 'http://$host:$_port/api';
  }

  late final Dio _dio;
  late Future<void> _initializationFuture;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: defaultBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    
    _initializationFuture = _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_baseUrlKey);
    
    if (customUrl != null && customUrl.isNotEmpty) {
      _dio.options.baseUrl = customUrl;
    } else {
      // Detección automática de emulador
      try {
        final deviceInfo = DeviceInfoPlugin();
        bool isEmulator = false;
        
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          // Detección robusta de emuladores Android
          isEmulator = !androidInfo.isPhysicalDevice ||
              androidInfo.model.contains('google_sdk') ||
              androidInfo.model.contains('Emulator') ||
              androidInfo.model.contains('Android SDK built for x86') ||
              androidInfo.hardware.contains('goldfish') ||
              androidInfo.hardware.contains('ranchu') ||
              androidInfo.brand.startsWith('generic') ||
              androidInfo.device.startsWith('generic') ||
              androidInfo.fingerprint.startsWith('generic');
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          isEmulator = !iosInfo.isPhysicalDevice || 
              iosInfo.model.toLowerCase().contains('simulator');
        }

        if (isEmulator) {
          _dio.options.baseUrl = 'http://10.0.2.2:$_port/api';
          debugPrint('ApiService: Emulador detectado. Usando 10.0.2.2');
        } else {
          _dio.options.baseUrl = 'http://$_lanIp:$_port/api';
          debugPrint('ApiService: Dispositivo físico detectado. Usando $_lanIp');
        }
      } catch (e) {
        debugPrint('ApiService: Error detectando emulador, usando LAN por defecto: $e');
      }
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final p = await SharedPreferences.getInstance();
          final token = p.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Log de la petición
          debugPrint('🌐 API Request: [${options.method}] ${options.baseUrl}${options.path}');
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          debugPrint('❌ API Error: [${e.requestOptions.method}] ${e.requestOptions.baseUrl}${e.requestOptions.path}');
          debugPrint('   Mensaje: ${e.message}');
          debugPrint('   Tipo: ${e.type}');
          if (e.response != null) {
            debugPrint('   Status: ${e.response?.statusCode}');
            debugPrint('   Data: ${e.response?.data}');
          }
          
          if (e.response?.statusCode == 401) {
            // Manejar logout si es necesario
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> _ensureInitialized() async {
    await _initializationFuture;
  }

  Future<void> setCustomBaseUrl(String url) async {
    _dio.options.baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url.trim());
  }

  String get currentBaseUrl => _dio.options.baseUrl;

  Dio get client => _dio;

  // Métodos de ayuda genéricos
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureInitialized();
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    await _ensureInitialized();
    return await _dio.post(path, data: data, options: options);
  }

  Future<Response> put(String path, {dynamic data, Options? options}) async {
    await _ensureInitialized();
    return await _dio.put(path, data: data, options: options);
  }

  Future<Response> delete(String path) async {
    await _ensureInitialized();
    return await _dio.delete(path);
  }
}

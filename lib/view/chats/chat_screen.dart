import 'package:flutter/material.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/services/firebase_chat_service.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final Map<String, dynamic> otroUsuario;
  final Map<String, dynamic>? inmueble;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otroUsuario,
    this.inmueble,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final FirebaseChatService _fbChat = FirebaseChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Map<String, dynamic>? _replyMessage; // Mensaje al que estamos respondiendo
  Map<String, dynamic>? _fullInmueble;
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _fullInmueble = widget.inmueble;
    _fetchMessages();
    _fetchPropertyDetails();
    _setupFirebase();
  }

  Future<void> _fetchPropertyDetails() async {
    if (widget.inmueble == null) return;
    
    // Si ya tenemos precio y foto, no hace falta buscar (optimización)
    if (_fullInmueble != null && 
        (_fullInmueble!['renta_mensual'] != null || _fullInmueble!['precio'] != null) &&
        (_fullInmueble!['imagen_portada'] != null || _fullInmueble!['imagenes_nombres'] != null)) {
      return;
    }

    try {
      final id = widget.inmueble!['id'];
      final response = await ApiService().get('/inmuebles/$id');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _fullInmueble = response.data['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error trayendo detalles extra del inmueble: $e');
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupFirebase() {
    _chatSubscription = _fbChat.getMessagesStream(widget.chatId.toString()).listen((fbMessages) {
      if (mounted) {
        setState(() {
          for (var fbMsg in fbMessages) {
            final index = _messages.indexWhere((m) => m['id'].toString() == fbMsg['id'].toString());
            if (index == -1) {
              _messages.add(fbMsg);
            } else {
              _messages[index] = fbMsg;
            }
          }
          _messages.sort((a,b) {
             final da = DateTime.tryParse(a['created_at'].toString()) ?? DateTime.now();
             final db = DateTime.tryParse(b['created_at'].toString()) ?? DateTime.now();
             return da.compareTo(db);
          });
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await _api.get('/chats/${widget.chatId}/mensajes');
      if (response.statusCode == 200) {
        setState(() {
          _messages = response.data['data'];
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _onReplyMessage(Map<String, dynamic> message) {
    setState(() {
      _replyMessage = message;
    });
    // Podríamos enfocar el teclado aquí si quisiéramos
  }

  void _cancelReply() {
    setState(() {
      _replyMessage = null;
    });
  }

  Future<void> _sendMessage({String? content, String? type, Map<String, dynamic>? metadata}) async {
    final text = content ?? _messageController.text.trim();
    if (text.isEmpty && type == null) return;

    final parentId = _replyMessage?['id'];
    final parentData = _replyMessage != null ? {
      'contenido': _replyMessage!['contenido'],
      'sender_nombre': _replyMessage!['sender_nombre'] ?? (int.tryParse(_replyMessage!['sender_id'].toString()) == int.tryParse(SesionActual.usuarioId ?? '0') ? 'Tú' : (widget.otroUsuario['nombre'] ?? 'Usuario')),
    } : null;

    final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";
    final localMsg = {
      'id': tempId,
      'contenido': text,
      'tipo': type ?? 'texto',
      'sender_id': int.tryParse(SesionActual.usuarioId ?? '0'),
      'created_at': DateTime.now().toString(),
      'is_temp': true,
      'parent': parentData, // Añadimos info del padre para el optimista
    };

    setState(() {
      _messages.add(localMsg);
      _isSending = true;
      _replyMessage = null; // Limpiar respuesta al enviar
    });
    if (content == null) _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _api.post(
        '/chats/${widget.chatId}/enviar',
        data: {
          'contenido': text,
          'tipo': type ?? 'texto',
          'parent_id': parentId,
          'metadata': metadata,
        },
      );

      if (response.statusCode != null && response.statusCode! < 300) {
        final newMessage = response.data['data'];
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
          if (!_messages.any((m) => m['id'].toString() == newMessage['id'].toString())) {
            _messages.add(newMessage);
          }
        });
        _fbChat.syncLaravelMessage(widget.chatId.toString(), newMessage);
      }
    } catch (e) {
      _fbChat.syncLaravelMessage(widget.chatId.toString(), localMsg);
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ImagenDinamica(
                  ruta: widget.otroUsuario['foto_perfil'] ?? 
                        widget.otroUsuario['avatar'] ?? 
                        widget.otroUsuario['perfil_foto'] ?? 
                        widget.otroUsuario['foto'] ?? '',
                  nombre: widget.otroUsuario['nombre'] ?? 'U',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otroUsuario['nombre'] ?? 'Usuario',
                  style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('En línea', style: TextStyle(color: Colors.green[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPropertyHeader(),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: MiTema.celeste))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final esMio = msg['sender_id'].toString() == SesionActual.usuarioId;
                    return InkWell(
                      onLongPress: () => _onReplyMessage(msg),
                      child: _buildModernMessage(msg, esMio),
                    );
                  },
                ),
          ),
          if (_replyMessage != null) _buildReplyPreview(),
          _buildPremiumInputArea(),
        ],
      ),
    );
  }

  Widget _buildPropertyHeader() {
    final inmueble = _fullInmueble;
    if (inmueble == null) return const SizedBox.shrink();

    // Detección AGRESIVA de imagen (Sincronizado con Explorar.dart)
    String? imagenUrl;
    final List<String> keysParaImagen = [
      'imagen_portada', 'imagenes_nombres', 'imagenes', 
      'imagen', 'foto', 'foto_principal'
    ];
    for (var key in keysParaImagen) {
      final val = inmueble[key];
      if (val is List && val.isNotEmpty) {
        imagenUrl = val[0].toString();
        break;
      } else if (val is String && val.isNotEmpty) {
        imagenUrl = val;
        break;
      }
    }

    // Búsqueda AGRESIVA de precio (Sincronizado con Explorar.dart)
    double precioFinal = 0.0;
    final List<String> keysParaPrecio = [
      'renta_mensual', 'precio', 'renta', 'monto', 'valor', 
      'monto_renta', 'precio_mensual', 'monto_mensual', 
      'precio_vivienda', 'pago_mensual', 'costo'
    ];
    for (var key in keysParaPrecio) {
      final val = inmueble[key];
      if (val != null) {
        final parsed = double.tryParse(val.toString());
        if (parsed != null && parsed > 0) {
          precioFinal = parsed;
          break;
        }
      }
    }

    final String precioFormateado = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    ).format(precioFinal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: ImagenDinamica(
              ruta: imagenUrl ?? '',
              borderRadius: BorderRadius.circular(12),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inmueble['titulo']?.toString() ?? 'Sin título',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 4),
                Text(
                  precioFinal > 0 ? '$precioFormateado / mes' : 'Cargando precio...',
                  style: TextStyle(
                    color: MiTema.celeste, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Quitamos el REF y ponemos un icono de estado o simplemente dejamos el espacio
          Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final bool esMio = _replyMessage!['sender_id'].toString() == SesionActual.usuarioId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: MiTema.celeste, width: 4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    esMio ? 'Tú' : (widget.otroUsuario['nombre'] ?? 'Usuario'),
                    style: TextStyle(color: MiTema.celeste, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _replyMessage!['contenido'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: _cancelReply,
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, curve: Curves.easeOutCubic).fadeIn();
  }

  Widget _buildModernMessage(Map<String, dynamic> msg, bool esMio) {
    final String time = _formatTime(msg['created_at']);
    final parent = msg['parent'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!esMio) ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImagenDinamica(
                      ruta: widget.otroUsuario['foto_perfil'] ?? 
                            widget.otroUsuario['avatar'] ?? 
                            widget.otroUsuario['perfil_foto'] ?? 
                            widget.otroUsuario['foto'] ?? '',
                      nombre: widget.otroUsuario['nombre'] ?? 'U',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(4), // Para espacio del parent
                  decoration: BoxDecoration(
                    gradient: esMio ? LinearGradient(colors: [MiTema.celeste, MiTema.azul], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                    color: esMio ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(esMio ? 20 : 0),
                      bottomRight: Radius.circular(esMio ? 0 : 20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parent != null) _buildMessageParent(parent, esMio),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          msg['contenido'] ?? '',
                          style: TextStyle(color: esMio ? Colors.white : Colors.black87, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideX(begin: esMio ? 0.1 : -0.1),
          Padding(
            padding: EdgeInsets.only(top: 4, left: esMio ? 0 : 36, right: esMio ? 8 : 0),
            child: Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageParent(dynamic parent, bool esMio) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: esMio ? Colors.white.withOpacity(0.15) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: esMio ? Colors.white : MiTema.celeste, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parent['sender_nombre'] ?? 'Usuario',
            style: TextStyle(
              color: esMio ? Colors.white : MiTema.celeste,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            parent['contenido'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: esMio ? Colors.white70 : Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic dateStr) {
    try {
      final date = DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
      return DateFormat('hh:mm a').format(date);
    } catch (e) { return ''; }
  }

  Widget _buildPremiumInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.add_circle_outline_rounded, color: MiTema.celeste), onPressed: () {}),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: 'Escribe un mensaje...', border: InputBorder.none),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [MiTema.celeste, MiTema.azul], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

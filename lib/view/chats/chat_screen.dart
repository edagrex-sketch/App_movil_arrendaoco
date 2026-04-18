import 'package:flutter/material.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/services/pusher_service.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/widgets/lottie_loading.dart'; // No se usa pero tal vez se use luego
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:arrendaoco/view/roco_chat.dart';
import 'package:intl/intl.dart';

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
  final PusherService _pusher = PusherService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Map<String, dynamic>? _replyMessage;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _setupPusher();
  }

  @override
  void dispose() {
    _pusher.disconnect(widget.chatId.toString());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _setupPusher() async {
    await _pusher.init(
      chatId: widget.chatId.toString(),
      onMessageReceived: (msg) {
        if (mounted) {
          setState(() {
            // Evitar duplicados si nosotros mismos enviamos el mensaje
            if (!_messages.any((m) => m['id'] == msg['id'])) {
              _messages.add(msg);
              _scrollToBottom();
            }
          });
        }
      },
    );
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
      debugPrint('Error fetching messages: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? content, String? type, Map<String, dynamic>? metadata}) async {
    final text = content ?? _messageController.text.trim();
    if (text.isEmpty && type == null) return;

    setState(() => _isSending = true);
    if (content == null) _messageController.clear();
    
    final parentId = _replyMessage?['id'];
    setState(() => _replyMessage = null);

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

      if (response.statusCode == 200) {
        final newMessage = response.data['data'];
        setState(() {
          if (!_messages.any((m) => m['id'] == newMessage['id'])) {
            _messages.add(newMessage);
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Acciones rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (!SesionActual.esPropietario)
              _buildActionItem(
                icon: Icons.assignment_turned_in_rounded,
                title: 'Solicitar Renta',
                subtitle: 'Envía una solicitud formal para este inmueble',
                color: MiTema.azul,
                onTap: () {
                  Navigator.pop(context);
                  _sendMessage(
                    content: '¡Hola! Me encantaría rentar esta propiedad. ¿Podemos iniciar el proceso?',
                    type: 'oferta',
                  );
                },
              ),
              _buildActionItem(
                icon: Icons.description_rounded,
                title: 'Proponer Acuerdo',
                subtitle: 'Envía una propuesta de contrato al inquilino',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _sendMessage(
                    content: 'He revisado tu perfil y me gustaría proponerte un acuerdo formal de renta.',
                    type: 'contrato_enviado',
                  );
                },
              ),
            const Divider(),
            _buildActionItem(
              icon: Icons.pets_rounded,
              title: 'Consultar con Roco',
              subtitle: 'Pide consejos de leyes o dudas de la propiedad',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _abrirRocoMediador();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  void _abrirRocoMediador() {
    final lastMessage = _messages.isNotEmpty ? _messages.last['contenido'] : '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RocoChatScreen(
          inmuebleId: widget.inmueble?['id'],
          initialMessage: lastMessage.isNotEmpty 
            ? 'Roco, en mi chat dijeron esto: "$lastMessage". ¿Qué opinas o qué me sugieres responder legalmente?'
            : 'Roco, ayúdame como mediador en este chat de renta.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (widget.inmueble != null) _buildInmuebleBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessagesList(),
          ),
          if (_replyMessage != null) _buildReplyPreview(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: MiTema.azul,
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            child: ClipOval(
              child: ImagenDinamica(
                ruta: widget.otroUsuario['foto_perfil'] ?? '',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otroUsuario['nombre'] ?? 'Usuario',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'En línea',
                  style: TextStyle(fontSize: 11, color: Colors.green[600], fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
      ],
    );
  }

  Widget _buildInmuebleBanner() {
    return InkWell(
      onTap: () {
        if (widget.inmueble != null) {
          Navigator.pushNamed(context, '/detalle-inmueble', arguments: widget.inmueble);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: MiTema.azul.withOpacity(0.05),
        child: Row(
          children: [
            Hero(
              tag: 'prop_img_${widget.inmueble?['id']}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ImagenDinamica(
                  ruta: widget.inmueble?['imagen'] ?? '',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interés por:',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.inmueble?['titulo'] ?? '',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MiTema.azul),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['sender_id'].toString() == SesionActual.usuarioId.toString();
        
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    final type = msg['tipo'];
    final time = DateTime.parse(msg['created_at']);
    final parent = msg['parent'];

    return GestureDetector(
      onDoubleTap: () {
        setState(() => _replyMessage = msg);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (parent != null)
              _buildParentRef(parent, isMe),
            
            if (type == 'oferta' || type == 'contrato_enviado')
              _buildActionCard(msg, isMe)
            else
              _buildTextBubble(msg['contenido'], isMe),
            
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(time),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg['leido'] == true ? Icons.done_all_rounded : Icons.check_rounded,
                      size: 14,
                      color: msg['leido'] == true ? MiTema.celeste : Colors.grey,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentRef(dynamic parent, bool isMe) {
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 40 : 0, 
        right: isMe ? 0 : 40,
        bottom: -10
      ),
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 18),
      decoration: BoxDecoration(
        color: Colors.grey[300]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parent['sender_nombre'] ?? 'Usuario',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            parent['contenido'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBubble(String content, bool isMe) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? MiTema.azul : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        content,
        style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14.5),
      ),
    );
  }

  Widget _buildActionCard(dynamic msg, bool isMe) {
    final isOferta = msg['tipo'] == 'oferta';
    final color = isOferta ? Colors.blue[800]! : Colors.green[700]!;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? MiTema.azul : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isOferta ? Icons.star_rounded : Icons.file_copy_rounded, color: isMe ? Colors.white : color, size: 18),
              const SizedBox(width: 8),
              Text(
                isOferta ? 'SOLICITUD DE RENTA' : 'PROPUESTA DE CONTRATO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isMe ? Colors.white : color, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            msg['contenido'],
            style: TextStyle(
              fontSize: 13, 
              fontStyle: FontStyle.italic,
              color: isMe ? Colors.white.withOpacity(0.9) : Colors.black87
            ),
          ),
          const SizedBox(height: 16),
          if (!isMe)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                elevation: 0,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isOferta ? 'VER PERFIL' : 'REVISAR CONTRATO', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: MiTema.azul, width: 4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Respondiendo a ${_replyMessage!['sender']?['nombre'] ?? 'Usuario'}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: MiTema.azul),
                  ),
                  Text(_replyMessage!['contenido'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18), 
              onPressed: () => setState(() => _replyMessage = null)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 10, 
        bottom: 10 + MediaQuery.of(context).viewInsets.bottom
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: _showActionMenu,
              icon: Icon(Icons.add_circle_outline_rounded, color: MiTema.azul),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(color: MiTema.azul, shape: BoxShape.circle),
              child: IconButton(
                onPressed: _isSending ? null : () => _sendMessage(),
                icon: _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

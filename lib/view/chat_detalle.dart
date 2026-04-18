import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/services/firebase_chat_service.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ChatDetalleScreen extends StatefulWidget {
  final String otroUsuarioId;
  final String otroUsuarioNombre;
  final String? fotoPerfil;
  final String? inmuebleId;

  const ChatDetalleScreen({
    super.key,
    required this.otroUsuarioId,
    required this.otroUsuarioNombre,
    this.fotoPerfil,
    this.inmuebleId,
  });

  @override
  State<ChatDetalleScreen> createState() => _ChatDetalleScreenState();
}

class _ChatDetalleScreenState extends State<ChatDetalleScreen> {
  final TextEditingController _msgController = TextEditingController();
  final FirebaseChatService _chatService = FirebaseChatService();
  final ScrollController _scrollController = ScrollController();
  late String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = _chatService.getChatId(
      SesionActual.usuarioId ?? '',
      widget.otroUsuarioId,
    );
  }

  void _enviarMensaje() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    _chatService.sendMessage(
      chatId: _chatId,
      senderId: SesionActual.usuarioId ?? '',
      receiverId: widget.otroUsuarioId,
      text: text,
      inmuebleId: widget.inmuebleId,
    );
    
    // Scroll al final
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryGradient)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: widget.fotoPerfil != null ? NetworkImage(widget.fotoPerfil!) : null,
              child: widget.fotoPerfil == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otroUsuarioNombre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'En línea ahora',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Área de mensajes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true, // Lo más nuevo abajo
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool esMio = data['sender_id'] == SesionActual.usuarioId;
                    final String texto = data['text'] ?? '';
                    final Timestamp? time = data['created_at'];

                    return _buildMessageBubble(texto, esMio, time)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: esMio ? 0.2 : -0.2, curve: Curves.easeOutCubic);
                  },
                );
              },
            ),
          ),

          // Input de texto
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool esMio, Timestamp? time) {
    final String hora = time != null ? DateFormat('HH:mm').format(time.toDate()) : '';

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: esMio ? MiTema.azul : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(esMio ? 20 : 4),
            bottomRight: Radius.circular(esMio ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: esMio ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hora,
              style: TextStyle(
                color: esMio ? Colors.white70 : Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _msgController,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                onSubmitted: (_) => _enviarMensaje(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MiTema.celeste.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _enviarMensaje,
            ),
          ),
        ],
      ),
    );
  }
}

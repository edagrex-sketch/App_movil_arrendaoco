import 'package:flutter/material.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/view/chats/chat_screen.dart';
import 'package:arrendaoco/view/widgets/imagen_dinamica.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _chats = [];

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final response = await _api.get('/chats');
      if (response.statusCode == 200) {
        setState(() {
          _chats = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? _buildShimmer()
          : _chats.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchChats,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _chats.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return _buildChatTile(chat);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatTile(dynamic chat) {
    final otroUsuario = chat['otro_usuario'];
    final unreadCount = chat['unread_count'] ?? 0;
    final lastMessage = chat['last_message'] ?? 'Inicia una conversación';
    final lastTime = chat['last_message_at'] != null 
        ? DateTime.parse(chat['last_message_at']) 
        : null;

    return ListTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat['id'],
              otroUsuario: otroUsuario,
              inmueble: chat['inmueble'],
            ),
          ),
        );
        _fetchChats(); // Refrescar al volver
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: ImagenDinamica(
                  ruta: otroUsuario['foto_perfil'] ?? '',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (chat['activo'] == true)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              otroUsuario['nombre'] ?? 'Usuario',
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.bold,
                fontSize: 16,
                color: MiTema.azul,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastTime != null)
            Text(
              _formatTime(lastTime),
              style: TextStyle(
                color: unreadCount > 0 ? MiTema.celeste : Colors.grey,
                fontSize: 12,
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage,
                style: TextStyle(
                  color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: MiTema.celeste,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays < 7) {
      return DateFormat('E').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'Aún no tienes conversaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            '¡Envía un mensaje para empezar!',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          leading: const CircleAvatar(radius: 28),
          title: Container(height: 12, width: 100, color: Colors.white),
          subtitle: Container(height: 10, width: 200, color: Colors.white),
        ),
      ),
    );
  }
}

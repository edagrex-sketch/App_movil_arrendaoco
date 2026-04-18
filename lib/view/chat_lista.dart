import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/view/chat_detalle.dart';
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ChatListaScreen extends StatelessWidget {
  const ChatListaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String myId = SesionActual.usuarioId ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Mensajes',
          style: TextStyle(
            color: MiTema.azul,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: MiTema.azul),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where(Filter.or(
              Filter('usuario_1', isEqualTo: myId),
              Filter('usuario_2', isEqualTo: myId),
            ))
            .orderBy('last_message_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey[100],
              indent: 85,
              endIndent: 20,
            ),
            itemBuilder: (context, index) {
              final data = chats[index].data() as Map<String, dynamic>;
              final String chatId = chats[index].id;
              
              // Determinar quién es el otro usuario
              final String otroId = data['usuario_1'] == myId 
                  ? data['usuario_2'] 
                  : data['usuario_1'];
              
              // Aquí deberíamos tener un sistema para obtener el nombre del otro usuario
              // Por ahora usaremos un nombre genérico o lo buscaremos en la data si existe
              final String nombre = data['otro_nombre'] ?? 'Usuario ArrendaOco';
              final String ultimoMsg = data['last_message'] ?? '';
              final Timestamp? time = data['last_message_at'];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: MiTema.celeste.withOpacity(0.1),
                      child: Icon(Icons.person, color: MiTema.celeste, size: 30),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
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
                    Text(
                      nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      time != null ? _formatTime(time.toDate()) : '',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    ultimoMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetalleScreen(
                        otroUsuarioId: otroId,
                        otroUsuarioNombre: nombre,
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes mensajes',
            style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Busca una propiedad e inicia un chat',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('dd/MM').format(date);
  }
}

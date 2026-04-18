import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/theme/arrenda_colors.dart';
import 'package:arrendaoco/view/explorar.dart';
import 'package:arrendaoco/view/favoritos.dart';
import 'package:arrendaoco/view/perfil.dart';
import 'package:arrendaoco/view/mis_rentas.dart';
import 'package:arrendaoco/services/fcm_service.dart';
import 'package:arrendaoco/view/widgets/notification_badge.dart';
import 'package:arrendaoco/view/roco_chat.dart';
import 'package:arrendaoco/view/chats/chat_list_screen.dart';

class InquilinoHomeScreen extends StatefulWidget {
  final String usuarioId;

  const InquilinoHomeScreen({super.key, required this.usuarioId});

  @override
  State<InquilinoHomeScreen> createState() => _InquilinoHomeScreenState();
}

class _InquilinoHomeScreenState extends State<InquilinoHomeScreen> {
  int _currentIndex = 0;

  final List<String> _titulos = [
    'Explorar',
    'Mensajes',
    'Mis Rentas',
    'Mis Favoritos',
    'Mi Perfil',
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ExplorarScreen(),
      const ChatListScreen(), 
      const MisRentasScreen(),
      const FavoritosScreen(),
      const PerfilScreen(),
    ];
    final uid = int.tryParse(widget.usuarioId) ?? 0;
    if (uid > 0) {
      FCMService.initialize(uid);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: ArrendaColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 12.0),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            color: Colors.white,
          ),
        ),
        leadingWidth: 56,
        title: Text(
          _titulos[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryGradient,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          NotificationBadge(usuarioId: int.tryParse(widget.usuarioId) ?? 0),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: ArrendaColors.accent.withOpacity(0.15),
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            setState(() {
              _currentIndex = i;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.search_outlined, color: Colors.grey[600]),
              selectedIcon: Icon(
                Icons.search_rounded,
                color: ArrendaColors.primary,
              ),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey[600]),
              selectedIcon: Icon(
                Icons.chat_bubble_rounded,
                color: ArrendaColors.primary,
              ),
              label: 'Mensajes',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: Colors.grey[600]),
              selectedIcon: Icon(
                Icons.receipt_long_rounded,
                color: ArrendaColors.primary,
              ),
              label: 'Mis Rentas',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.favorite_border_rounded,
                color: Colors.grey[600],
              ),
              selectedIcon: Icon(
                Icons.favorite_rounded,
                color: ArrendaColors.primary,
              ),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Colors.grey[600]),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: ArrendaColors.primary,
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RocoChatScreen()),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.pets_rounded, color: Colors.white),
      ),
      body: SafeArea(child: _pages[_currentIndex]),
    );
  }
}

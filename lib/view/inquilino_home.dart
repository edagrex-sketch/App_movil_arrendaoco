import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/view/explorar.dart';
import 'package:arrendaoco/view/favoritos.dart';
import 'package:arrendaoco/view/perfil.dart';

import 'package:arrendaoco/services/notificaciones_service.dart';
import 'package:arrendaoco/view/widgets/notification_badge.dart';

class InquilinoHomeScreen extends StatefulWidget {
  final String usuarioId;

  const InquilinoHomeScreen({super.key, required this.usuarioId});

  @override
  State<InquilinoHomeScreen> createState() => _InquilinoHomeScreenState();
}

class _InquilinoHomeScreenState extends State<InquilinoHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Iniciar escucha de notificaciones en tiempo real
    final uid = int.tryParse(widget.usuarioId) ?? 0;
    if (uid > 0) {
      NotificacionesService.escucharNotificaciones(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ExplorarScreen(),
      const FavoritosScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'ArrendaOco',
          style: TextStyle(fontWeight: FontWeight.bold),
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
          indicatorColor: MiTema.celeste.withOpacity(0.15),
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
              selectedIcon: Icon(Icons.search_rounded, color: MiTema.azul),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.favorite_border_rounded,
                color: Colors.grey[600],
              ),
              selectedIcon: Icon(Icons.favorite_rounded, color: MiTema.azul),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Colors.grey[600]),
              selectedIcon: Icon(Icons.person_rounded, color: MiTema.azul),
              label: 'Perfil',
            ),
          ],
        ),
      ),
      body: SafeArea(child: pages[_currentIndex]),
    );
  }
}

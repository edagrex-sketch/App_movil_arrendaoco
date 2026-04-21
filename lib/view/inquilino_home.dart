import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:arrendaoco/theme/arrenda_colors.dart';
import 'package:arrendaoco/view/explorar.dart';
import 'package:arrendaoco/view/favoritos.dart';
import 'package:arrendaoco/view/perfil.dart';
import 'package:arrendaoco/view/mis_rentas.dart';
import 'package:arrendaoco/services/fcm_service.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/view/widgets/notification_badge.dart';
import 'package:arrendaoco/view/roco_chat.dart';
import 'package:arrendaoco/widgets/premium_navbar.dart';
import 'package:arrendaoco/view/chats/chat_list_screen.dart';
import 'package:arrendaoco/widgets/animated_rocco_fab.dart';

class InquilinoHomeScreen extends StatefulWidget {
  final String usuarioId;
  final int initialIndex;

  const InquilinoHomeScreen({
    super.key, 
    required this.usuarioId,
    this.initialIndex = 0,
  });

  @override
  State<InquilinoHomeScreen> createState() => _InquilinoHomeScreenState();
}

class _InquilinoHomeScreenState extends State<InquilinoHomeScreen> {
  late int _currentIndex;

  final List<String> _titulos = [
    'Inicio',
    'Mis Rentas',
    'Mi Perfil',
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const ExplorarScreen(),
      const MisRentasScreen(),
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
      extendBody: false,
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
      bottomNavigationBar: PremiumFloatingNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        items: const [
          StunningNavItem(
            icon: Icons.home_outlined, 
            selectedIcon: Icons.home_rounded, 
            label: 'Explorar',
          ),
          StunningNavItem(
            icon: Icons.receipt_long_outlined, 
            selectedIcon: Icons.receipt_long_rounded, 
            label: 'Mis Rentas',
          ),
          StunningNavItem(
            icon: Icons.person_outline_rounded, 
            selectedIcon: Icons.person_rounded, 
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 25),
        child: AnimatedRoccoFab(),
      ),
      body: SafeArea(
        top: false, // El contenido debe llegar hasta arriba bajo el AppBar
        bottom: false, // Y hasta abajo bajo el Navbar
        child: _pages[_currentIndex],
      ),
    );
  }
}

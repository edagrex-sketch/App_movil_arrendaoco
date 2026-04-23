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
import 'package:arrendaoco/model/sesion_actual.dart';
import 'package:arrendaoco/view/arrendador.dart'; // Import to use InicioFeed

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



  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    final uid = int.tryParse(widget.usuarioId) ?? 0;
    if (uid > 0) {
      FCMService.initialize(uid);
    }
  }

  @override
  Widget build(BuildContext context) {

    final bool esProp = SesionActual.esPropietario;
    
    final List<String> titulos = esProp 
      ? ['Propiedades', 'Explorar', 'Perfil']
      : ['Explorar', 'Perfil'];

    final List<Widget> pages = esProp
      ? [
          InicioFeed(usuarioId: widget.usuarioId),
          const ExplorarScreen(),
          const PerfilScreen(),
        ]
      : [
          const ExplorarScreen(),
          const PerfilScreen(),
        ];

    final List<StunningNavItem> navItems = esProp
      ? const [
          StunningNavItem(
            icon: Icons.home_work_outlined, 
            selectedIcon: Icons.home_work_rounded, 
            label: 'Propiedades',
          ),
          StunningNavItem(
            icon: Icons.search_outlined, 
            selectedIcon: Icons.search_rounded, 
            label: 'Explorar',
          ),
          StunningNavItem(
            icon: Icons.person_outline_rounded, 
            selectedIcon: Icons.person_rounded, 
            label: 'Perfil',
          ),
        ]
      : const [
          StunningNavItem(
            icon: Icons.search_outlined, 
            selectedIcon: Icons.search_rounded, 
            label: 'Explorar',
          ),
          StunningNavItem(
            icon: Icons.person_outline_rounded, 
            selectedIcon: Icons.person_rounded, 
            label: 'Perfil',
          ),
        ];

    // Ajustar índice si cambia el número de pestañas
    if (_currentIndex >= titulos.length) {
      _currentIndex = titulos.length - 1;
    }

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          backgroundColor: Colors.white,
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
              titulos[_currentIndex],
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
            items: navItems,
          ),
          body: SafeArea(
            top: false, 
            bottom: false,
            child: pages[_currentIndex],
          ),
        ),
        const AnimatedRoccoFab(),
      ],
    );
  }
}

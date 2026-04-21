import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<StunningNavItem> items;

  const PremiumFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => onDestinationSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 20 : 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? MiTema.azul.withOpacity(0.1) 
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? items[index].selectedIcon : items[index].icon,
                          color: isSelected 
                            ? MiTema.azul 
                            : Colors.grey[500],
                          size: 26,
                        ).animate(target: isSelected ? 1 : 0)
                         .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15))
                         .shimmer(delay: 400.ms, duration: 1000.ms),
                        if (isSelected)
                          const SizedBox(height: 4),
                        if (isSelected)
                          Text(
                            items[index].label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: MiTema.azul,
                            ),
                          ).animate().fadeIn().scale(),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 800.ms);
  }
}

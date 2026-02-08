import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/arrenda_colors.dart';

class ArrendaGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const ArrendaGlass({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: ArrendaColors.glassBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: ArrendaColors.glassBorder, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

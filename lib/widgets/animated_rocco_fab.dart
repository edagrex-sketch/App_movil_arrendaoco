import 'package:flutter/material.dart';
import 'package:arrendaoco/view/roco_chat.dart';
import 'dart:async';

class AnimatedRoccoFab extends StatefulWidget {
  const AnimatedRoccoFab({super.key});

  @override
  State<AnimatedRoccoFab> createState() => _AnimatedRoccoFabState();
}

class _AnimatedRoccoFabState extends State<AnimatedRoccoFab> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    // Iniciar expandido y contraer después de unos segundos para llamar la atención
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RocoChatScreen()),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.fastOutSlowIn,
        height: 56,
        width: _isExpanded ? 190 : 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.pets_rounded, color: Colors.white, size: 26),
            if (_isExpanded) ...[
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Preguntar a ROCCO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

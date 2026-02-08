import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';

class ImagenDinamica extends StatelessWidget {
  final String ruta;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ImagenDinamica({
    super.key,
    required this.ruta,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (ruta.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      );
    }

    if (ruta.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: ruta,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => StunningShimmer(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: 0,
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    } else {
      // Asumimos ruta local
      final file = File(ruta);
      if (!file.existsSync()) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.image_search, color: Colors.grey),
        );
      }
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          );
        },
      );
    }
  }
}

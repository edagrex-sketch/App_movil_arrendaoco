import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';
import 'package:arrendaoco/services/api_service.dart';
import 'package:arrendaoco/theme/tema.dart';

class ImagenDinamica extends StatelessWidget {
  final String ruta;
  final String? nombre; // Nuevo: Nombre para generar iniciales
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImagenDinamica({
    super.key,
    required this.ruta,
    this.nombre,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (ruta.isEmpty || ruta == 'null') return _buildPlaceholder();

    String rutaLimpiaRaw = ruta.trim();
    String urlFinal = rutaLimpiaRaw;
    bool isNetwork = rutaLimpiaRaw.toLowerCase().startsWith('http');
    
    // Lógica de servidor mejorada
    if (!isNetwork && !rutaLimpiaRaw.startsWith('/data/') && !rutaLimpiaRaw.startsWith('C:') && !rutaLimpiaRaw.startsWith('/storage/emulated/')) {
        final baseUrlFiltered = ApiService().currentBaseUrl.replaceAll('/api', '');
        String rutaParaServer = rutaLimpiaRaw;
        // Si no tiene storage ni es una URL completa, le ponemos storage/
        if (!rutaParaServer.contains('storage') && !rutaParaServer.contains('://')) {
          rutaParaServer = "storage/$rutaParaServer";
        }
        if (!rutaParaServer.startsWith('/')) {
          rutaParaServer = "/$rutaParaServer";
        }
        urlFinal = "$baseUrlFiltered$rutaParaServer";
        isNetwork = true;
    }

    if (isNetwork) {
      urlFinal = urlFinal.replaceAll('//storage', '/storage').replaceAll('///', '/');
      if (urlFinal.contains('https:/') && !urlFinal.contains('https://')) {
        urlFinal = urlFinal.replaceFirst('https:/', 'https://');
      }

      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: urlFinal,
          fit: fit,
          width: width,
          height: height,
          placeholder: (context, url) => StunningShimmer(
            width: width ?? double.infinity,
            height: height ?? double.infinity,
            borderRadius: borderRadius != null ? 10 : 0,
          ),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    } else {
      final file = File(ruta);
      if (!file.existsSync()) return _buildPlaceholder();
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.file(file, fit: fit, width: width, height: height, errorBuilder: (c, e, s) => _buildPlaceholder()),
      );
    }
  }

  Widget _buildPlaceholder() {
    // Si tenemos un nombre, generamos un avatar con la inicial
    if (nombre != null && nombre!.isNotEmpty) {
      final String inicial = nombre![0].toUpperCase();
      // Elegir un color basado en el nombre para que siempre sea el mismo para el mismo usuario
      final List<Color> colores = [
        const Color(0xFF6B4EE6), // Morado Manuel
        const Color(0xFF00B4D8), // Celeste ArrendaOco
        const Color(0xFFFF9F1C), // Naranja Roco
        const Color(0xFFE91E63), // Rosa
        const Color(0xFF4CAF50), // Verde
      ];
      final Color colorFondo = colores[nombre!.length % colores.length];

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Text(
            inicial,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: (width != null) ? width! * 0.45 : 20,
            ),
          ),
        ),
      );
    }

    // Fallback: Si no hay nombre, mostramos un icono genérico elegante
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded, 
          color: Colors.grey[400], 
          size: (width != null && width! < 30) ? 14 : 26
        ),
      ),
    );
  }
}

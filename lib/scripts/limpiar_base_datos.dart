import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🛑 INICIANDO LIMPIEZA TOTAL DE LA BASE DE DATOS...');
  print('⚠️  ESTA ACCIÓN ES DESTRUCTIVA E IRREVERSIBLE');

  await Supabase.initialize(
    url: 'https://ewkythohvhdmksswsdxj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3a3l0aG9odmhkbWtzc3dzZHhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwNDQyODUsImV4cCI6MjA4MDYyMDI4NX0.gSegtK1EsXoEL88KHCLsK83EarYnVpYt5Y6oKbMm8wU',
  );

  final supabase = Supabase.instance.client;

  // Lista ordenada para evitar errores de Foreign Keys
  final tablas = [
    'pagos_renta',
    'mensajes_resena',
    'calendario',
    'notificaciones',
    'resenas',
    'favoritos',
    'rentas',
    'inmuebles',
    'usuarios',
  ];

  for (var tabla in tablas) {
    try {
      print('🗑️ Eliminando datos de tabla: $tabla...');

      // Esto elimina TODOS los registros donde id sea mayor a 0 (asumiendo IDs numéricos positivos)
      // O usando un filtro que siempre sea cierto como id.neq.0
      await supabase.from(tabla).delete().neq('id', 0);

      print('✅ Tabla $tabla limpiada correctamente.');
    } catch (e) {
      print('❌ Error limpiando $tabla: $e');
      print(
        '   (Puede que la tabla esté vacía o tenga restricciones especiales)',
      );
    }
  }

  print('\n✨ LIMPIEZA COMPLETADA ✨');
}

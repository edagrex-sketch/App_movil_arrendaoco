// ignore_for_file: avoid_print
import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://ewkythohvhdmksswsdxj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3a3l0aG9odmhkbWtzc3dzZHhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwNDQyODUsImV4cCI6MjA4MDYyMDI4NX0.gSegtK1EsXoEL88KHCLsK83EarYnVpYt5Y6oKbMm8wU',
  );

  print('Conectando a Supabase...');

  try {
    // 1. Crear Arrendador
    print('Creando Arrendador...');
    // Verificar si existe para no duplicar error
    final existeArr = await supabase
        .from('usuarios')
        .select('id')
        .eq('username', 'arrendador_test@demo.com')
        .maybeSingle();

    int arrendadorId;
    if (existeArr != null) {
      arrendadorId = existeArr['id'];
      print('Arrendador ya existía (ID: $arrendadorId)');
    } else {
      final arrRes = await supabase
          .from('usuarios')
          .insert({
            'username': 'arrendador_test@demo.com',
            'password': 'password123',
            'nombre': 'Juan Propietario',
            'rol': 'Arrendador',
            // 'foto_perfil': '...' // Opcional
          })
          .select('id')
          .single();
      arrendadorId = arrRes['id'];
      print('Arrendador creado (ID: $arrendadorId)');
    }

    // 2. Crear Inquilino
    print('Creando Inquilino...');
    try {
      final existeInq = await supabase
          .from('usuarios')
          .select('id')
          .eq('username', 'inquilino_test@demo.com')
          .maybeSingle();
      if (existeInq != null) {
        print('Inquilino ya existía');
      } else {
        await supabase
            .from('usuarios')
            .insert({
              'username': 'inquilino_test@demo.com',
              'password': 'password123',
              'nombre': 'Pedro Inquilino',
              'rol': 'Inquilino',
            })
            .select('id')
            .single();
        print('Inquilino creado');
      }
    } catch (e) {
      print('❌ Error creando inquilino: $e');
    }

    // 3. Crear 5 Inmuebles
    print('Creando 5 Inmuebles para Arrendador ID $arrendadorId...');

    // Lista de inmuebles de ejemplo
    final inmuebles = [
      {
        'propietario_id': arrendadorId,
        'titulo': 'Departamento Centro Histórico',
        'descripcion':
            'Hermoso departamento ubicado en el corazón de la ciudad. Cerca de museos y restaurantes. Ideal para parejas.',
        'precio': 5500.0,

        'tamano': 'Mediano',
        'camas': 2,
        'banos': 1,
        'rutas_imagen':
            'https://plus.unsplash.com/premium_photo-1689609950112-d66095626efb?fm=jpg&q=60&w=3000,https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
        'categoria': 'Departamento',
        'disponible': 1,
        'latitud': 19.4326,
        'longitud': -99.1332,
        'estacionamiento': 0,
        'mascotas': 0,
        'visitas': 0,
        'amueblado': 1,
        'agua': 1,
        'wifi': 1,
      },
      {
        'propietario_id': arrendadorId,
        'titulo': 'Casa con Jardín Amplio',
        'descripcion':
            'Casa familiar en zona residencial tranquila. Cuenta con garaje para 2 autos y jardín trasero.',
        'precio': 12000.0,

        'tamano': 'Grande',
        'camas': 3,
        'banos': 2,
        'rutas_imagen':
            'https://cdn.pixabay.com/photo/2014/11/21/17/17/house-540796_1280.jpg,https://images.unsplash.com/photo-1564013799919-ab600027ffc6',
        'categoria': 'Casa',
        'disponible': 1,
        'latitud': 19.4426,
        'longitud': -99.1432,
        'estacionamiento': 2,
        'mascotas': 1,
        'visitas': 1,
        'amueblado': 0,
        'agua': 1,
        'wifi': 1,
      },
      {
        'propietario_id': arrendadorId,
        'titulo': 'Loft Industrial Moderno',
        'descripcion':
            'Espacio abierto estilo loft industrial. Techos altos y mucha luz natural. Perfecto para profesionistas.',
        'precio': 8500.0,

        'tamano': 'Pequeño',
        'camas': 1,
        'banos': 1,
        'rutas_imagen':
            'https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg,https://images.unsplash.com/photo-1502672260266-1c1ef2d93688',
        'categoria': 'Departamento',
        'disponible': 1,
        'latitud': 19.4126,
        'longitud': -99.1632,
        'estacionamiento': 1,
        'mascotas': 1,
        'visitas': 1,
        'amueblado': 1,
        'agua': 1,
        'wifi': 1,
      },
      {
        'propietario_id': arrendadorId,
        'titulo': 'Cabaña en el Bosque',
        'descripcion':
            'Escapa de la ciudad a esta acogedora cabaña. Chimenea interior y terraza con vista a la montaña.',
        'precio': 4500.0,

        'tamano': 'Mediano',
        'camas': 2,
        'banos': 1,
        'rutas_imagen':
            'https://img.freepik.com/foto-gratis/villa-lujo-piscina-espectacular-diseno-contemporaneo-arte-digital-bienes-raices-hogar-casa-propiedad-ge_1258-150749.jpg',
        'categoria': 'Casa',
        'disponible': 1,
        'latitud': 19.3026,
        'longitud': -99.2032,
        'estacionamiento': 1,
        'mascotas': 1,
        'visitas': 1,
        'amueblado': 1,
        'agua': 0,
        'wifi': 0,
      },
      {
        'propietario_id': arrendadorId,
        'titulo': 'Habitación Estudiante',
        'descripcion':
            'Cuarto amueblado con escritorio y cama individual. Servicios incluidos (agua, luz, internet).',
        'precio': 3000.0,

        'tamano': 'Pequeño',
        'camas': 1,
        'banos': 1,
        'rutas_imagen':
            'https://images.adsttc.com/media/images/623c/4fa0/3e4b/314e/8a00/001b/large_jpg/_fi.jpg',
        'categoria': 'Cuarto',
        'disponible': 1,
        'latitud': 19.3326,
        'longitud': -99.1832,
        'estacionamiento': 0,
        'mascotas': 0,
        'visitas': 1,
        'amueblado': 1,
        'agua': 1,
        'wifi': 1,
      },
    ];

    await supabase.from('inmuebles').insert(inmuebles);
    print('✅ ¡Datos insertados exitosamente!');
  } catch (e) {
    print('❌ Error: $e');
  }
}

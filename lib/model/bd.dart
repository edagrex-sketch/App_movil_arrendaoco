import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class BaseDatos {
  static Database? _db;

  static Future<Database> conecta() async {
    if (_db != null) return _db!;

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'arrendaoco.db');

    _db = await openDatabase(
      path,
      version: 6, // IMPORTANTE: versión 6 para agregar notificaciones
      onCreate: (Database db, int version) async {
        // ======== Tabla usuarios ========
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            nombre TEXT,
            password TEXT,
            rol TEXT
          )
        ''');

        await db.insert('usuarios', {
          'username': 'admin',
          'nombre': 'Administrador',
          'password': '123',
          'rol': 'Arrendador',
        });

        // ======== Tabla inmuebles ========
        await db.execute('''
          CREATE TABLE inmuebles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT,
            descripcion TEXT,
            precio REAL,
            disponible INTEGER,
            categoria TEXT CHECK(
              categoria IN ('Casa', 'Departamento', 'Cuarto')
            ),
            propietario_id INTEGER,
            latitud REAL,
            longitud REAL,
            rutas_imagen TEXT,
            camas INTEGER,
            banos INTEGER,
            tamano TEXT,
            estacionamiento INTEGER,
            mascotas INTEGER,
            visitas INTEGER,
            amueblado INTEGER,
            agua INTEGER,
            wifi INTEGER,
            FOREIGN KEY (propietario_id) REFERENCES usuarios(id)
          )
        ''');

        // ======== Tabla reseñas ========
        await db.execute('''
          CREATE TABLE resenas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inmueble_id INTEGER NOT NULL,
            usuario_nombre TEXT,
            rating INTEGER NOT NULL,
            comentario TEXT,
            fecha TEXT,
            FOREIGN KEY (inmueble_id) REFERENCES inmuebles(id)
          )
        ''');

        // ======== Tabla favoritos ========
        await db.execute('''
          CREATE TABLE favoritos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL,
            inmueble_id INTEGER NOT NULL,
            fecha_agregado TEXT,
            FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
            FOREIGN KEY (inmueble_id) REFERENCES inmuebles(id),
            UNIQUE(usuario_id, inmueble_id)
          )
        ''');

        // ======== Tabla calendario ========
        await db.execute('''
          CREATE TABLE calendario (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL,
            inmueble_id INTEGER,
            renta_id INTEGER,
            titulo TEXT NOT NULL,
            descripcion TEXT,
            fecha TEXT NOT NULL,
            tipo TEXT CHECK(tipo IN ('visita', 'accion', 'recordatorio', 'pago')),
            compartido INTEGER DEFAULT 0,
            FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
            FOREIGN KEY (inmueble_id) REFERENCES inmuebles(id),
            FOREIGN KEY (renta_id) REFERENCES rentas(id)
          )
        ''');

        // ======== Tabla rentas ========
        await db.execute('''
          CREATE TABLE rentas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inmueble_id INTEGER NOT NULL,
            arrendador_id INTEGER NOT NULL,
            inquilino_id INTEGER NOT NULL,
            fecha_inicio TEXT NOT NULL,
            fecha_fin TEXT,
            monto_mensual REAL NOT NULL,
            dia_pago INTEGER NOT NULL,
            estado TEXT CHECK(estado IN ('activa', 'finalizada', 'pendiente')) DEFAULT 'activa',
            FOREIGN KEY (inmueble_id) REFERENCES inmuebles(id),
            FOREIGN KEY (arrendador_id) REFERENCES usuarios(id),
            FOREIGN KEY (inquilino_id) REFERENCES usuarios(id)
          )
        ''');

        // ======== Tabla pagos_renta ========
        await db.execute('''
          CREATE TABLE pagos_renta (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            renta_id INTEGER NOT NULL,
            mes TEXT NOT NULL,
            anio INTEGER NOT NULL,
            monto REAL NOT NULL,
            fecha_vencimiento TEXT NOT NULL,
            fecha_pago TEXT,
            estado TEXT CHECK(estado IN ('pendiente', 'pagado', 'atrasado')) DEFAULT 'pendiente',
            FOREIGN KEY (renta_id) REFERENCES rentas(id)
          )
        ''');

        // ======== Tabla notificaciones ========
        await db.execute('''
          CREATE TABLE notificaciones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL,
            titulo TEXT NOT NULL,
            mensaje TEXT NOT NULL,
            tipo TEXT CHECK(tipo IN ('renta', 'pago', 'inmueble', 'sistema')),
            leida INTEGER DEFAULT 0,
            fecha TEXT NOT NULL,
            FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS resenas (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              inmueble_id INTEGER NOT NULL,
              usuario_nombre TEXT,
              rating INTEGER NOT NULL,
              comentario TEXT,
              fecha TEXT,
              FOREIGN KEY (inmueble_id) REFERENCES inmuebles(id)
            )
          ''');
        }
        if (oldVersion < 3) {
          // Agregar columna 'rol' a la tabla usuarios
          await db.execute('''
            ALTER TABLE usuarios ADD COLUMN rol TEXT
          ''');
        }
        if (oldVersion < 4) {
          // Agregar tabla favoritos
          await db.execute('''
            CREATE TABLE IF NOT EXISTS favoritos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL,
              inmueble_id INTEGER NOT NULL,
              fecha_agregado TEXT,
              FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
              FOREIGN KEY (inmueble_id) REFERENCES inmuebles(id),
              UNIQUE(usuario_id, inmueble_id)
            )
          ''');

          // Agregar tabla calendario
          await db.execute('''
            CREATE TABLE IF NOT EXISTS calendario (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL,
              inmueble_id INTEGER,
              titulo TEXT NOT NULL,
              descripcion TEXT,
              fecha TEXT NOT NULL,
              tipo TEXT CHECK(tipo IN ('visita', 'accion', 'recordatorio')),
              FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
              FOREIGN KEY (inmueble_id) REFERENCES inmuebles(id)
            )
          ''');
        }
        if (oldVersion < 5) {
          // Agregar columnas a calendario para soporte de rentas
          await db.execute('''
            ALTER TABLE calendario ADD COLUMN renta_id INTEGER
          ''');
          await db.execute('''
            ALTER TABLE calendario ADD COLUMN compartido INTEGER DEFAULT 0
          ''');

          // Crear tabla rentas
          await db.execute('''
            CREATE TABLE IF NOT EXISTS rentas (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              inmueble_id INTEGER NOT NULL,
              arrendador_id INTEGER NOT NULL,
              inquilino_id INTEGER NOT NULL,
              fecha_inicio TEXT NOT NULL,
              fecha_fin TEXT,
              monto_mensual REAL NOT NULL,
              dia_pago INTEGER NOT NULL,
              estado TEXT CHECK(estado IN ('activa', 'finalizada', 'pendiente')) DEFAULT 'activa',
              FOREIGN KEY (inmueble_id) REFERENCES inmuebles(id),
              FOREIGN KEY (arrendador_id) REFERENCES usuarios(id),
              FOREIGN KEY (inquilino_id) REFERENCES usuarios(id)
            )
          ''');

          // Crear tabla pagos_renta
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pagos_renta (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              renta_id INTEGER NOT NULL,
              mes TEXT NOT NULL,
              anio INTEGER NOT NULL,
              monto REAL NOT NULL,
              fecha_vencimiento TEXT NOT NULL,
              fecha_pago TEXT,
              estado TEXT CHECK(estado IN ('pendiente', 'pagado', 'atrasado')) DEFAULT 'pendiente',
              FOREIGN KEY (renta_id) REFERENCES rentas(id)
            )
          ''');
        }
        if (oldVersion < 6) {
          // Crear tabla notificaciones
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notificaciones (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL,
              titulo TEXT NOT NULL,
              mensaje TEXT NOT NULL,
              tipo TEXT CHECK(tipo IN ('renta', 'pago', 'inmueble', 'sistema')),
              leida INTEGER DEFAULT 0,
              fecha TEXT NOT NULL,
              FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
            )
          ''');
        }
      },
    );

    return _db!;
  }

  // ================== INMUEBLES (opcionales) ==================

  static Future<int> insertarInmueble(Map<String, dynamic> data) async {
    final db = await conecta();
    return db.insert('inmuebles', data);
  }

  static Future<List<Map<String, dynamic>>> obtenerInmuebles() async {
    final db = await conecta();
    return db.query('inmuebles', orderBy: 'id DESC');
  }

  // ================== RESEÑAS ==================

  static Future<int> insertarResena(Map<String, dynamic> resena) async {
    final db = await conecta();
    return db.insert('resenas', resena);
  }

  static Future<List<Map<String, dynamic>>> obtenerResenasPorInmueble(
    int inmuebleId,
  ) async {
    final db = await conecta();
    return db.query(
      'resenas',
      where: 'inmueble_id = ?',
      whereArgs: [inmuebleId],
      orderBy: 'id DESC',
    );
  }

  static Future<Map<String, dynamic>> obtenerResumenResenas(
    int inmuebleId,
  ) async {
    final db = await conecta();
    final result = await db.rawQuery(
      '''
      SELECT 
        AVG(rating) AS promedio,
        COUNT(*) AS total
      FROM resenas
      WHERE inmueble_id = ?
    ''',
      [inmuebleId],
    );

    if (result.isNotEmpty) {
      final row = result.first;
      final promedioRaw = row['promedio'];
      final totalRaw = row['total'];

      final promedio = promedioRaw == null
          ? 0.0
          : (promedioRaw is int)
          ? promedioRaw.toDouble()
          : promedioRaw as double;

      final total = totalRaw == null
          ? 0
          : (totalRaw is int)
          ? totalRaw
          : (totalRaw as num).toInt();

      return {'promedio': promedio, 'total': total};
    }
    return {'promedio': 0.0, 'total': 0};
  }

  // ================== FAVORITOS ==================

  static Future<int> agregarFavorito(int usuarioId, int inmuebleId) async {
    final db = await conecta();
    return db.insert('favoritos', {
      'usuario_id': usuarioId,
      'inmueble_id': inmuebleId,
      'fecha_agregado': DateTime.now().toIso8601String(),
    });
  }

  static Future<int> eliminarFavorito(int usuarioId, int inmuebleId) async {
    final db = await conecta();
    return db.delete(
      'favoritos',
      where: 'usuario_id = ? AND inmueble_id = ?',
      whereArgs: [usuarioId, inmuebleId],
    );
  }

  static Future<bool> esFavorito(int usuarioId, int inmuebleId) async {
    final db = await conecta();
    final result = await db.query(
      'favoritos',
      where: 'usuario_id = ? AND inmueble_id = ?',
      whereArgs: [usuarioId, inmuebleId],
    );
    return result.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> obtenerFavoritos(
    int usuarioId,
  ) async {
    final db = await conecta();
    return db.rawQuery(
      '''
      SELECT i.* FROM inmuebles i
      INNER JOIN favoritos f ON i.id = f.inmueble_id
      WHERE f.usuario_id = ?
      ORDER BY f.fecha_agregado DESC
    ''',
      [usuarioId],
    );
  }

  // ================== CALENDARIO ==================

  static Future<int> agregarEvento(Map<String, dynamic> evento) async {
    final db = await conecta();
    return db.insert('calendario', evento);
  }

  static Future<List<Map<String, dynamic>>> obtenerEventosPorUsuario(
    int usuarioId,
  ) async {
    final db = await conecta();
    return db.query(
      'calendario',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'fecha ASC',
    );
  }

  static Future<int> eliminarEvento(int eventoId) async {
    final db = await conecta();
    return db.delete('calendario', where: 'id = ?', whereArgs: [eventoId]);
  }

  static Future<List<Map<String, dynamic>>> obtenerEventosPorRenta(
    int rentaId,
  ) async {
    final db = await conecta();
    return db.query(
      'calendario',
      where: 'renta_id = ? AND compartido = 1',
      whereArgs: [rentaId],
      orderBy: 'fecha ASC',
    );
  }

  // ================== RENTAS ==================

  static Future<int> crearRenta(Map<String, dynamic> renta) async {
    final db = await conecta();
    return db.insert('rentas', renta);
  }

  static Future<List<Map<String, dynamic>>> obtenerRentasPorArrendador(
    int arrendadorId,
  ) async {
    final db = await conecta();
    return db.rawQuery(
      '''
      SELECT r.*, i.titulo as inmueble_titulo, i.rutas_imagen, u.nombre as inquilino_nombre
      FROM rentas r
      INNER JOIN inmuebles i ON r.inmueble_id = i.id
      INNER JOIN usuarios u ON r.inquilino_id = u.id
      WHERE r.arrendador_id = ?
      ORDER BY r.fecha_inicio DESC
    ''',
      [arrendadorId],
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerRentasPorInquilino(
    int inquilinoId,
  ) async {
    final db = await conecta();
    return db.rawQuery(
      '''
      SELECT r.*, i.titulo as inmueble_titulo, i.rutas_imagen, u.nombre as arrendador_nombre
      FROM rentas r
      INNER JOIN inmuebles i ON r.inmueble_id = i.id
      INNER JOIN usuarios u ON r.arrendador_id = u.id
      WHERE r.inquilino_id = ?
      ORDER BY r.fecha_inicio DESC
    ''',
      [inquilinoId],
    );
  }

  static Future<Map<String, dynamic>?> obtenerRentaPorId(int rentaId) async {
    final db = await conecta();
    final result = await db.rawQuery(
      '''
      SELECT r.*, i.titulo as inmueble_titulo, i.rutas_imagen,
             u1.nombre as inquilino_nombre, u1.id as inquilino_id,
             u2.nombre as arrendador_nombre, u2.id as arrendador_id
      FROM rentas r
      INNER JOIN inmuebles i ON r.inmueble_id = i.id
      INNER JOIN usuarios u1 ON r.inquilino_id = u1.id
      INNER JOIN usuarios u2 ON r.arrendador_id = u2.id
      WHERE r.id = ?
    ''',
      [rentaId],
    );

    return result.isNotEmpty ? result.first : null;
  }

  static Future<bool> verificarInquilinoExiste(int inquilinoId) async {
    final db = await conecta();
    final result = await db.query(
      'usuarios',
      where: 'id = ? AND rol = ?',
      whereArgs: [inquilinoId, 'Inquilino'],
    );
    return result.isNotEmpty;
  }

  static Future<bool> inmuebleTieneRentaActiva(int inmuebleId) async {
    final db = await conecta();
    final result = await db.query(
      'rentas',
      where: 'inmueble_id = ? AND estado = ?',
      whereArgs: [inmuebleId, 'activa'],
    );
    return result.isNotEmpty;
  }

  static Future<int> actualizarEstadoRenta(int rentaId, String estado) async {
    final db = await conecta();
    return db.update(
      'rentas',
      {'estado': estado},
      where: 'id = ?',
      whereArgs: [rentaId],
    );
  }

  // ================== PAGOS DE RENTA ==================

  static Future<int> registrarPago(Map<String, dynamic> pago) async {
    final db = await conecta();
    return db.insert('pagos_renta', pago);
  }

  static Future<List<Map<String, dynamic>>> obtenerPagosPorRenta(
    int rentaId,
  ) async {
    final db = await conecta();
    return db.query(
      'pagos_renta',
      where: 'renta_id = ?',
      whereArgs: [rentaId],
      orderBy: 'anio ASC, mes ASC',
    );
  }

  static Future<int> actualizarEstadoPago(
    int pagoId,
    String estado,
    String? fechaPago,
  ) async {
    final db = await conecta();
    return db.update(
      'pagos_renta',
      {'estado': estado, if (fechaPago != null) 'fecha_pago': fechaPago},
      where: 'id = ?',
      whereArgs: [pagoId],
    );
  }

  static Future<Map<String, dynamic>?> obtenerProximoPago(int rentaId) async {
    final db = await conecta();
    final result = await db.query(
      'pagos_renta',
      where: 'renta_id = ? AND estado = ?',
      whereArgs: [rentaId, 'pendiente'],
      orderBy: 'fecha_vencimiento ASC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> generarPagosMensuales(
    int rentaId,
    DateTime fechaInicio,
    double monto,
    int diaPago,
    int meses,
  ) async {
    final db = await conecta();

    for (int i = 0; i < meses; i++) {
      final fecha = DateTime(fechaInicio.year, fechaInicio.month + i, diaPago);

      final mes = _getNombreMes(fecha.month);
      final anio = fecha.year;

      await db.insert('pagos_renta', {
        'renta_id': rentaId,
        'mes': mes,
        'anio': anio,
        'monto': monto,
        'fecha_vencimiento': fecha.toIso8601String(),
        'estado': 'pendiente',
      });
    }
  }

  static String _getNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[mes - 1];
  }

  // ================== NOTIFICACIONES ==================

  static Future<int> crearNotificacion({
    required int usuarioId,
    required String titulo,
    required String mensaje,
    String tipo = 'sistema',
  }) async {
    final db = await conecta();
    return db.insert('notificaciones', {
      'usuario_id': usuarioId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'leida': 0,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> obtenerNotificaciones(
    int usuarioId,
  ) async {
    final db = await conecta();
    return db.query(
      'notificaciones',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'fecha DESC',
    );
  }

  static Future<int> marcarComoLeida(int notificacionId) async {
    final db = await conecta();
    return db.update(
      'notificaciones',
      {'leida': 1},
      where: 'id = ?',
      whereArgs: [notificacionId],
    );
  }

  static Future<int> contarNoLeidas(int usuarioId) async {
    final db = await conecta();
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM notificaciones
      WHERE usuario_id = ? AND leida = 0
    ''',
      [usuarioId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  static Future<int> eliminarNotificacion(int notificacionId) async {
    final db = await conecta();
    return db.delete(
      'notificaciones',
      where: 'id = ?',
      whereArgs: [notificacionId],
    );
  }

  static Future<int> marcarTodasComoLeidas(int usuarioId) async {
    final db = await conecta();
    return db.update(
      'notificaciones',
      {'leida': 1},
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );
  }
}

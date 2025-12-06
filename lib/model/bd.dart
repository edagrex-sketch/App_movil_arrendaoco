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
      version: 3, // IMPORTANTE: versión 3 para agregar columna 'rol' a usuarios
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
}

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
      version: 1,
      onCreate: (Database db, int version) async {
        // ======== Tabla usuarios ========
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            nombre TEXT,
            password TEXT
          )
        ''');

        await db.insert('usuarios', {
          'username': 'admin',
          'nombre': 'Administrador',
          'password': '123',
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
      },
    );

    return _db!;
  }
}

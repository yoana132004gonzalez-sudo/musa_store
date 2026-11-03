import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init(); // única instancia
  static Database? _database;

  AppDatabase._init(); // constructor privado

  Future<Database> get database async {
    if (_database != null) return _database!; // reutiliza la conexión
    _database = await _initDB('musa_store.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      // SQLite ignora las claves foráneas por defecto: hay que activarlas en cada conexión
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB, // se ejecuta solo la primera vez
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      );
    ''');

    // costo: lo que le costó la prenda a la tienda (sirve para calcular la ganancia)
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria_id INTEGER NOT NULL,
        costo REAL NOT NULL DEFAULT 0,
        precio REAL NOT NULL,
        activo INTEGER DEFAULT 1,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id)
      );
    ''');

    // El stock vive en la variante (talle y color)
    await db.execute('''
      CREATE TABLE variantes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        talle TEXT,
        color TEXT,
        stock INTEGER DEFAULT 0,
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        activo INTEGER DEFAULT 1
      );
    ''');

    // es_fiado: 1 si la venta se hizo a cuenta (el cliente todavía no pagó todo)
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        es_fiado INTEGER DEFAULT 0,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
      );
    ''');

    // Se guardan precio y costo de ese momento, así un cambio futuro no altera ventas pasadas
    await db.execute('''
      CREATE TABLE detalle_venta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        variante_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        costo_unitario REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (venta_id) REFERENCES ventas(id),
        FOREIGN KEY (variante_id) REFERENCES variantes(id)
      );
    ''');

    // Cada plata que entra se registra acá. Saldo de un fiado = total de la venta - sus pagos
    await db.execute('''
      CREATE TABLE pagos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        cliente_id INTEGER,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        metodo_pago TEXT,
        FOREIGN KEY (venta_id) REFERENCES ventas(id),
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        categoria TEXT
      );
    ''');

    // Datos iniciales
    await db.insert('categorias', {'nombre': 'Mujer'});
    await db.insert('categorias', {'nombre': 'Hombre'});
    await db.insert('categorias', {'nombre': 'Accesorios'});
  }
}
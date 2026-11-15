import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/categoria_model.dart';
import '../models/producto_model.dart';

class ProductoDao {
  Future<List<Producto>> listarActivos() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.rawQuery('''
      SELECT p.*, c.nombre AS categoria_nombre,
        COALESCE((SELECT SUM(v.stock) FROM variantes v WHERE v.producto_id = p.id), 0) AS stock_total
      FROM productos p
      JOIN categorias c ON c.id = p.categoria_id
      WHERE p.activo = 1
      ORDER BY p.nombre COLLATE NOCASE
    ''');
    return filas.map((fila) => Producto.fromMap(fila)).toList();
  }

  Future<List<Categoria>> listarCategorias() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query('categorias', orderBy: 'id');
    return filas.map((fila) => Categoria.fromMap(fila)).toList();
  }

  Future<List<Variante>> variantesDe(int productoId) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'variantes',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'id',
    );
    return filas.map((fila) => Variante.fromMap(fila)).toList();
  }

  /// Guarda el producto y sus variantes juntos: o se guarda todo o no se guarda nada.
  Future<int> insertar(Producto producto, List<Variante> variantes) async {
    final db = await AppDatabase.instance.database;
    return await db.transaction((txn) async {
      final id = await txn.insert('productos', producto.toMap());
      for (final v in variantes) {
        await txn.insert('variantes', {
          'producto_id': id,
          'talle': v.talle,
          'color': v.color,
          'stock': v.stock,
        });
      }
      return id;
    });
  }

  Future<void> actualizar(Producto producto, List<Variante> variantes) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'productos',
        producto.toMap(),
        where: 'id = ?',
        whereArgs: [producto.id],
      );

      final existentes = await txn.query(
        'variantes',
        columns: ['id'],
        where: 'producto_id = ?',
        whereArgs: [producto.id],
      );
      final idsExistentes = existentes.map((f) => f['id'] as int).toList();
      final idsConservados =
          variantes.where((v) => v.id != null).map((v) => v.id!).toSet();

      // Las variantes que se sacaron de la lista: si ya se vendieron se deja
      // el stock en 0 para no perder el historial; si no, se borran.
      for (final id in idsExistentes) {
        if (idsConservados.contains(id)) continue;
        final usadas = Sqflite.firstIntValue(await txn.rawQuery(
              'SELECT COUNT(*) FROM detalle_venta WHERE variante_id = ?',
              [id],
            )) ??
            0;
        if (usadas > 0) {
          await txn.update('variantes', {'stock': 0},
              where: 'id = ?', whereArgs: [id]);
        } else {
          await txn.delete('variantes', where: 'id = ?', whereArgs: [id]);
        }
      }

      for (final v in variantes) {
        final datos = {
          'producto_id': producto.id,
          'talle': v.talle,
          'color': v.color,
          'stock': v.stock,
        };
        if (v.id == null) {
          await txn.insert('variantes', datos);
        } else {
          await txn.update('variantes', datos,
              where: 'id = ?', whereArgs: [v.id]);
        }
      }
    });
  }

  /// Baja lógica: el producto deja de mostrarse pero queda en el historial.
  Future<int> darDeBaja(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.update('productos', {'activo': 0},
        where: 'id = ?', whereArgs: [id]);
  }
}

import '../database/app_database.dart';
import '../models/cliente_model.dart';

class ClienteDao {
  Future<List<Cliente>> listarActivos() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'clientes',
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'nombre COLLATE NOCASE',
    );
    return filas.map((fila) => Cliente.fromMap(fila)).toList();
  }

  Future<int> insertar(Cliente cliente) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<int> actualizar(Cliente cliente) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<int> darDeBaja(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.update('clientes', {'activo': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> existeTelefono(String telefono, {int? excluirId}) async {
    final db = await AppDatabase.instance.database;
    final filas = excluirId == null
        ? await db.rawQuery(
            'SELECT COUNT(*) AS n FROM clientes WHERE activo = 1 AND telefono = ?',
            [telefono],
          )
        : await db.rawQuery(
            'SELECT COUNT(*) AS n FROM clientes WHERE activo = 1 AND telefono = ? AND id != ?',
            [telefono, excluirId],
          );
    return ((filas.first['n'] ?? 0) as int) > 0;
  }
}

import '../database/app_database.dart';
import '../models/gasto_model.dart';

class GastoDao {
  Future<List<Gasto>> listar() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query('gastos', orderBy: 'fecha DESC, id DESC');
    return filas.map((fila) => Gasto.fromMap(fila)).toList();
  }

  Future<int> insertar(Gasto gasto) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('gastos', gasto.toMap());
  }

  Future<int> actualizar(Gasto gasto) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'gastos',
      gasto.toMap(),
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  Future<int> eliminar(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }
}

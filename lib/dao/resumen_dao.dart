import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/resumen_model.dart';

class ResumenDao {
  Future<double> _suma(Database db, String sql, List<Object?> args) async {
    final filas = await db.rawQuery(sql, args);
    final valor = filas.first.values.first;
    return valor == null ? 0 : (valor as num).toDouble();
  }

  /// Calcula los totales entre dos fechas (desde incluida, hasta excluida).
  Future<Resumen> calcular(String desde, String hasta) async {
    final db = await AppDatabase.instance.database;
    final rango = [desde, hasta];

    final ventas = await _suma(
      db,
      'SELECT COALESCE(SUM(total), 0) FROM ventas WHERE fecha >= ? AND fecha < ?',
      rango,
    );
    final costo = await _suma(
      db,
      '''SELECT COALESCE(SUM(d.costo_unitario * d.cantidad), 0)
         FROM detalle_venta d
         JOIN ventas v ON v.id = d.venta_id
         WHERE v.fecha >= ? AND v.fecha < ?''',
      rango,
    );
    final cobrado = await _suma(
      db,
      'SELECT COALESCE(SUM(monto), 0) FROM pagos WHERE fecha >= ? AND fecha < ?',
      rango,
    );
    final gastos = await _suma(
      db,
      'SELECT COALESCE(SUM(monto), 0) FROM gastos WHERE fecha >= ? AND fecha < ?',
      rango,
    );

    return Resumen(
      ventas: ventas,
      costo: costo,
      cobrado: cobrado,
      gastos: gastos,
    );
  }
}

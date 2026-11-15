import '../database/app_database.dart';
import '../models/venta_model.dart';

class VentaDao {
  static const _consultaVentas = '''
    SELECT v.id, v.fecha, v.total, v.es_fiado, v.cliente_id,
      c.nombre AS cliente_nombre, c.telefono AS cliente_telefono,
      COALESCE((SELECT SUM(p.monto) FROM pagos p WHERE p.venta_id = v.id), 0) AS pagado
    FROM ventas v
    LEFT JOIN clientes c ON c.id = v.cliente_id
  ''';

  Future<List<VarianteVendible>> variantesConStock() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.rawQuery('''
      SELECT v.id AS variante_id, p.nombre AS producto, v.talle, v.color,
        v.stock, p.precio, p.costo
      FROM variantes v
      JOIN productos p ON p.id = v.producto_id
      WHERE p.activo = 1 AND v.stock > 0
      ORDER BY p.nombre COLLATE NOCASE, v.talle, v.color
    ''');
    return filas.map((f) => VarianteVendible.fromMap(f)).toList();
  }

  Future<List<VentaResumen>> listarVentas() async {
    final db = await AppDatabase.instance.database;
    final filas =
        await db.rawQuery('$_consultaVentas ORDER BY v.fecha DESC, v.id DESC');
    return filas.map((f) => VentaResumen.fromMap(f)).toList();
  }

  Future<VentaResumen?> ventaPorId(int id) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.rawQuery('$_consultaVentas WHERE v.id = ?', [id]);
    if (filas.isEmpty) return null;
    return VentaResumen.fromMap(filas.first);
  }

  Future<List<DetalleVenta>> detalleDe(int ventaId) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.rawQuery('''
      SELECT p.nombre AS producto, va.talle, va.color, d.cantidad, d.precio_unitario
      FROM detalle_venta d
      JOIN variantes va ON va.id = d.variante_id
      JOIN productos p ON p.id = va.producto_id
      WHERE d.venta_id = ?
      ORDER BY d.id
    ''', [ventaId]);
    return filas.map((f) => DetalleVenta.fromMap(f)).toList();
  }

  Future<List<Pago>> pagosDe(int ventaId) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'pagos',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
      orderBy: 'id',
    );
    return filas.map((f) => Pago.fromMap(f)).toList();
  }

  /// Registra la venta completa en una sola transacción: la venta, sus
  /// renglones, el descuento de stock y el pago inicial. Si algo falla,
  /// no se guarda nada.
  Future<int> registrarVenta({
    int? clienteId,
    required List<ItemVenta> items,
    required double total,
    required bool esFiado,
    required double pagoInicial,
    required String metodoPago,
  }) async {
    final db = await AppDatabase.instance.database;
    return await db.transaction((txn) async {
      final fecha = DateTime.now().toIso8601String();

      // 1. Verificar que haya stock de todo antes de guardar nada
      for (final item in items) {
        final filas = await txn.query(
          'variantes',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [item.variante.varianteId],
        );
        final stockActual =
            filas.isEmpty ? 0 : (filas.first['stock'] as num).toInt();
        if (stockActual < item.cantidad) {
          throw Exception(
            'No hay stock suficiente de ${item.variante.producto} ${item.variante.detalle}',
          );
        }
      }

      // 2. Guardar la venta
      final ventaId = await txn.insert('ventas', {
        'cliente_id': clienteId,
        'fecha': fecha,
        'total': total,
        'es_fiado': esFiado ? 1 : 0,
      });

      // 3. Guardar cada renglón y descontar el stock
      for (final item in items) {
        await txn.insert('detalle_venta', {
          'venta_id': ventaId,
          'variante_id': item.variante.varianteId,
          'cantidad': item.cantidad,
          'precio_unitario': item.variante.precio,
          'costo_unitario': item.variante.costo,
        });
        await txn.rawUpdate(
          'UPDATE variantes SET stock = stock - ? WHERE id = ?',
          [item.cantidad, item.variante.varianteId],
        );
      }

      // 4. Registrar lo que se cobró en el momento
      if (pagoInicial > 0) {
        await txn.insert('pagos', {
          'venta_id': ventaId,
          'cliente_id': clienteId,
          'monto': pagoInicial,
          'fecha': fecha,
          'metodo_pago': metodoPago,
        });
      }

      return ventaId;
    });
  }

  Future<void> registrarPago({
    required int ventaId,
    int? clienteId,
    required double monto,
    required String metodo,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert('pagos', {
      'venta_id': ventaId,
      'cliente_id': clienteId,
      'monto': monto,
      'fecha': DateTime.now().toIso8601String(),
      'metodo_pago': metodo,
    });
  }
}

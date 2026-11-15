/// Una variante (talle y color) que se puede vender, con su producto y precio.
class VarianteVendible {
  final int varianteId;
  final String producto;
  final String talle;
  final String color;
  final int stock;
  final double precio;
  final double costo;

  VarianteVendible({
    required this.varianteId,
    required this.producto,
    required this.talle,
    required this.color,
    required this.stock,
    required this.precio,
    required this.costo,
  });

  factory VarianteVendible.fromMap(Map<String, dynamic> map) =>
      VarianteVendible(
        varianteId: map['variante_id'] as int,
        producto: map['producto'] as String,
        talle: (map['talle'] ?? '') as String,
        color: (map['color'] ?? '') as String,
        stock: (map['stock'] as num).toInt(),
        precio: (map['precio'] as num).toDouble(),
        costo: (map['costo'] as num).toDouble(),
      );

  String get detalle {
    final partes = <String>[];
    if (talle.isNotEmpty) partes.add(talle);
    if (color.isNotEmpty) partes.add(color);
    return partes.join(' · ');
  }
}

/// Un renglón de la venta que se está armando.
class ItemVenta {
  final VarianteVendible variante;
  int cantidad;

  ItemVenta({required this.variante, this.cantidad = 1});

  double get subtotal => variante.precio * cantidad;
}

/// Una venta ya registrada, con lo que se pagó hasta ahora.
class VentaResumen {
  final int id;
  final String fecha;
  final double total;
  final bool esFiado;
  final int? clienteId;
  final String? clienteNombre;
  final String? clienteTelefono;
  final double pagado;

  VentaResumen({
    required this.id,
    required this.fecha,
    required this.total,
    required this.esFiado,
    this.clienteId,
    this.clienteNombre,
    this.clienteTelefono,
    required this.pagado,
  });

  /// Lo que todavía se debe de esta venta.
  double get saldo {
    final resto = total - pagado;
    return resto < 0.005 ? 0 : resto;
  }

  factory VentaResumen.fromMap(Map<String, dynamic> map) => VentaResumen(
        id: map['id'] as int,
        fecha: map['fecha'] as String,
        total: (map['total'] as num).toDouble(),
        esFiado: ((map['es_fiado'] ?? 0) as num).toInt() == 1,
        clienteId: map['cliente_id'] as int?,
        clienteNombre: map['cliente_nombre'] as String?,
        clienteTelefono: map['cliente_telefono'] as String?,
        pagado: ((map['pagado'] ?? 0) as num).toDouble(),
      );
}

class DetalleVenta {
  final String producto;
  final String talle;
  final String color;
  final int cantidad;
  final double precioUnitario;

  DetalleVenta({
    required this.producto,
    required this.talle,
    required this.color,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory DetalleVenta.fromMap(Map<String, dynamic> map) => DetalleVenta(
        producto: map['producto'] as String,
        talle: (map['talle'] ?? '') as String,
        color: (map['color'] ?? '') as String,
        cantidad: (map['cantidad'] as num).toInt(),
        precioUnitario: (map['precio_unitario'] as num).toDouble(),
      );

  double get subtotal => precioUnitario * cantidad;

  String get descripcion {
    final partes = <String>[producto];
    if (talle.isNotEmpty) partes.add(talle);
    if (color.isNotEmpty) partes.add(color);
    return partes.join(' · ');
  }
}

class Pago {
  final int? id;
  final double monto;
  final String fecha;
  final String metodo;

  Pago({this.id, required this.monto, required this.fecha, required this.metodo});

  factory Pago.fromMap(Map<String, dynamic> map) => Pago(
        id: map['id'] as int?,
        monto: (map['monto'] as num).toDouble(),
        fecha: map['fecha'] as String,
        metodo: (map['metodo_pago'] ?? '') as String,
      );
}

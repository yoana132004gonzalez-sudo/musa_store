/// Una variante es un talle y color de un producto, con su propio stock.
class Variante {
  final int? id;
  final String talle;
  final String color;
  final int stock;

  Variante({
    this.id,
    required this.talle,
    required this.color,
    required this.stock,
  });

  factory Variante.fromMap(Map<String, dynamic> map) => Variante(
        id: map['id'] as int?,
        talle: (map['talle'] ?? '') as String,
        color: (map['color'] ?? '') as String,
        stock: ((map['stock'] ?? 0) as num).toInt(),
      );
}

class Producto {
  final int? id;
  final String nombre;
  final int categoriaId;
  final double costo;
  final double precio;
  final int activo;

  // Datos que vienen de la consulta, solo para mostrar en pantalla
  final String categoriaNombre;
  final int stockTotal;

  Producto({
    this.id,
    required this.nombre,
    required this.categoriaId,
    required this.costo,
    required this.precio,
    this.activo = 1,
    this.categoriaNombre = '',
    this.stockTotal = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'categoria_id': categoriaId,
        'costo': costo,
        'precio': precio,
        'activo': activo,
      };

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        categoriaId: map['categoria_id'] as int,
        costo: (map['costo'] as num).toDouble(),
        precio: (map['precio'] as num).toDouble(),
        activo: ((map['activo'] ?? 1) as num).toInt(),
        categoriaNombre: (map['categoria_nombre'] ?? '') as String,
        stockTotal: ((map['stock_total'] ?? 0) as num).toInt(),
      );
}

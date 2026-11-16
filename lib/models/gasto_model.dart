class Gasto {
  final int? id;
  final String descripcion;
  final double monto;
  final String fecha;
  final String categoria;

  Gasto({
    this.id,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.categoria,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'descripcion': descripcion,
        'monto': monto,
        'fecha': fecha,
        'categoria': categoria,
      };

  factory Gasto.fromMap(Map<String, dynamic> map) => Gasto(
        id: map['id'] as int?,
        descripcion: map['descripcion'] as String,
        monto: (map['monto'] as num).toDouble(),
        fecha: map['fecha'] as String,
        categoria: (map['categoria'] ?? 'Otros') as String,
      );
}

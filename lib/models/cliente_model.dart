class Cliente {
  final int? id;
  final String nombre;
  final String? telefono;
  final int activo;

  Cliente({
    this.id,
    required this.nombre,
    this.telefono,
    this.activo = 1,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'activo': activo,
      };

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        telefono: map['telefono'] as String?,
        activo: ((map['activo'] ?? 1) as num).toInt(),
      );
}

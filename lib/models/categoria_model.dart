class Categoria {
  final int id;
  final String nombre;

  Categoria({required this.id, required this.nombre});

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
      );
}

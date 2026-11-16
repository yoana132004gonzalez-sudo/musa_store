/// Devuelve un importe con puntos de miles y signo pesos. Ej: 1500 -> $1.500
String pesos(double valor) {
  final negativo = valor < 0;
  final entero = valor.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < entero.length; i++) {
    final desdeElFinal = entero.length - i;
    buffer.write(entero[i]);
    if (desdeElFinal > 1 && desdeElFinal % 3 == 1) buffer.write('.');
  }
  return '${negativo ? '-' : ''}\$${buffer.toString()}';
}

/// Convierte una fecha guardada como texto ISO a dd/MM/yyyy HH:mm
String fechaHora(String iso) {
  final f = DateTime.tryParse(iso);
  if (f == null) return iso;
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
}

/// Convierte una fecha guardada como texto ISO a dd/MM/yyyy
String fechaCorta(String iso) {
  final f = DateTime.tryParse(iso);
  if (f == null) return iso;
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year}';
}

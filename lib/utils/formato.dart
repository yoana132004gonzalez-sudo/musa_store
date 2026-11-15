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

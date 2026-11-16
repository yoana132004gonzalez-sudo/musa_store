/// Totales de un período (hoy, este mes o todo el historial).
class Resumen {
  final double ventas;
  final double costo;
  final double cobrado;
  final double gastos;

  Resumen({
    required this.ventas,
    required this.costo,
    required this.cobrado,
    required this.gastos,
  });

  /// Lo vendido menos lo que costó la mercadería vendida.
  double get ganancia => ventas - costo;

  /// La ganancia menos los gastos de la tienda.
  double get resultado => ganancia - gastos;

  /// La plata que realmente entró menos los gastos.
  double get disponible => cobrado - gastos;
}

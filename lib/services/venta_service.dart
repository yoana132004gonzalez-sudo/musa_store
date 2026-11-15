import '../dao/venta_dao.dart';
import '../models/cliente_model.dart';
import '../models/venta_model.dart';
import '../utils/formato.dart';

/// Reglas de negocio de las ventas y los pagos.
class VentaService {
  final _dao = VentaDao();

  Future<List<VarianteVendible>> variantesConStock() =>
      _dao.variantesConStock();

  Future<List<VentaResumen>> listar() => _dao.listarVentas();

  Future<VentaResumen?> obtener(int id) => _dao.ventaPorId(id);

  Future<List<DetalleVenta>> detalle(int id) => _dao.detalleDe(id);

  Future<List<Pago>> pagos(int id) => _dao.pagosDe(id);

  Future<void> registrarVenta({
    Cliente? cliente,
    required List<ItemVenta> items,
    required bool esFiado,
    required double pagoInicial,
    required String metodoPago,
  }) async {
    if (items.isEmpty) {
      throw Exception('Agregá al menos un producto');
    }
    if (esFiado && cliente == null) {
      throw Exception('Un fiado necesita un cliente');
    }
    final total = items.fold(0.0, (suma, item) => suma + item.subtotal);
    final pago = esFiado ? pagoInicial : total;
    if (pago < 0) {
      throw Exception('La entrega no puede ser negativa');
    }
    if (pago > total) {
      throw Exception('La entrega no puede superar el total');
    }

    await _dao.registrarVenta(
      clienteId: cliente?.id,
      items: items,
      total: total,
      esFiado: esFiado,
      pagoInicial: pago,
      metodoPago: metodoPago,
    );
  }

  Future<void> registrarPago(
    VentaResumen venta,
    double monto,
    String metodo,
  ) async {
    if (monto <= 0) {
      throw Exception('El monto tiene que ser mayor a 0');
    }
    final actual = await _dao.ventaPorId(venta.id);
    if (actual == null) {
      throw Exception('No se encontró la venta');
    }
    if (monto > actual.saldo + 0.005) {
      throw Exception('El pago supera lo que se debe (${pesos(actual.saldo)})');
    }
    await _dao.registrarPago(
      ventaId: venta.id,
      clienteId: actual.clienteId,
      monto: monto,
      metodo: metodo,
    );
  }
}

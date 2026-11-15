import '../dao/cliente_dao.dart';
import '../models/cliente_model.dart';

/// Reglas de negocio de los clientes.
class ClienteService {
  final _dao = ClienteDao();

  Future<List<Cliente>> listar() => _dao.listarActivos();

  Future<void> darDeBaja(int id) => _dao.darDeBaja(id);

  /// Deja solo los números. Si tiene 10 dígitos (código de área + número),
  /// le agrega 549 para que funcione el enlace de WhatsApp en Argentina.
  String normalizarTelefono(String texto) {
    var digitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
    while (digitos.startsWith('0')) {
      digitos = digitos.substring(1);
    }
    if (!digitos.startsWith('54') && digitos.length == 10) {
      digitos = '549$digitos';
    }
    return digitos;
  }

  Future<void> guardar(Cliente cliente) async {
    final nombre = cliente.nombre.trim();
    if (nombre.isEmpty) {
      throw Exception('El nombre es obligatorio');
    }

    final telefono = normalizarTelefono(cliente.telefono ?? '');
    if (telefono.isNotEmpty && telefono.length < 10) {
      throw Exception('El teléfono parece incompleto. Incluí el código de área.');
    }
    if (telefono.isNotEmpty &&
        await _dao.existeTelefono(telefono, excluirId: cliente.id)) {
      throw Exception('Ya hay un cliente con ese teléfono');
    }

    final limpio = Cliente(
      id: cliente.id,
      nombre: nombre,
      telefono: telefono.isEmpty ? null : telefono,
    );
    if (limpio.id == null) {
      await _dao.insertar(limpio);
    } else {
      await _dao.actualizar(limpio);
    }
  }
}

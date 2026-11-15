import 'package:url_launcher/url_launcher.dart';

/// Abre WhatsApp con el chat del cliente y el mensaje ya escrito (deep link).
Future<void> abrirWhatsApp(String telefono, String mensaje) async {
  final uri = Uri.parse(
    'https://wa.me/$telefono?text=${Uri.encodeComponent(mensaje)}',
  );
  final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!abierto) {
    throw Exception('No se pudo abrir WhatsApp');
  }
}

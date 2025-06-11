import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QrIngresoPage extends StatefulWidget {
  const QrIngresoPage({super.key});

  @override
  State<QrIngresoPage> createState() => _QrIngresoPageState();
}

class _QrIngresoPageState extends State<QrIngresoPage> {
  final supabase = Supabase.instance.client;
  bool escaneando = true;

  Future<void> ingresarAListaEspera() async {
    final usuario = supabase.auth.currentUser;
    final usuarioId = usuario?.id;

    if (usuarioId == null) {
      _mostrarSnackbar('Usuario no autenticado');
      return;
    }

    try {
      final yaRegistrado = await supabase
          .from('ingresos_local')
          .select('id')
          .eq('usuario_id', usuarioId)
          .eq('estado', 'esperando')
          .maybeSingle();

      if (yaRegistrado != null) {
        _mostrarSnackbar('Ya estás en la lista de espera');
        _volverAlHome();
        return;
      }

      final userData = await supabase
          .from('usuarios')
          .select('nombre')
          .eq('id', usuarioId)
          .single();

      final nombre = userData['nombre'] ?? 'Anónimo';

      await supabase.from('ingresos_local').insert({
        'usuario_id': usuarioId,
        'nombre': nombre,
        'estado': 'esperando',
        'fecha_hora': DateTime.now().toIso8601String(),
      });

      _mostrarSnackbar('¡Ingresaste a la lista de espera!');
      _volverAlHome();
    } catch (e) {
      _mostrarSnackbar('Error al registrar ingreso: $e');
    }
  }

  void _mostrarSnackbar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _volverAlHome() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  bool _yaDetectado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear QR para ingreso")),
      body: MobileScanner(
        controller: MobileScannerController(),
        onDetect: (capture) {
          if (_yaDetectado) return;

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? valor = barcodes.first.rawValue;
            if (valor != null && valor.isNotEmpty) {
              _yaDetectado = true;
              if (valor == 'PERMITIDO') {
                ingresarAListaEspera();
              } else {
                _mostrarSnackbar('QR inválido para ingreso');
                _volverAlHome();
              }
            }
          }
        },
      ),
    );
  }
}

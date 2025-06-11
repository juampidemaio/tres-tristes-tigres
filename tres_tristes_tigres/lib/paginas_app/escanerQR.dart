import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tres_tristes_tigres/paginas_app/principalCliente.dart';
import '../supabase_service.dart';

class Escanerqr extends StatefulWidget {
  const Escanerqr({super.key});

  @override
  State<Escanerqr> createState() => _EscanerqrState();
}

class _EscanerqrState extends State<Escanerqr> {
  final MobileScannerController _controller = MobileScannerController();
  bool _yaDetectado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) async {
          if (_yaDetectado) return;
          _yaDetectado = true;

          final List<Barcode> barcodes = capture.barcodes;
          final String? codigo = barcodes.first.rawValue;

          if (codigo != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Principalcliente(url: codigo)),
            );
          } else {
            _yaDetectado = false;
          }
        },
      ),
    );
  }
}

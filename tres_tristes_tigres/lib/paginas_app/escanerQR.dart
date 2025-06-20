import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tres_tristes_tigres/paginas_app/principalCliente.dart';
import '../supabase_service.dart';
import '../supabase_service.dart';

class Escanerqr extends StatefulWidget {
  final bool puedePedirCuenta;
  const Escanerqr({super.key, this.puedePedirCuenta = false});

  @override
  State<Escanerqr> createState() => _EscanerqrState();
}

class _EscanerqrState extends State<Escanerqr> {
  final sb = SupabaseService();
  final MobileScannerController _controller = MobileScannerController();
  bool _yaDetectado = false;
  String estadoPedido = "";

  @override
  void initState() {
    setState(() {
      comprobarPedidoHecho();
    });
  }

  comprobarPedidoHecho() async {
    estadoPedido = await sb.verificarClienteHizoPedido(
      SupabaseService.client.auth.currentUser!.email!,
    );
  }

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

          if (codigo != null && estadoPedido == "") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Principalcliente(url: codigo)),
            );
          } else {
            _yaDetectado = false;
          }

          if (codigo != null &&
              estadoPedido == "recibido" &&
              widget.puedePedirCuenta) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => Principalcliente(
                      url: codigo,
                      estadoPedido: estadoPedido,
                      escaneoRealizado: true,
                      puedePedirCuenta: true,
                    ),
              ),
            );
          } else {
            _yaDetectado = false;
          }

          if (codigo != null &&
                  estadoPedido == "recibido" &&
                  !widget.puedePedirCuenta ||
              codigo != null && estadoPedido == "entregado") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => Principalcliente(
                      url: codigo,
                      estadoPedido: estadoPedido,
                      escaneoRealizado: true,
                    ),
              ),
            );
          } else {
            _yaDetectado = false;
          }

          if (codigo != null && estadoPedido == "enProceso") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => Principalcliente(
                      url: codigo,
                      estadoPedido: estadoPedido,
                      escaneoRealizado: true, // <-- acá lo pasás
                    ),
              ),
            );
          } else {
            _yaDetectado = false;
          }

          if (codigo != null && estadoPedido == "paraEnviar") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => Principalcliente(
                      url: codigo,
                      estadoPedido: estadoPedido, // <-- acá lo pasás
                      escaneoRealizado: true,
                    ),
              ),
            );
          } else {
            _yaDetectado = false;
          }

          if (codigo != null && estadoPedido == "pendiente") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => Principalcliente(
                      url: codigo,
                      estadoPedido: estadoPedido, // <-- acá lo pasás
                      escaneoRealizado: true,
                    ),
              ),
            );
          } else {
            _yaDetectado = false;
          }
        },
      ),
    );
  }
}

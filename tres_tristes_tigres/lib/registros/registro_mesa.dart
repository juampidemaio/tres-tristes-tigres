import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../supabase_service.dart';
import '../classes/mesa.dart';
import 'package:flutter/foundation.dart';
import '../home.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:qr/qr.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RegistroMesa extends StatefulWidget {
  const RegistroMesa({super.key});

  @override
  State<RegistroMesa> createState() => _RegistroMesaState();
}

class _RegistroMesaState extends State<RegistroMesa> {
  final _formKey = GlobalKey<FormState>();
  final supabaseService = SupabaseService();

  final numeroMesaController = TextEditingController();
  final nroComensalesController = TextEditingController();
  String? tipoMesaSeleccionado;
  Uint8List? imagenSeleccionadaBytes;

  Future<Uint8List?> tomarFoto() async {
    final picker = ImagePicker();
    XFile? foto;
    if (kIsWeb) {
      foto = await picker.pickImage(source: ImageSource.gallery);
    } else {
      foto = await picker.pickImage(source: ImageSource.camera);
    }

    if (foto != null) {
      final bytes = await foto.readAsBytes();

      setState(() {
        imagenSeleccionadaBytes = bytes;
      });
      return bytes;
    } else {
      return null;
    }
  }

  Future<String?> guardarFotoStorage(int numeroMesa) async {
    final nombreArchivo =
        'mesas/mesa${numeroMesa}_' +
        DateTime.now().millisecondsSinceEpoch.toString() +
        '.jpg';
    var url = null;

    if (imagenSeleccionadaBytes != null) {
      url = await supabaseService.subirImagenASupabase(
        await imagenSeleccionadaBytes!,
        nombreArchivo,
      );
    }

    return url;
  }

  guardarMesaBD() async {
    final nroMesa = int.parse(numeroMesaController.text);
    var urlImagen = await guardarFotoStorage(nroMesa);
    var urlQR = await subirQR(nroMesa);

    if (urlImagen != null) {
      var mesa = Mesa(
        numero: nroMesa,
        nroComensales: int.parse(nroComensalesController.text),
        tipo: tipoMesaSeleccionado!,
        imagen: urlImagen,
        qr: urlQR,
        estadoMesa: "libre",
      );

      try {
        if (urlImagen != null) {
          await supabaseService.agregarMesa(mesa);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Mesa registrada correctamente"),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.yellow,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        var mensaje = "";
        if (e.toString().contains('23505')) {
          mensaje = "Ya existe una mesa con ese número";
        } else {
          mensaje = "Error al registrar la mesa";
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<Uint8List> generarQR(int numeroMesa) async {
    final qrData = "https://app02.com/mesas/${numeroMesa}";

    final qrValidationResult = QrValidator.validate(
      data: qrData,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    final qrCode = qrValidationResult.qrCode!;

    final painter = QrPainter.withQr(
      qr: qrCode,
      color: ui.Color(0xFF000000),
      emptyColor: ui.Color(0xFFFFFFFF),
      gapless: true,
    );

    final ui.Image img = await painter.toImage(600);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    return pngBytes;
  }

  Future<String> subirQR(int numeroMesa) async {
    var urlImagen = null;
    final nombreArchivo =
        'mesasQR/QRmesa${numeroMesa}_' +
        DateTime.now().millisecondsSinceEpoch.toString() +
        '.jpg';
    var bytesQR = await generarQR(numeroMesa);

    urlImagen = await supabaseService.subirImagenASupabase(
      bytesQR,
      nombreArchivo,
    );

    return urlImagen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alta de Mesa'),
        backgroundColor: const Color(0xFF5E35B1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Alta de Mesa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: numeroMesaController,
                decoration: const InputDecoration(labelText: 'Número mesa'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obligatorio';
                  }
                  final n = int.tryParse(value);
                  if (n == null) {
                    return 'Debe ingresar un número válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: nroComensalesController,
                decoration: const InputDecoration(
                  labelText: 'Número de comensales',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obligatorio';
                  }
                  final n = int.tryParse(value);
                  if (n == null) {
                    return 'Debe ingresar un número válido';
                  }
                  if (n > 20) {
                    return 'El máximo de  comensales es de 20';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: tipoMesaSeleccionado,
                items:
                    ['Estándar', 'VIP', 'Apta discapacitados'].map((
                      String tipo,
                    ) {
                      return DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    tipoMesaSeleccionado = newValue;
                  });
                },
                decoration: InputDecoration(labelText: 'Tipo de mesa'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Debe seleccionar un tipo de mesa'
                            : null,
              ),
              const SizedBox(height: 10),
              imagenSeleccionadaBytes != null
                  ? Image.memory(imagenSeleccionadaBytes!, height: 100)
                  : const Text('No se ha seleccionado imagen'),
              ElevatedButton.icon(
                onPressed: tomarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tomar Foto'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await guardarMesaBD();
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Registrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E35B1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

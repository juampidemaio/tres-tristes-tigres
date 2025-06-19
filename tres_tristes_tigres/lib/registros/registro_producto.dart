import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../supabase_service.dart';
import '../classes/producto.dart';
import 'package:flutter/foundation.dart';
import '../home.dart';
import 'dart:ui' as ui;
import 'package:qr/qr.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RegistroProducto extends StatefulWidget {
  const RegistroProducto({super.key});

  @override
  State<RegistroProducto> createState() => _RegistroProductoState();
}

class _RegistroProductoState extends State<RegistroProducto> {
  final _formKey = GlobalKey<FormState>();
  final supabaseService = SupabaseService();

  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final tiempoPromedioController = TextEditingController();
  final precioController = TextEditingController();
  
  List<Uint8List?> imagenesSeleccionadas = [null, null, null];
  int fotoActual = 0;

  // Nueva variable para el tipo de producto
  String? tipoSeleccionado;
  final List<Map<String, String>> tiposProducto = [
    {'display': 'Comida', 'value': 'comida'},
    {'display': 'Bebida', 'value': 'bebida'},
    {'display': 'Postre', 'value': 'postre'},
  ];

  Future<void> tomarFoto(int indice) async {
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
        imagenesSeleccionadas[indice] = bytes;
      });
    }
  }

  Future<List<String?>> guardarFotosStorage(String nombreProducto) async {
    List<String?> urls = [];
    
    for (int i = 0; i < imagenesSeleccionadas.length; i++) {
      if (imagenesSeleccionadas[i] != null) {
        final nombreArchivo = 'productos/${nombreProducto}_foto${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final url = await supabaseService.subirImagenASupabase(
          imagenesSeleccionadas[i]!,
          nombreArchivo,
        );
        urls.add(url);
      } else {
        urls.add(null);
      }
    }
    
    return urls;
  }

  Future<Uint8List> generarQRProducto(String nombreProducto) async {
    final qrData = "https://app02.com/productos/${nombreProducto.replaceAll(' ', '_')}";

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

  Future<String?> subirQRProducto(String nombreProducto) async {
    final nombreArchivo = 'productosQR/QR_${nombreProducto.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
    final bytesQR = await generarQRProducto(nombreProducto);

    final urlImagen = await supabaseService.subirImagenASupabase(
      bytesQR,
      nombreArchivo,
    );

    return urlImagen;
  }

  Future<void> guardarProductoBD() async {
    final nombre = nombreController.text.trim();
    final descripcion = descripcionController.text.trim();
    final tiempoPromedio = int.parse(tiempoPromedioController.text);
    final precio = double.parse(precioController.text);

    // Validar que al menos una foto esté seleccionada
    bool tieneFotos = imagenesSeleccionadas.any((imagen) => imagen != null);
    if (!tieneFotos) {
      _mostrarError("Debe seleccionar al menos una foto del producto");
      return;
    }

    // Verificar si ya existe un producto con el mismo nombre
    try {
      final existe = await supabaseService.existeProductoPorNombre(nombre);
      if (existe) {
        _mostrarError("Ya existe un producto con el nombre '$nombre'");
        return;
      }
    } catch (e) {
      _mostrarError("Error al verificar la existencia del producto. Inténtelo nuevamente.");
      return;
    }

    // Mostrar indicador de carga
    _mostrarCargando();

    try {
      // Subir fotos
      final urlsFotos = await guardarFotosStorage(nombre);
      
      // Generar y subir QR
      final urlQR = await subirQRProducto(nombre);

      // Crear objeto producto con tipo
      final producto = Producto(
        nombre: nombre,
        descripcion: descripcion,
        tiempoPromedio: tiempoPromedio,
        precio: precio,
        foto1: urlsFotos[0],
        foto2: urlsFotos[1],
        foto3: urlsFotos[2],
        codigoQr: urlQR,
        tipo: tipoSeleccionado!,
      );

      // Guardar en base de datos
      await supabaseService.agregarProducto(producto);

      // Ocultar indicador de carga
      Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Producto registrado exitosamente"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'IR AL INICIO',
              textColor: Colors.white,
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
    } catch (e) {
      // Ocultar indicador de carga si está visible
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      String mensaje = _obtenerMensajeError(e);
      _mostrarError(mensaje);
    }
  }

  void _mostrarError(String mensaje) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ $mensaje"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _mostrarCargando() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Guardando producto..."),
            ],
          ),
        );
      },
    );
  }

  String _obtenerMensajeError(dynamic error) {
    String errorString = error.toString().toLowerCase();
    
    if (errorString.contains('23505') || errorString.contains('duplicate')) {
      return "Ya existe un producto con ese nombre";
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return "Error de conexión. Verifique su internet e inténtelo nuevamente";
    } else if (errorString.contains('timeout')) {
      return "La operación tardó demasiado. Inténtelo nuevamente";
    } else if (errorString.contains('storage') || errorString.contains('upload')) {
      return "Error al subir las imágenes. Inténtelo nuevamente";
    } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
      return "No tiene permisos para realizar esta acción";
    } else if (errorString.contains('validation') || errorString.contains('invalid')) {
      return "Los datos ingresados no son válidos";
    } else {
      return "Error inesperado al registrar el producto. Inténtelo nuevamente";
    }
  }

  Widget _buildFotoContainer(int indice) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text('Foto ${indice + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: imagenesSeleccionadas[indice] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imagenesSeleccionadas[indice]!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => tomarFoto(indice),
            icon: const Icon(Icons.camera_alt, size: 16),
            label: Text(imagenesSeleccionadas[indice] != null ? 'Cambiar' : 'Tomar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E35B1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alta de Producto'),
        backgroundColor: const Color(0xFF5E35B1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar Nuevo Producto',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Nombre del producto
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre del producto es obligatorio';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  if (value.trim().length > 50) {
                    return 'El nombre no puede superar los 50 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción del producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Describa los ingredientes y características del producto...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  if (value.trim().length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  if (value.trim().length > 500) {
                    return 'La descripción no puede superar los 500 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo de producto - COMBO BOX ESTILIZADO
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de producto',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: tiposProducto.map((tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo['value'],
                      child: Text(tipo['display']!),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      tipoSeleccionado = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Debe seleccionar el tipo de producto';
                    }
                    return null;
                  },
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5E35B1)),
                  style: const TextStyle(color: Colors.black),
                  dropdownColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Tiempo promedio de elaboración
              TextFormField(
                controller: tiempoPromedioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de elaboración (minutos)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                  suffix: Text('min'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El tiempo de elaboración es obligatorio';
                  }
                  final tiempo = int.tryParse(value);
                  if (tiempo == null) {
                    return 'Debe ingresar un número válido';
                  }
                  if (tiempo <= 0) {
                    return 'El tiempo debe ser mayor a 0 minutos';
                  }
                  if (tiempo > 300) {
                    return 'El tiempo no puede superar los 300 minutos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Precio
              TextFormField(
                controller: precioController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio del producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  final precio = double.tryParse(value);
                  if (precio == null) {
                    return 'Debe ingresar un precio válido';
                  }
                  if (precio <= 0) {
                    return 'El precio debe ser mayor a \$0';
                  }
                  if (precio > 999999) {
                    return 'El precio no puede superar los \$999,999';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Sección de fotos
              const Text(
                'Fotos del producto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFotoContainer(0),
                  _buildFotoContainer(1),
                  _buildFotoContainer(2),
                ],
              ),
              const SizedBox(height: 32),

              // Botón registrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await guardarProductoBD();
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Registrar Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E35B1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    tiempoPromedioController.dispose();
    precioController.dispose();
    super.dispose();
  }
}
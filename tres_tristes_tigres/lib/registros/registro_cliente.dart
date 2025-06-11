import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../login.dart';

class RegistroCliente extends StatefulWidget {
  final String perfil; // 'cliente_anonimo' o 'cliente_registrado'
  const RegistroCliente({super.key, required this.perfil});

  @override
  State<RegistroCliente> createState() => _RegistroClienteState();
}

class _RegistroClienteState extends State<RegistroCliente> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final dniController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();


  File? imagen;
  bool isLoading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );
    if (picked != null) {
      setState(() {
        imagen = File(picked.path);
      });
    }
  }

  Future<String?> subirImagen(String userId) async {
    if (imagen == null) return null;
    final nombreArchivo = '${const Uuid().v4()}.jpg';
    final ruta = 'usuarios/$userId/$nombreArchivo';
    final bytes = await imagen!.readAsBytes();

    await supabase.storage
        .from('fotos')
        .uploadBinary(
          ruta,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return supabase.storage.from('fotos').getPublicUrl(ruta);
  }

  void mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder:
          (_) =>
              AlertDialog(title: const Text('❌ Error'), content: Text(mensaje)),
    );
  }

  void procesarDatosDesdeQR(String data) {
    final partes = data.split('@');
    print('Partes del QR: $partes'); // Para debug
    if (partes.length >= 5) {
      setState(() {
        apellidoController.text = partes[1];
        nombreController.text = partes[2];
        dniController.text = partes[4]; // Cambié de [3] a [4]
      });
    } else {
      mostrarError('El QR no tiene el formato correcto.');
    }
  }



Future<void> notificarAlDueno(String nombreCliente) async {
  print('🔔 Iniciando notificación para $nombreCliente');

  final response = await supabase
      .from('usuarios')
      .select('id')
      .filter('perfil', 'in', ['dueño', 'supervisor']);

  print('📋 Dueños y supervisores encontrados: $response');

  if (response == null || response.isEmpty) {
    print('⚠️ No hay dueños o supervisores registrados.');
    return;
  }

  final ids = response.map((u) => u['id']).toList();
  print('🆔 IDs extraídos: $ids');

  final tokensRes = await supabase
      .from('user_tokens')
      .select('fcm_token, usuario_id')
      .inFilter('usuario_id', ids);

  print('📱 Tokens encontrados: $tokensRes');

  if (tokensRes == null || tokensRes.isEmpty) {
    print('⚠️ No hay tokens registrados.');
    return;
  }

  final url = Uri.parse('https://push-notif-api-iz1o.onrender.com/send-notification');

  for (final row in tokensRes) {
    final token = row['fcm_token'];
    print('🚀 Enviando a token: $token');

    if (token != null) {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': 'Nuevo cliente registrado',
          'body': '$nombreCliente se ha registrado y espera aprobación.',
        }),
      );
      print('📨 Respuesta del servidor: ${res.statusCode} - ${res.body}');
    }
  }
}



  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (imagen == null) {
      mostrarError('Debes tomar una foto.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (res.user == null) throw 'No se pudo registrar el usuario.';
      final userId = res.user!.id;

      final fotoUrl = await subirImagen(userId);

      final Map<String, dynamic> data = {
        'id': userId,
        'email': emailController.text.trim(),
        'nombre': nombreController.text.trim(),
        'perfil': widget.perfil,
        'foto_url': fotoUrl,
      };

      if (widget.perfil == 'cliente_registrado') {
        data.addAll({
          'apellido': apellidoController.text.trim(),
          'dni': dniController.text.trim(),
          'aprobado': 'pendiente',
        });
      }

      await supabase.from('usuarios').insert(data);

      await notificarAlDueno(nombreController.text);

      

      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                content: Text(
                  widget.perfil == 'cliente_anonimo'
                      ? '✅ Cliente anónimo registrado correctamente.'
                      : '✅ Registro exitoso. Espera la aprobación del supervisor o dueño.',
                ),
                actions: [
                  TextButton(
                    onPressed:
                        () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (_) => false,
                        ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      mostrarError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAnonimo = widget.perfil == 'cliente_anonimo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Cuadriculado superior
                  Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/imagenes/cuadriculado.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Contenido principal
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF26639C),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Título compacto
                              Container(
                                padding: const EdgeInsets.all(15),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFD9400),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    esAnonimo
                                        ? 'CLIENTE ANÓNIMO'
                                        : 'CLIENTE REGISTRADO',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),

                              // Formulario expandido
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 25,
                                  ),
                                  child: Column(
                                    children: [
                                      // Botón Escanear DNI (solo para clientes registrados)
                                      if (!esAnonimo) ...[
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons.qr_code_scanner,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'ESCANEAR DNI',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => ScannerPage(
                                                        onScan: (valor) {
                                                          procesarDatosDesdeQR(
                                                            valor,
                                                          );
                                                        },
                                                      ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFFD9400,
                                              ),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              elevation: 3,
                                            ),
                                          ),
                                        ),
                                      ],

                                      // Campos de formulario expandidos
                                      Expanded(
                                        child: Column(
                                          children: [
                                            // Campo de Nombre
                                            Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: TextFormField(
                                                  controller: nombreController,
                                                  decoration: InputDecoration(
                                                    hintText: 'Nombre',
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 15,
                                                          vertical: 8,
                                                        ),
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                  ),
                                                  validator:
                                                      (v) =>
                                                          v!.isEmpty
                                                              ? 'Campo obligatorio'
                                                              : null,
                                                ),
                                              ),
                                            ),

                                            // Campos solo para clientes registrados
                                            if (!esAnonimo) ...[
                                              // Campo de Apellido
                                              Expanded(
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 6,
                                                  ),
                                                  child: TextFormField(
                                                    controller:
                                                        apellidoController,
                                                    decoration: InputDecoration(
                                                      hintText: 'Apellido',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 15,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                    ),
                                                    validator:
                                                        (v) =>
                                                            v!.isEmpty
                                                                ? 'Campo obligatorio'
                                                                : null,
                                                  ),
                                                ),
                                              ),

                                              // Campo de DNI
                                              Expanded(
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 6,
                                                  ),
                                                  child: TextFormField(
                                                    controller: dniController,
                                                    decoration: InputDecoration(
                                                      hintText: 'DNI',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 15,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                    ),
                                                    validator:
                                                        (v) =>
                                                            v!.isEmpty
                                                                ? 'Campo obligatorio'
                                                                : null,
                                                  ),
                                                ),
                                              ),
                                            ],

                                            // Campo de Email
                                            Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: TextFormField(
                                                  controller: emailController,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Correo electrónico',
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 15,
                                                          vertical: 8,
                                                        ),
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                  ),
                                                  validator: (v) {
                                                    if (v == null || v.isEmpty)
                                                      return 'Campo obligatorio';
                                                    final regex = RegExp(
                                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                                    );
                                                    if (!regex.hasMatch(v))
                                                      return 'Correo no válido';
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ),

                                            // Campo de Contraseña
                                            Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: TextFormField(
                                                  controller:
                                                      passwordController,
                                                  obscureText: true,
                                                  decoration: InputDecoration(
                                                    hintText: 'Contraseña',
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 15,
                                                          vertical: 8,
                                                        ),
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                  ),
                                                  validator:
                                                      (v) =>
                                                          v != null &&
                                                                  v.length < 6
                                                              ? 'Mínimo 6 caracteres'
                                                              : null,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: TextFormField(
                                                controller: confirmPasswordController,
                                                obscureText: true,
                                                decoration: InputDecoration(
                                                  hintText: 'Confirmar contraseña',
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 15,
                                                    vertical: 8,
                                                  ),
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                ),
                                                validator: (v) {
                                                  if (v == null || v.isEmpty) {
                                                    return 'Este campo es obligatorio';
                                                  }
                                                  if (v != passwordController.text) {
                                                    return 'Las contraseñas no coinciden';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ),


                                            // Sección de imagen compacta
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // Vista previa de imagen más pequeña
                                                  Container(
                                                    width: 60,
                                                    height: 60,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child:
                                                        imagen != null
                                                            ? ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                              child: Image.file(
                                                                imagen!,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              ),
                                                            )
                                                            : Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                                border: Border.all(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                        0.5,
                                                                      ),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: const Icon(
                                                                Icons.person,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                size: 30,
                                                              ),
                                                            ),
                                                  ),
                                                  const SizedBox(width: 15),
                                                  // Botón Tomar Foto más compacto
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: pickImage,
                                                      icon: const Icon(
                                                        Icons.camera_alt,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                        'Tomar Foto',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFFD9400,
                                                            ),
                                                        foregroundColor:
                                                            Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 8,
                                                            ),
                                                        elevation: 3,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Botón Registrar
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 15,
                                          top: 10,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: registrar,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(
                                              0xFF26639C,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            elevation: 3,
                                          ),
                                          child: const Text(
                                            "REGISTRAR",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Cuadriculado inferior
                  Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/imagenes/cuadriculado.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

// 📷 Pantalla de escaneo QR
class ScannerPage extends StatefulWidget {
  final Function(String) onScan;

  const ScannerPage({super.key, required this.onScan});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _yaDetectado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear DNI")),
      body: MobileScanner(
        onDetect: (capture) {
          if (_yaDetectado) return;

          final List<Barcode> barcodes = capture.barcodes;

          if (barcodes.isNotEmpty) {
            final String? value = barcodes.first.rawValue;

            if (value != null && value.isNotEmpty) {
              _yaDetectado = true;
              widget.onScan(value);
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }
}

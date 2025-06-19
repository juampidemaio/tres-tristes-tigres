import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../login.dart';

class RegistroDueno extends StatefulWidget {
  final String perfil; // 'dueno' o 'supervisor'
  const RegistroDueno({super.key, required this.perfil});

  @override
  State<RegistroDueno> createState() => _RegistroDuenoState();
}

class _RegistroDuenoState extends State<RegistroDueno> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final dniController = TextEditingController();
  final cuilController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  File? imagen;
  bool isLoading = false;

  String? perfilActual;
  bool cargandoPerfil = true;

  @override
  void initState() {
    super.initState();
    validarPermisos();
  }

  Future<void> validarPermisos() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response =
        await supabase
            .from('usuarios')
            .select('perfil')
            .eq('id', user.id)
            .maybeSingle();

    perfilActual = response?['perfil'];
    setState(() => cargandoPerfil = false);
  }

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

    final url = supabase.storage.from('fotos').getPublicUrl(ruta);
    return url;
  }

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (imagen == null) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (_) => const AlertDialog(
                title: Text('❌ Faltan datos'),
                content: Text('Debés tomar una foto antes de registrarte.'),
              ),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = res.user;
      if (user == null) throw 'No se pudo registrar el usuario.';

      final fotoUrl = await subirImagen(user.id);

      await supabase.from('usuarios').insert({
        'id': user.id,
        'email': emailController.text.trim(),
        'nombre': nombreController.text.trim(),
        'apellido': apellidoController.text.trim(),
        'dni': dniController.text.trim(),
        'cuil': cuilController.text.trim(),
        'perfil': widget.perfil,
        'foto_url': fotoUrl,
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                content: const Text(
                  '✅ Registro exitoso. Revisa tu correo para confirmar.',
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
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('❌ Error'),
                content: Text(e.toString()),
              ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void procesarDatosDesdeQR(String data) {
    print('Datos escaneados del QR: $data');
    final partes = data.split('@');
    if (partes.length >= 6) {
      final apellido = partes[1];
      final nombre = partes[2];
      final sexo = partes[3];
      final dniRaw = partes[4];
      final dniLimpio = RegExp(r'\d+').stringMatch(dniRaw) ?? '';

      setState(() {
        apellidoController.text = apellido;
        nombreController.text = nombre;
        dniController.text = dniLimpio;
        cuilController.text = calcularCUIL(dniLimpio, sexo);
      });
    } else {
      showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text('QR inválido'),
              content: Text('No se pudo leer el DNI y CUIL correctamente.'),
            ),
      );
    }
  }

  String calcularCUIL(String dni, String sexo) {
    String prefijo = (sexo == 'M') ? '20' : '27';
    String base = prefijo + dni;
    List<int> pesos = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];

    int suma = 0;
    for (int i = 0; i < 10; i++) {
      suma += int.parse(base[i]) * pesos[i];
    }

    int resto = suma % 11;
    int verificador;
    if (resto == 0) {
      verificador = 0;
    } else if (resto == 1) {
      prefijo = (sexo == 'M') ? '23' : '23';
      verificador = (sexo == 'M') ? 9 : 4;
    } else {
      verificador = 11 - resto;
    }

    return '$prefijo$dni$verificador';
  }

  @override
  Widget build(BuildContext context) {
    if (cargandoPerfil) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (perfilActual != 'dueño' && perfilActual != 'supervisor') {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso denegado')),
        body: const Center(
          child: Text('No tenés permisos para acceder a esta sección.'),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
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
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Parte superior cuadriculada
                    Container(
                      height: 30,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/imagenes/cuadriculado.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Padding(
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
                              // Título con fondo naranja
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
                                    widget.perfil == 'dueño'
                                        ? 'DUEÑO'
                                        : widget.perfil == 'supervisor'
                                        ? 'SUPERVISOR'
                                        : '',
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

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: [
                                    // Botón Escanear DNI
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 12),
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          elevation: 3,
                                        ),
                                      ),
                                    ),

                                    // Campos de texto
                                    ...[
                                      {
                                        'controller': nombreController,
                                        'hint': 'Nombre',
                                        'validator':
                                            (v) =>
                                                v!.isEmpty
                                                    ? 'Campo obligatorio'
                                                    : null,
                                      },
                                      {
                                        'controller': apellidoController,
                                        'hint': 'Apellido',
                                        'validator':
                                            (v) =>
                                                v!.isEmpty
                                                    ? 'Campo obligatorio'
                                                    : null,
                                      },
                                      {
                                        'controller': dniController,
                                        'hint': 'DNI',
                                        'validator':
                                            (v) =>
                                                v!.isEmpty
                                                    ? 'Campo obligatorio'
                                                    : null,
                                      },
                                      {
                                        'controller': cuilController,
                                        'hint': 'CUIL',
                                        'validator':
                                            (v) =>
                                                v!.isEmpty
                                                    ? 'Campo obligatorio'
                                                    : null,
                                      },
                                    ].map<Widget>((field) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ), // ← más separación aquí
                                        child: TextFormField(
                                          controller:
                                              field['controller']
                                                  as TextEditingController,
                                          decoration: InputDecoration(
                                            hintText: field['hint'] as String,
                                            hintStyle: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              borderSide: BorderSide.none,
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
                                              field['validator']
                                                  as String? Function(String?)?,
                                        ),
                                      );
                                    }).toList(),

                                    // Campo Correo electrónico
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: TextFormField(
                                        controller: emailController,
                                        decoration: InputDecoration(
                                          hintText: 'Correo electrónico',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide.none,
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

                                    // Campo Contraseña
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: TextFormField(
                                        controller: passwordController,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          hintText: 'Contraseña',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide.none,
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
                                                v != null && v.length < 6
                                                    ? 'Mínimo 6 caracteres'
                                                    : null,
                                      ),
                                    ),

                                    // Campo Confirmar Contraseña
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide.none,
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
                                    const SizedBox(height: 10),

                                    // Imagen compacta con botón integrado
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Vista previa de la imagen (o ícono por defecto)
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                    : Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(0.5),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.person,
                                                        color: Colors.white,
                                                        size: 30,
                                                      ),
                                                    ),
                                          ),
                                          const SizedBox(width: 15),
                                          // Botón compacto para tomar foto
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: pickImage,
                                              icon: const Icon(
                                                Icons.camera_alt,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Tomar Foto',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFFD9400,
                                                ),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
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

                                    // Botón Registrar
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(
                                        bottom: 15,
                                        top: 10,
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: registrar,
                                        icon: const Icon(Icons.save),
                                        label: const Text(
                                          "REGISTRAR",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Color(0xFF26639C),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
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
              ),
    );
  }
}

// 📷 Pantalla de escaneo QR (abajo del todo)
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

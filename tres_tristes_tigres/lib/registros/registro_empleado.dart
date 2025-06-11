import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../login.dart';

class RegistroEmpleado extends StatefulWidget {
  const RegistroEmpleado({super.key});

  @override
  State<RegistroEmpleado> createState() => _RegistroEmpleadoState();
}

class _RegistroEmpleadoState extends State<RegistroEmpleado> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final dniController = TextEditingController();
  final cuilController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? tipoSeleccionado;
  File? imagen;
  bool isLoading = false;

  final List<String> tipos = ['mozo', 'cocinero', 'bartender', 'maitre'];

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

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (tipoSeleccionado == null) {
      mostrarError('Seleccioná un tipo de empleado');
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Crear en auth
      final res = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = res.user;
      if (user == null) throw 'No se pudo registrar el usuario.';

      // 2. Subir foto
      final fotoUrl = await subirImagen(user.id);

      // 3. Insertar en `usuarios`
      await supabase.from('usuarios').insert({
        'id': user.id,
        'email': emailController.text.trim(),
        'nombre': nombreController.text.trim(),
        'apellido': apellidoController.text.trim(),
        'dni': dniController.text.trim(),
        'cuil': cuilController.text.trim(),
        'perfil': 'empleado',
        'tipo_empleado': tipoSeleccionado,
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
      mostrarError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder:
          (_) =>
              AlertDialog(title: const Text('❌ Error'), content: Text(mensaje)),
    );
  }

  //Codigo a adaptar
  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Registro de EMPLEADO',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                ),
                TextFormField(
                  controller: apellidoController,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                  validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                ),
                TextFormField(
                  controller: dniController,
                  decoration: const InputDecoration(labelText: 'DNI'),
                  validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                ),
                TextFormField(
                  controller: cuilController,
                  decoration: const InputDecoration(labelText: 'CUIL'),
                  validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                ),
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  hint: const Text('Tipo de empleado'),
                  items:
                      tipos
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo.toUpperCase()),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => tipoSeleccionado = value),
                  validator: (v) => v == null ? 'Seleccioná un tipo' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obligatorio';
                    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!regex.hasMatch(v)) return 'Correo no válido';
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator:
                      (v) =>
                          v != null && v.length < 6
                              ? 'Mínimo 6 caracteres'
                              : null,
                ),
                const SizedBox(height: 10),
                imagen != null
                    ? Image.file(imagen!, height: 100)
                    : const Text('No se ha seleccionado imagen'),
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar Foto'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: registrar,
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
        );
  }
}

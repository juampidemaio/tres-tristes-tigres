import 'package:flutter/material.dart';
import 'registros/registro_dueno.dart';
import 'registros/registro_empleado.dart';
import 'registros/registro_cliente.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  String? perfilSeleccionado;

  void seleccionarPerfil(String perfil) {
    setState(() {
      perfilSeleccionado = perfil;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE7F6),
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        backgroundColor: const Color(0xFF5E35B1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: perfilSeleccionado == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Qué tipo de usuario sos?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildRolButton('dueño', Icons.star),
                      _buildRolButton('supervisor', Icons.verified_user),
                      _buildRolButton('empleado', Icons.work),
                      _buildRolButton('cliente_registrado', Icons.person),
                      _buildRolButton('cliente_anonimo', Icons.emoji_emotions),
                    ],
                  ),
                ],
              )
            : _mostrarFormularioPorRol(perfilSeleccionado!),
      ),
    );
  }

  Widget _buildRolButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () => seleccionarPerfil(label),
      icon: Icon(icon),
      label: Text(label.toUpperCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7E57C2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _mostrarFormularioPorRol(String perfil) {
    switch (perfil) {
      case 'dueño':
      case 'supervisor':
        return RegistroDueno(perfil: perfil);
      case 'empleado':
        return const RegistroEmpleado();
      case 'cliente_registrado':
      case 'cliente_anonimo':
        return RegistroCliente(perfil: perfil);
      default:
        return const Text('Perfil no soportado');
    }
  }
}

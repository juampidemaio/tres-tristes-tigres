import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GestionClientesPage extends StatefulWidget {
  final String perfilActual;

  const GestionClientesPage({super.key, required this.perfilActual});

  @override
  State<GestionClientesPage> createState() => _GestionClientesPageState();
}

class _GestionClientesPageState extends State<GestionClientesPage> {
  String filtro = 'pendiente';
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    final query = supabase
        .from('usuarios')
        .select()
        .eq('perfil', 'cliente_registrado')
        .eq('aprobado', filtro);
    final data = await query;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> enviarCorreo({
    required String nombre,
    required String email,
    required String estado,
  }) async {
    const serviceId = 'service_09ti1jw';
    const templateId = 'template_qnschgh';
    const userId = 'wdMRU-ZjinXIfuOD7';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'to_name': nombre,
          'to_email': email,
          'estado': estado,
        },
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Correo enviado con éxito');
    } else {
      print('❌ Error al enviar correo: ${response.body}');
    }
  }

  Future<void> actualizarAprobacion({
    required String id,
    required String nuevoEstado,
    required String nombre,
    required String email,
  }) async {
    await supabase.from('usuarios').update({'aprobado': nuevoEstado}).eq('id', id);
    await enviarCorreo(nombre: nombre, email: email, estado: nuevoEstado);
  }

  Future<void> confirmarCambio({
    required String id,
    required String nuevoEstado,
    required String nombre,
    required String email,
  }) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmación'),
        content: Text(
          nuevoEstado == 'aceptado'
              ? '¿Está seguro que desea aceptar este cliente?'
              : '¿Está seguro que desea rechazar este cliente?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Confirmar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      await actualizarAprobacion(
        id: id,
        nuevoEstado: nuevoEstado,
        nombre: nombre,
        email: email,
      );
      setState(() {});
    }
  }

  bool get puedeAprobar =>
      widget.perfilActual == 'dueño' || widget.perfilActual == 'supervisor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EB), // Fondo claro
      appBar: AppBar(
        backgroundColor: const Color(0xFF26639D), // Azul profundo
        title: const Text('Gestión de Clientes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ToggleButtons(
            borderColor: const Color(0xFF98A6C2),
            selectedColor: Colors.white,
            fillColor: const Color(0xFF0E6BB7), // Azul medio
            color: const Color(0xFF26639D), // Texto de botones no seleccionados
            borderRadius: BorderRadius.circular(10),
            isSelected: [
              filtro == 'pendiente',
              filtro == 'aceptado',
              filtro == 'rechazado',
            ],
            onPressed: (index) {
              setState(() {
                filtro = ['pendiente', 'aceptado', 'rechazado'][index];
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text('Pendientes'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text('Aceptados'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text('Rechazados'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: obtenerClientes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clientes = snapshot.data!;
                if (clientes.isEmpty) {
                  return const Center(child: Text('No hay clientes.'));
                }

                return ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    final nombre = cliente['nombre'] ?? 'Sin nombre';
                    final email = cliente['email'] ?? 'Sin email';
                    final id = cliente['id'];
                    final aprobado = cliente['aprobado'] ?? 'pendiente';

                    return Card(
                      color: const Color(0xFF98A6C2), // Fondo de card gris azulado
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '$email\nEstado: $aprobado',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        isThreeLine: true,
                        trailing: (filtro == 'pendiente' && puedeAprobar)
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0E6BB7), // Azul acción
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(48, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(Icons.check),
                                    onPressed: () => confirmarCambio(
                                      id: id,
                                      nuevoEstado: 'aceptado',
                                      nombre: nombre,
                                      email: email,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF9100), // Naranja acción
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(48, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(Icons.close),
                                    onPressed: () => confirmarCambio(
                                      id: id,
                                      nuevoEstado: 'rechazado',
                                      nombre: nombre,
                                      email: email,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ClientesMaitrePage extends StatefulWidget {
  @override
  _ClientesMaitrePageState createState() => _ClientesMaitrePageState();
}

class _ClientesMaitrePageState extends State<ClientesMaitrePage> {
  final supabase = Supabase.instance.client;
  String estadoSeleccionado = 'esperando';
  List<dynamic> clientes = [];

  final backgroundColor = const Color(0xFF0E6BB7);
  final textColor = const Color(0xFFF7F4EB);
  final chartColors = [
    const Color(0xFFFF9100), // naranja
    const Color(0xFF26639D), // azul intermedio
    const Color(0xFF98A6C2), // gris claro
    const Color(0xFFF7F4EB), // casi blanco
  ];

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  Future<void> cargarClientes() async {
    final response = await supabase
        .from('ingresos_local')
        .select()
        .eq('estado', estadoSeleccionado)
        .order('fecha_hora', ascending: true);

    setState(() {
      clientes = response;
    });
  }

  void cambiarEstado(String nuevoEstado) {
    setState(() {
      estadoSeleccionado = nuevoEstado;
    });
    cargarClientes();
  }

  void mostrarDialogoAsignarMesa(Map cliente) async {
    final estado = cliente['estado'];
    final numeroMesa = cliente['mesa_numero'];

    if (estado == 'asignado' || estado == 'sentado') {
      String mensaje = estado == 'asignado'
          ? 'El cliente ya fue asignado a la mesa $numeroMesa.'
          : 'El cliente está ocupado en la mesa $numeroMesa.';

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: chartColors[1],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Información', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Text(mensaje, style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: TextStyle(color: chartColors[0], fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final mesasDisponibles = await supabase
        .from('mesas')
        .select()
        .eq('estadoMesa', 'libre');

    if (mesasDisponibles.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: chartColors[1],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Sin mesas disponibles', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Text(
            'Todas las mesas están ocupadas por el momento. Intenta nuevamente en unos minutos.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Aceptar', style: TextStyle(color: chartColors[0], fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    int? mesaSeleccionada;

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Asignar mesa disponible',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    isExpanded: true,
                    dropdownColor: chartColors[1],
                    style: TextStyle(color: textColor),
                    value: mesaSeleccionada,
                    hint: Text('Seleccionar mesa', style: TextStyle(color: textColor)),
                    items: mesasDisponibles.map<DropdownMenuItem<int>>((mesa) {
                      final int? numeroMesa = int.tryParse(mesa['numero'].toString());
                      return DropdownMenuItem<int>(
                        value: numeroMesa,
                        child: Text('Mesa ${mesa['numero']}', style: TextStyle(color: textColor)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        mesaSeleccionada = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: chartColors[0],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: mesaSeleccionada == null
                        ? null
                        : () => asignarMesa(cliente, mesaSeleccionada!),
                    child: const Text('Asignar Mesa'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> asignarMesa(Map cliente, int numeroMesa) async {
    try {
      final response = await supabase
          .from('usuarios')
          .select()
          .eq('id', cliente['usuario_id'])
          .single();

      if (response == null) throw Exception('Usuario no encontrado');

      await supabase
          .from('ingresos_local')
          .update({
            'estado': 'asignado',
            'mesa_numero': numeroMesa,
          })
          .eq('usuario_id', response['id']);

      await supabase
          .from('mesas')
          .update({
            'usuario': response['email'],
            'estadoMesa': "ocupada",
          })
          .eq('numero', numeroMesa);

      Navigator.pop(context);
      cargarClientes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesa asignada correctamente')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar mesa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Clientes en $estadoSeleccionado', style: TextStyle(color: textColor)),
        backgroundColor: chartColors[1],
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          Container(
            color: chartColors[1],
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var estado in ['esperando', 'asignado', 'sentado'])
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: estadoSeleccionado == estado ? chartColors[0] : chartColors[2],
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onPressed: () => cambiarEstado(estado),
                    child: Text(estado[0].toUpperCase() + estado.substring(1)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return Card(
                  color: chartColors[0],
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.person, color: chartColors[1]),
                    title: Text(
                      cliente['nombre'],
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingresó: ${DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.parse(cliente['fecha_hora']))}',
                          style: TextStyle(color: textColor.withOpacity(0.9)),
                        ),
                        if (cliente['estado'] == 'asignado' || cliente['estado'] == 'sentado')
                          Text(
                            'Mesa: ${cliente['mesa_numero']}',
                            style: TextStyle(color: textColor.withOpacity(0.95), fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    trailing: Text(
                      cliente['estado'],
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                    onTap: () => mostrarDialogoAsignarMesa(cliente),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

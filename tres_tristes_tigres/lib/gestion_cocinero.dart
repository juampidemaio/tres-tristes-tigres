import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class GestionCocineroPage extends StatefulWidget {
  @override
  _GestionCocineroPageState createState() => _GestionCocineroPageState();
}

class _GestionCocineroPageState extends State<GestionCocineroPage> {
  List<dynamic> pedidos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPedidos();
  }

  Future<void> fetchPedidos() async {
    final response = await Supabase.instance.client
        .from('pedidos')
        .select()
        .eq('estado', 'enProceso'); // Solo pedidos en preparación
    setState(() {
      pedidos = response;
      isLoading = false;
    });
  }

  Future<Map<String, dynamic>> obtenerProductoPorId(String idProducto) async {
    final response = await Supabase.instance.client
        .from('productos')
        .select()
        .eq('id', idProducto)
        .single();

    return response;
  }

  Future<List<Map<String, dynamic>>> filtrarProductosCocina(Map pedido) async {
    final pedidoMap = Map<String, dynamic>.from(pedido['pedido']);
    List<Map<String, dynamic>> productosCocina = [];

    for (final entry in pedidoMap.entries) {
      final idProducto = entry.key;
      final cantidad = entry.value;

      final producto = await obtenerProductoPorId(idProducto);

    if (producto['tipo'] == 'comida' || producto['tipo'] == 'postre') {
        productosCocina.add({
          'producto': producto,
          'cantidad': cantidad,
          'pedidoId': pedido['id'],
        });
      }
    }

    return productosCocina;
  }

  Widget buildProductoTile(Map productoInfo) {
    final producto = productoInfo['producto'];
    final cantidad = productoInfo['cantidad'];

    return ListTile(
      title: Text(producto['nombre'] ?? 'Producto'),
      subtitle: Text("Cantidad: $cantidad"),
      trailing: Icon(Icons.kitchen),
    );
  }

  Future<void> verificarYActualizarEstadoGeneral(int pedidoId) async {
  final client = Supabase.instance.client;

  final pedido = await client
      .from('pedidos')
      .select('comida_realizada, postre_realizado, bebida_realizada, estado')
      .eq('id', pedidoId)
      .maybeSingle();

  if (pedido == null) return;

  final todosListos = [pedido['comida_realizada'], pedido['postre_realizado'], pedido['bebida_realizada']]
      .where((v) => v != null)
      .every((v) => v == true);

  if (todosListos && pedido['estado'] == 'enProceso') {
    await client
        .from('pedidos')
        .update({'estado': 'paraEnviar'})
        .eq('id', pedidoId);
  }
}

Future<void> actualizarCamposPedido(int pedidoId, Map<String, dynamic> campos) async {
  await Supabase.instance.client
      .from('pedidos')
      .update(campos)
      .eq('id', pedidoId);
  fetchPedidos(); // refresca la vista
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestión Cocina')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Widget>>(
              future: _generarListaCocina(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return Center(child: Text('No hay pedidos de cocina.'));
                return ListView(children: snapshot.data!);
              },
            ),
    );
  }

//de esta manera se lo envio a todos los mozos
Future<void> enviarNotificacionMozo(int pedidoId, String parte) async {
  final client = Supabase.instance.client;

  final usuarios = await client
  .from('usuarios')
  .select('id')
  .eq('perfil', 'empleado')
  .eq('tipo_empleado', 'mozo');
  
 final userIds = usuarios.map((u) => u['id']).toList();

  final tokens = await client
    .from('user_tokens')
    .select('fcm_token, usuario_id')
    .inFilter('usuario_id', userIds);

  final url = Uri.parse('https://push-notif-api-iz1o.onrender.com/send-notification');

  for (final row in tokens) {
    final token = row['fcm_token'];
    if (token != null) {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': 'Parte de pedido lista',
          'body': 'La $parte del pedido #$pedidoId está lista.',
        }),
      );
    }
  }
}

Future<List<Widget>> _generarListaCocina() async {
  List<Widget> lista = [];

  for (var pedido in pedidos) {
    final productosCocina = await filtrarProductosCocina(pedido);
    if (productosCocina.isEmpty) continue;

    lista.add(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Pedido #${pedido['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );

    // Mostrar productos
    lista.addAll(productosCocina.map(buildProductoTile));

    // Verificar qué partes ya están realizadas
    final comidaRealizada = pedido['comida_realizada'] == true;
    final postreRealizado = pedido['postre_realizado'] == true;

    // Extraer los productos del pedido para ver qué tipos hay
    final pedidoMap = Map<String, dynamic>.from(pedido['pedido']);
    bool tieneComida = false;
    bool tienePostre = false;

    for (final entry in pedidoMap.entries) {
      final producto = await obtenerProductoPorId(entry.key);
      if (producto['tipo'] == 'comida') tieneComida = true;
      if (producto['tipo'] == 'postre') tienePostre = true;
    }

    // Solo mostrar botón si hay partes pendientes
   if (tieneComida && !comidaRealizada) {
  lista.add(
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("¿Confirmar comida?"),
              content: Text("¿Estás seguro de que la comida del pedido #${pedido['id']} está lista?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancelar")),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Confirmar")),
              ],
            ),
          );
          if (confirmar == true) {
            await actualizarCamposPedido(pedido['id'], {'comida_realizada': true});
            await verificarYActualizarEstadoGeneral(pedido['id']);
            await enviarNotificacionMozo(pedido['id'], 'comida');
          }
        },
        icon: Icon(Icons.restaurant),
        label: Text("Confirmar comida lista"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );
}

if (tienePostre && !postreRealizado) {
  lista.add(
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("¿Confirmar postre?"),
              content: Text("¿Estás seguro de que el postre del pedido #${pedido['id']} está listo?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancelar")),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Confirmar")),
              ],
            ),
          );
          if (confirmar == true) {
          await actualizarCamposPedido(pedido['id'], {'postre_realizado': true});
          await verificarYActualizarEstadoGeneral(pedido['id']);
          await enviarNotificacionMozo(pedido['id'], 'postre');
        }

        },
        icon: Icon(Icons.icecream),
        label: Text("Confirmar postre listo"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );
    } else {
      lista.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
          child: Text(
            "✅ Parte de cocina ya confirmada",
            style: TextStyle(color:const Color(0xFFFF9100), fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    lista.add(Divider());
  }

  return lista;
}


}

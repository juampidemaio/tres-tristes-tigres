import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class GestionBartenderPage extends StatefulWidget {
  @override
  _GestionBartenderPageState createState() => _GestionBartenderPageState();
}

class _GestionBartenderPageState extends State<GestionBartenderPage> {
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
        .eq('estado', 'enProceso');
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

  Future<List<Map<String, dynamic>>> filtrarProductosBar(Map pedido) async {
    final pedidoMap = Map<String, dynamic>.from(pedido['pedido']);
    List<Map<String, dynamic>> productosBar = [];

    for (final entry in pedidoMap.entries) {
      final idProducto = entry.key;
      final cantidad = entry.value;

      final producto = await obtenerProductoPorId(idProducto);

      if (producto['tipo'] == 'bebida') {
        productosBar.add({
          'producto': producto,
          'cantidad': cantidad,
          'pedidoId': pedido['id'],
        });
      }
    }

    return productosBar;
  }

  Future<void> actualizarCamposPedido(int pedidoId, Map<String, dynamic> campos) async {
    await Supabase.instance.client
        .from('pedidos')
        .update(campos)
        .eq('id', pedidoId);
    fetchPedidos();
  }

  Future<void> verificarYActualizarEstadoGeneral(int pedidoId) async {
    final pedido = await Supabase.instance.client
        .from('pedidos')
        .select('comida_realizada, postre_realizado, bebida_realizada, estado')
        .eq('id', pedidoId)
        .maybeSingle();

    if (pedido == null) return;

    final todosListos = [pedido['comida_realizada'], pedido['postre_realizado'], pedido['bebida_realizada']]
        .where((v) => v != null)
        .every((v) => v == true);

    if (todosListos && pedido['estado'] == 'enProceso') {
      await Supabase.instance.client
          .from('pedidos')
          .update({'estado': 'paraEnviar'})
          .eq('id', pedidoId);
    }
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

  Widget buildProductoTile(Map productoInfo) {
    final producto = productoInfo['producto'];
    final cantidad = productoInfo['cantidad'];

    return ListTile(
      title: Text(producto['nombre'] ?? 'Producto'),
      subtitle: Text("Cantidad: $cantidad"),
      trailing: Icon(Icons.local_bar),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestión Bar')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Widget>>(
              future: _generarListaBar(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return Center(child: Text('No hay pedidos de bar.'));
                return ListView(children: snapshot.data!);
              },
            ),
    );
  }

  Future<List<Widget>> _generarListaBar() async {
    List<Widget> lista = [];

    for (var pedido in pedidos) {
      final productosBar = await filtrarProductosBar(pedido);
      if (productosBar.isEmpty) continue;

      lista.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Pedido #${pedido['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      lista.addAll(productosBar.map(buildProductoTile));

      final bebidaRealizada = pedido['bebida_realizada'] == true;
      final pedidoMap = Map<String, dynamic>.from(pedido['pedido']);
      bool tieneBebida = false;

      for (final entry in pedidoMap.entries) {
        final producto = await obtenerProductoPorId(entry.key);
        if (producto['tipo'] == 'bebida') tieneBebida = true;
      }

      if (tieneBebida && !bebidaRealizada) {
        lista.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmacion = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("¿Confirmar pedido?"),
                    content: Text("¿Estás seguro de que el pedido #${pedido['id']} está listo para enviar?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text("Confirmar"),
                      ),
                    ],
                  ),
                );

                if (confirmacion == true) {
                  await actualizarCamposPedido(pedido['id'], {'bebida_realizada': true});
                  await verificarYActualizarEstadoGeneral(pedido['id']);
                  await enviarNotificacionMozo(pedido['id'], 'bebida');
                }
              },
              icon: Icon(Icons.check_circle_outline),
              label: Text("Marcar como listo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100),
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
              "✅ Parte de bar ya confirmada",
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

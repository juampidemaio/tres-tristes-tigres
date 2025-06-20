import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GestionMozoPage extends StatefulWidget {
  @override
  _GestionMozoPageState createState() => _GestionMozoPageState();
}

class _GestionMozoPageState extends State<GestionMozoPage> {
  final backgroundColor = const Color(0xFFF7F4EB);
  final textColor = const Color(0xFF26639D);
  final cardColor = const Color(0xFF98A6C2);

  List<dynamic> pedidos = [];
  bool isLoading = true;

  final estados = ['pendiente', 'enProceso', 'paraEnviar', 'entregado'];
  String estadoSeleccionado = 'pendiente';

  @override
  void initState() {
    super.initState();
    fetchPedidos();
  }

  Future<void> fetchPedidos() async {
  final client = Supabase.instance.client;

 final pedidosData = await client
    .from('pedidos')
    .select()
    .order('id', ascending: false);

  // Para cada pedido, buscamos la mesa del cliente
  for (var pedido in pedidosData) {
  final clienteEmail = pedido['cliente'];

  final mesa = await client
      .from('mesas')
      .select('numero')
      .eq('usuario', clienteEmail)
      .maybeSingle();

  print('Resultado mesa: $mesa');

  pedido['mesa'] = mesa != null ? mesa['numero'] : 'Sin asignar';
}


  setState(() {
    pedidos = pedidosData;
    isLoading = false;
  });
}




Future<void> actualizarEstado(int idPedido, String nuevoEstado) async {
  final client = Supabase.instance.client;

  // 1. Actualizamos el estado del pedido
  await client
      .from('pedidos')
      .update({'estado': nuevoEstado})
      .eq('id', idPedido);

  

  // 2. Obtenemos el pedido completo
  final pedidoData = await client
      .from('pedidos')
      .select('cliente, pedido')
      .eq('id', idPedido)
      .single();

  final pedidoJson = pedidoData['pedido'] as Map<String, dynamic>;
  final productoIds = pedidoJson.keys.map(int.parse).toList();

  // 3. Buscamos tipo de producto
  final productos = await client
      .from('productos')
      .select('id, tipo')
      .inFilter('id', productoIds);


  final tieneComida = productos.any((p) => p['tipo'] == 'comida');
  final tienePostre = productos.any((p) => p['tipo'] == 'postre');
  final tieneBebida = productos.any((p) => p['tipo'] == 'bebida');

    final updateData = <String, dynamic>{};
  if (tieneComida) updateData['comida_realizada'] = false;
  if (tienePostre) updateData['postre_realizado'] = false;
  if (tieneBebida) updateData['bebida_realizada'] = false;
  
  if (updateData.isNotEmpty) {
    await client.from('pedidos').update(updateData).eq('id', idPedido);
  }

  // 4. Buscamos empleados a notificar
  List<String> perfiles = [];
  if (tieneComida) perfiles.add('cocinero');
  if (tienePostre) perfiles.add('cocinero');
  if (tieneBebida) perfiles.add('bartender');

  final usuarios = await client
  .from('usuarios')
  .select('id')
  .eq('perfil', 'empleado')
  .inFilter('tipo_empleado', perfiles);

  final userIds = usuarios.map((u) => u['id']).toList();

  final tokens = await client
    .from('user_tokens')
    .select('fcm_token, usuario_id')
    .inFilter('usuario_id', userIds);


  final url = Uri.parse('https://push-notif-api-iz1o.onrender.com/send-notification');

  final tokensUnicos = <String>{};
  for (final row in tokens) {
    final token = row['fcm_token'];
    if (token != null && tokensUnicos.add(token)) {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': 'Nuevo pedido entrante',
          'body': 'Hay un nuevo pedido confirmado por el mozo.',
        }),
      );
    }
}


  // 5. Refrescar lista
  fetchPedidos();
}




 Widget buildPedidoTile(Map pedido) {
  return Card(
    color: cardColor,
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      title: Text("Cliente: ${pedido['cliente']}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mesa: ${pedido['mesa']}", style: const TextStyle(color: Colors.white)),
          Text("Importe: \$${pedido['importe']}", style: const TextStyle(color: Colors.white)),
          Text("Tiempo: ${pedido['tiempoPromedio']} min", style: const TextStyle(color: Colors.white)),
          Text("Estado: ${pedido['estado']}", style: const TextStyle(color: Colors.white70)),
          if (pedido['estado'] == 'enProceso') ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  pedido['comida_realizada'] == true ? Icons.check_circle : Icons.hourglass_bottom,
                  color: pedido['comida_realizada'] == true ? Colors.green : Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 4),
                Text("Comida", style: TextStyle(color: Colors.white)),
                
                SizedBox(width: 12),
                Icon(
                  pedido['postre_realizado'] == true ? Icons.check_circle : Icons.hourglass_bottom,
                  color: pedido['postre_realizado'] == true ? Colors.green : Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 4),
                Text("Postre", style: TextStyle(color: Colors.white)),
                
                SizedBox(width: 12),
                Icon(
                  pedido['bebida_realizada'] == true ? Icons.check_circle : Icons.hourglass_bottom,
                  color: pedido['bebida_realizada'] == true ? Colors.green : Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 4),
                Text("Bebida", style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ],
      ),
      trailing: pedido['estado'] == 'pendiente'
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100),
                foregroundColor: Colors.white,
              ),
              onPressed: () => actualizarEstado(pedido['id'], 'enProceso'),
              child: const Text("Confirmar"),
            )
          : pedido['estado'] == 'paraEnviar'
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("¿Confirmar pedido?"),
                      content: const Text("¿Estás seguro que el pedido está para enviar?"),
                      actions: [
                        TextButton(
                          child: const Text("Cancelar"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text("Confirmar"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            actualizarEstado(pedido['id'], 'entregado');
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text("Entregar"),
            )
          : null,
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    final pedidosFiltrados =
        pedidos.where((p) => p['estado'] == estadoSeleccionado).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: textColor,
        title: const Text("Gestión de Pedidos", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),
                ToggleButtons(
                  borderColor: cardColor,
                  selectedColor: Colors.white,
                  fillColor: textColor,
                  color: textColor,
                  borderRadius: BorderRadius.circular(12),
                  isSelected: estados.map((e) => e == estadoSeleccionado).toList(),
                  onPressed: (index) {
                    setState(() {
                      estadoSeleccionado = estados[index];
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                      child: Text('Pendiente'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                      child: Text('En Proceso'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                      child: Text('Para Enviar'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                      child: Text('Entregado'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchPedidos,
                    child: pedidosFiltrados.isEmpty
                        ? const Center(child: Text("No hay pedidos en este estado."))
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: pedidosFiltrados.map((p) => buildPedidoTile(p)).toList(),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
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

  Future<List<Widget>> _generarListaCocina() async {
    List<Widget> lista = [];

    for (var pedido in pedidos) {
      final productosCocina = await filtrarProductosCocina(pedido);
      if (productosCocina.isNotEmpty) {
        lista.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Pedido #${pedido['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
        lista.addAll(productosCocina.map(buildProductoTile));
        lista.add(Divider());
      }
    }

    return lista;
  }
}

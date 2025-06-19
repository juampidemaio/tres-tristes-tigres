import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import 'package:tres_tristes_tigres/classes/mesa.dart';
import 'package:tres_tristes_tigres/classes/pedido.dart';
import 'package:tres_tristes_tigres/classes/producto.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  //Mesas
  Future<String?> subirImagenASupabase(Uint8List bytes, String fileName) async {
    final response = await client.storage
        .from('fotos')
        .uploadBinary(fileName, bytes);

    if (response.isEmpty) return null;

    final publicUrl = client.storage.from('fotos').getPublicUrl(fileName);

    return publicUrl;
  }

  Future<void> agregarMesa(Mesa mesa) async {
    await client.from("mesas").insert(mesa.toJson());
  }

  Future<String> comprobarEstadoMesa(int numeroMesa) async {
    final result =
        await client
            .from('mesas')
            .select('estadoMesa')
            .eq('numero', numeroMesa)
            .single();

    return result['estadoMesa'] as String;
  }

  Future<void> asignarMesa(String correo, int nroMesa) async {
    print(nroMesa);
    print(correo);
    await client
        .from('mesas')
        .update({'usuario': correo, 'estadoMesa': 'ocupada'})
        .eq('numero', nroMesa);
  }

  Future<String> comprobarUsuarioMesa(int numeroMesa) async {
    final result =
        await client
            .from('mesas')
            .select('usuario')
            .eq('numero', numeroMesa)
            .single();

    return result['usuario'] as String;
  }

  Future<int?> comprobarNumeroMesa(String correoUsuario) async {
    try {
      final result =
          await client
              .from('mesas')
              .select('numero')
              .eq('usuario', correoUsuario)
              .single();

      return result['numero'] as int;
    } catch (e) {
      return null;
    }
  }

  // PRODUCTOS - Métodos actualizados
  Future<void> agregarProducto(Producto producto) async {
    try {
      print("=== DEBUGGING PRODUCTO ===");
      print("Datos a insertar: ${producto.toJson()}");

      final response =
          await client.from("productos").insert(producto.toJson()).select();

      print("Inserción exitosa: $response");
    } catch (e) {
      print("ERROR al insertar producto: $e");
      if (e is PostgrestException) {
        print("Código de error: ${e.code}");
        print("Mensaje: ${e.message}");
        print("Detalles: ${e.details}");
      }
      rethrow;
    }
  }

  Future<List<Producto>> obtenerProductos() async {
    final response = await client.from('productos').select();

    return response.map<Producto>((json) => Producto.fromJson(json)).toList();
  }

  // Nuevo método para obtener productos por tipo
  Future<List<Producto>> obtenerProductosPorTipo(String tipo) async {
    final response = await client
        .from('productos')
        .select()
        .eq('tipo', tipo.toLowerCase());

    return response.map<Producto>((json) => Producto.fromJson(json)).toList();
  }

  Future<Producto?> obtenerProductoPorId(int id) async {
    try {
      final response =
          await client.from('productos').select().eq('id', id).single();

      return Producto.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Producto?> obtenerProductoPorNombre(String nombre) async {
    try {
      final response =
          await client.from('productos').select().eq('nombre', nombre).single();

      return Producto.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> actualizarProducto(Producto producto) async {
    await client
        .from('productos')
        .update(producto.toJson())
        .eq('id', producto.id!);
  }

  Future<void> eliminarProducto(int id) async {
    await client.from('productos').delete().eq('id', id);
  }

  Future<int?> obtenerTiempoProducto(int id) async {
    try {
      final result =
          await client
              .from('productos')
              .select('tiempo_promedio_elaboracion')
              .eq('id', id)
              .single();

      return result['tiempo_promedio_elaboracion'] as int;
    } catch (e) {
      return null;
    }
  }

  // Nuevo método para verificar si existe un producto por nombre
  Future<bool> existeProductoPorNombre(String nombre) async {
    try {
      final response = await client
          .from('productos')
          .select('nombre')
          .ilike('nombre', nombre.toLowerCase());

      return response.isNotEmpty;
    } catch (e) {
      print("Error al verificar producto existente: $e");
      return false;
    }
  }

  // Método para obtener solo los nombres de productos (para verificación)
  Future<List<String>> obtenerNombresProductos() async {
    try {
      final response = await client.from('productos').select('nombre');

      return response
          .map<String>((item) => (item['nombre'] as String).toLowerCase())
          .toList();
    } catch (e) {
      print("Error al obtener nombres de productos: $e");
      return [];
    }
  }

  // Método para buscar productos por categoría o filtros - actualizado
  Future<List<Producto>> buscarProductos(String termino, {String? tipo}) async {
    var query = client
        .from('productos')
        .select()
        .or('nombre.ilike.%$termino%,descripcion.ilike.%$termino%');

    // Si se especifica un tipo, filtrar también por tipo
    if (tipo != null && tipo.isNotEmpty) {
      query = query.eq('tipo', tipo.toLowerCase());
    }

    final response = await query;
    return response.map<Producto>((json) => Producto.fromJson(json)).toList();
  }

  //Pedido

  Future<void> agregarPedido(Pedido pedido) async {
    try {
      final response = await client.from("pedidos").insert(pedido.toJson());
    } catch (e) {
      print("ERROR al insertar producto: $e");
    }
  }

  Future<String> verificarClienteHizoPedido(String correo) async {
    var estado = "";

    try {
      final result =
          await client
              .from('pedidos')
              .select('estado')
              .eq('cliente', correo)
              .single();

      estado = result['estado'];
    } catch (e) {
      estado = "";
    }
    return estado;
  }
}

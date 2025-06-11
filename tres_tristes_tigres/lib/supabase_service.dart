import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import 'package:tres_tristes_tigres/classes/mesa.dart';

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
}

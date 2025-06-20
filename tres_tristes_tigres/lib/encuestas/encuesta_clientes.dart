import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EncuestaPage_cliente extends StatefulWidget {
  const EncuestaPage_cliente({super.key});

  @override
  State<EncuestaPage_cliente> createState() => _EncuestaPage_clienteState();
}

class _EncuestaPage_clienteState extends State<EncuestaPage_cliente> {
  final _formKey = GlobalKey<FormState>();

  double puntuacion = 5;
  String atencion = 'buena';
  bool recomendaria = false;
  String experiencia = '';
  String? ambiente;
  List<XFile> imagenes = [];

  final backgroundColor = const Color(0xFF0E6BB7);
  final textColor = const Color(0xFFF7F4EB);
  final chartColors = [
    const Color(0xFFFF9100),
    const Color(0xFF26639D),
    const Color(0xFF98A6C2),
    const Color(0xFFF7F4EB),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Encuesta de Satisfacción'),
        backgroundColor: chartColors[1],
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Theme(
          data: ThemeData(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: chartColors[2],
              hintStyle: TextStyle(color: textColor.withOpacity(0.8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Puntuación general (1 a 10):',
                    style: TextStyle(color: textColor)),
                Slider(
                  value: puntuacion,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: chartColors[0],
                  label: puntuacion.toString(),
                  onChanged: (val) {
                    setState(() {
                      puntuacion = val;
                    });
                  },
                ),

                const SizedBox(height: 16),
                Text('Atención del personal:',
                    style: TextStyle(color: textColor)),
                DropdownButtonFormField<String>(
                  dropdownColor: chartColors[1],
                  value: atencion,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: ['excelente', 'buena', 'regular', 'mala']
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: TextStyle(color: textColor)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => atencion = val!),
                ),

                const SizedBox(height: 16),
                CheckboxListTile(
                  activeColor: chartColors[0],
                  checkColor: Colors.black,
                  value: recomendaria,
                  onChanged: (val) => setState(() => recomendaria = val!),
                  title: Text('¿Recomendarías el lugar?',
                      style: TextStyle(color: textColor)),
                ),

                const SizedBox(height: 16),
                Text('¿Cómo describís tu experiencia?',
                    style: TextStyle(color: textColor)),
                TextFormField(
                  onChanged: (val) => experiencia = val,
                  validator: (val) =>
                      val!.isEmpty ? 'Campo obligatorio' : null,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(
                    hintText: 'Escribí tu experiencia...',
                  ),
                ),

                const SizedBox(height: 16),
                Text('Ambiente del lugar:',
                    style: TextStyle(color: textColor)),
                Column(
                  children: ['Ruidoso', 'Tranquilo', 'Muy agradable']
                      .map((e) => RadioListTile(
                            title: Text(e, style: TextStyle(color: textColor)),
                            value: e,
                            activeColor: chartColors[0],
                            groupValue: ambiente,
                            onChanged: (val) =>
                                setState(() => ambiente = val),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: chartColors[0],
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final selected = await picker.pickMultiImage();
                    if (selected.length > 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Máximo 3 imágenes')),
                      );
                    } else {
                      setState(() => imagenes = selected);
                    }
                  },
                  child: const Text('Seleccionar hasta 3 fotos'),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: chartColors[1],
                    foregroundColor: textColor,
                  ),
                  onPressed: _enviarEncuesta,
                  child: const Text('Enviar Encuesta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enviarEncuesta() async {
    if (_formKey.currentState!.validate()) {
      if (ambiente == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor seleccioná el ambiente')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final supabase = Supabase.instance.client;
      List<String?> urls = [null, null, null];

      try {
        for (int i = 0; i < imagenes.length; i++) {
          final file = File(imagenes[i].path);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final storagePath = 'encuestas_cliente/$fileName';

          await supabase.storage
              .from('encuestas_cliente')
              .upload(storagePath, file);

          final publicUrl = supabase.storage
              .from('encuestas_cliente')
              .getPublicUrl(storagePath);

          urls[i] = publicUrl;
        }

        final user = supabase.auth.currentUser;
        if (user == null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Usuario no autenticado')),
          );
          return;
        }

        await supabase.from('encuestas').insert({
          'usuario_id': user.id,
          'puntuacion_general': puntuacion.toInt(),
          'atencion': atencion,
          'recomendaria': recomendaria,
          'experiencia': experiencia,
          'ambiente': ambiente!.toLowerCase(),
          'imagen1': urls[0],
          'imagen2': urls[1],
          'imagen3': urls[2],
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Encuesta enviada con éxito!')),
        );

        setState(() {
          puntuacion = 5;
          atencion = 'buena';
          recomendaria = false;
          experiencia = '';
          ambiente = null;
          imagenes = [];
        });
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar encuesta: $e')),
        );
      }
    }
  }
}

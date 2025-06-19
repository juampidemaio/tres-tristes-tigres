import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  List<Map<String, dynamic>> encuestas = [];

  final backgroundColor = const Color(0xFF0E6BB7);
  final textColor = const Color(0xFFF7F4EB);
  final chartColors = [
    const Color(0xFFFF9100),
    const Color(0xFF26639D),
    const Color(0xFF98A6C2),
    const Color(0xFFF7F4EB),
  ];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final data = await Supabase.instance.client.from('encuestas').select();
    setState(() {
      encuestas = List<Map<String, dynamic>>.from(data);
    });
  }

  Map<String, int> contar(String campo) {
    final Map<String, int> contador = {};
    for (var encuesta in encuestas) {
      var valor = encuesta[campo];
      if (valor is bool) valor = valor ? 'sí' : 'no';
      final clave = valor?.toString().toLowerCase() ?? 'sin datos';
      contador[clave] = (contador[clave] ?? 0) + 1;
    }
    return contador;
  }

  List<String> obtenerTodasLasImagenes() {
    List<String> imagenes = [];
    for (var encuesta in encuestas) {
      for (var i = 1; i <= 3; i++) {
        final url = encuesta['imagen$i'];
        if (url != null && url.toString().isNotEmpty) {
          imagenes.add(url);
        }
      }
    }
    return imagenes;
  }

  Widget buildPieChart(Map<String, int> data, String titulo) {
    final total = data.values.fold(0, (a, b) => a + b);
    final items = data.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(titulo, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 30,
              sections: List.generate(items.length, (i) {
                final porcentaje = (items[i].value / total) * 100;
                return PieChartSectionData(
                  color: chartColors[i % chartColors.length],
                  value: items[i].value.toDouble(),
                  title: '${porcentaje.toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(items.length, (i) {
            return Chip(
              backgroundColor: chartColors[i % chartColors.length],
              label: Text(items[i].key, style: const TextStyle(color: Colors.black)),
            );
          }),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget buildBarChart(Map<String, int> data, String titulo) {
    final items = data.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(titulo, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(items.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: items[i].value.toDouble(),
                      color: chartColors[i % chartColors.length],
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      return Text(items[idx].key, style: const TextStyle(color: Colors.white, fontSize: 12));
                    },
                  ),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget buildLineChart(String campo, String titulo) {
    List<FlSpot> puntos = [];
    int valorAcumulado = 0;
    for (int i = 0; i < encuestas.length; i++) {
      final valor = encuestas[i][campo];
      if (valor is bool && valor) valorAcumulado++;
      else if (valor == 'sí') valorAcumulado++;
      puntos.add(FlSpot(i.toDouble(), valorAcumulado.toDouble()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(titulo, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: puntos,
                  isCurved: true,
                  barWidth: 3,
                  color: chartColors[0],
                  dotData: FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(show: false),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget buildGaleria() {
    final imagenes = obtenerTodasLasImagenes();
    if (imagenes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text('Galería de experiencias',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: imagenes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: InteractiveViewer(
                      child: Image.network(imagenes[index]),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imagenes[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (encuestas.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final puntuacionPorNumero = <String, int>{};
    for (var e in encuestas) {
      final num = e['puntuacion_general'].toString();
      puntuacionPorNumero[num] = (puntuacionPorNumero[num] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: const Color(0xFFFF9100),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildPieChart(puntuacionPorNumero, 'Puntuaciones (1 a 10)'),
            buildBarChart(contar('atencion'), 'Atención'),
            buildLineChart('recomendaria', '¿Lo recomendarías? (acumulado)'),
            buildBarChart(contar('ambiente'), 'Ambiente'),
            buildGaleria(), 
          ],
        ),
      ),
    );
  }
}

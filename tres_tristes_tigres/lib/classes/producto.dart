class Producto {
  final int? id;
  final String nombre;
  final String descripcion;
  final int tiempoPromedio; // en minutos
  final double precio;
  final String? foto1;
  final String? foto2;
  final String? foto3;
  final String? codigoQr;
  final String tipo; // Nueva propiedad

  Producto({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.tiempoPromedio,
    required this.precio,
    this.foto1,
    this.foto2,
    this.foto3,
    this.codigoQr,
    required this.tipo, // Requerido
  });

  // Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'nombre': nombre,
      'descripcion': descripcion,
      'tiempo_promedio_elaboracion': tiempoPromedio,
      'precio': precio,
      'tipo': tipo, // Agregar tipo
    };
    
    // Solo agregar las fotos que no sean null
    if (foto1 != null) json['foto_1'] = foto1;
    if (foto2 != null) json['foto_2'] = foto2;
    if (foto3 != null) json['foto_3'] = foto3;
    if (codigoQr != null) json['codigo_qr'] = codigoQr;
    
    return json;
  }

  // Crear instancia desde JSON
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tiempoPromedio: json['tiempo_promedio_elaboracion'] ?? 0,
      precio: json['precio']?.toDouble() ?? 0.0,
      foto1: json['foto_1'],
      foto2: json['foto_2'],
      foto3: json['foto_3'],
      codigoQr: json['codigo_qr'],
      tipo: json['tipo'] ?? 'comida', // Valor por defecto
    );
  }

  // Crear copia con modificaciones
  Producto copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    int? tiempoPromedio,
    double? precio,
    String? foto1,
    String? foto2,
    String? foto3,
    String? codigoQr,
    String? tipo,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      tiempoPromedio: tiempoPromedio ?? this.tiempoPromedio,
      precio: precio ?? this.precio,
      foto1: foto1 ?? this.foto1,
      foto2: foto2 ?? this.foto2,
      foto3: foto3 ?? this.foto3,
      codigoQr: codigoQr ?? this.codigoQr,
      tipo: tipo ?? this.tipo,
    );
  }

  @override
  String toString() {
    return 'Producto{id: $id, nombre: $nombre, descripcion: $descripcion, tiempoPromedio: $tiempoPromedio, precio: $precio, tipo: $tipo}';
  }
}
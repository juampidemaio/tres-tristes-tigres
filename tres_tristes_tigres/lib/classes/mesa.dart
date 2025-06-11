class Mesa {
  final int numero;
  final int nroComensales;
  final String tipo;
  final String imagen;
  final String qr;
  final String estadoMesa;

  Mesa({
    required this.numero,
    required this.nroComensales,
    required this.tipo,
    required this.imagen,
    required this.qr,
    required this.estadoMesa,
  });

  factory Mesa.fromJson(Map<String, dynamic> json) {
    return Mesa(
      numero: json['numero'],
      nroComensales: json['nroComensales'],
      tipo: json['tipo'],
      imagen: json['imagen'],
      qr: json['qr'],
      estadoMesa: json['estadoMesa'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'nroComensales': nroComensales,
      'tipo': tipo,
      'imagen': imagen,
      'qr': qr,
      'estadoMesa': estadoMesa,
    };
  }
}

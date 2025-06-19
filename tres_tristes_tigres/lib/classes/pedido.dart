class Pedido {
  final String cliente;
  final Map<int, int> pedido;
  final int tiempoPromedio; //minutos
  final double importe;
  final String estado;

  Pedido({
    required this.cliente,
    required this.pedido,
    required this.tiempoPromedio,
    required this.importe,
    required this.estado,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      cliente: json['cliente'],
      pedido: json['pedido'],
      tiempoPromedio: json['tiempoPromedio'],
      importe: json['importe'],
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cliente': cliente,
      'pedido': pedido.map((key, value) => MapEntry(key.toString(), value)),
      'tiempoPromedio': tiempoPromedio,
      'importe': importe,
      'estado': estado,
    };
  }
}

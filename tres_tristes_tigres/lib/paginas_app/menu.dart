import 'package:flutter/material.dart';
import '../supabase_service.dart';
import '../classes/producto.dart';
import '../classes/pedido.dart';
import '../home.dart';
import '../paginas_app/principalCliente.dart';

class Menu extends StatefulWidget {
  final String url;
  const Menu({super.key, required this.url});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final sb = SupabaseService();
  List<Producto> productos = [];
  Map<int, int> pedido = {};
  String correo = "registrado01@gmail.com";
  String mensajePedido = "";
  double importe = 0;
  String tipoSeleccionado = "Comida";
  bool desplegableAbierto = false;
  int tiempoPromedio = 0;

  @override
  void initState() {
    super.initState();
    traerProductos();
    correo = SupabaseService.client.auth.currentUser!.email!;
  }

  traerProductos() async {
    var listadoProductos = await sb.obtenerProductos();
    setState(() {
      productos = listadoProductos;
    });
  }

  agregarPedido(int idProducto) {
    if (pedido.containsKey(idProducto)) {
      pedido[idProducto] = pedido[idProducto]! + 1;
    } else {
      pedido[idProducto] = 1;
    }
    sumarImporte(idProducto);
    setState(() {
      obtenerTiempoPromedio();
    });
  }

  sacarPedido(int idProducto) {
    if (pedido.containsKey(idProducto)) {
      final cantidadActual = pedido[idProducto]!;
      if (cantidadActual > 1) {
        restarImporte(idProducto);
        setState(() {
          pedido[idProducto] = cantidadActual - 1;
        });
      } else {
        restarImporte(idProducto);
        setState(() {
          pedido.remove(idProducto);
        });
      }
      setState(() {
        obtenerTiempoPromedio();
      });
    }
  }

  sumarImporte(idProducto) {
    for (var producto in productos) {
      if (idProducto == producto.id) {
        setState(() {
          importe += producto.precio;
        });
        break;
      }
    }
  }

  restarImporte(idProducto) {
    if (pedido.containsKey(idProducto)) {
      for (var producto in productos) {
        if (producto.id == idProducto) {
          setState(() {
            importe -= producto.precio;
          });
          break;
        }
      }
    }
  }

  Future<int> obtenerTiempoPromedio() async {
    var maximo = 0;
    for (var idproducto in pedido.keys) {
      var tiempo = await sb.obtenerTiempoProducto(idproducto);
      if (tiempo! > maximo) {
        maximo = tiempo;
      }
    }
    tiempoPromedio = maximo;
    return maximo;
  }

  enviarPedido() async {
    var tiempoMaximo = await obtenerTiempoPromedio();
    var pedidoEnviado = new Pedido(
      cliente: correo,
      pedido: pedido,
      tiempoPromedio: tiempoMaximo,
      importe: importe,
      estado: "pendiente",
    );
    await sb.agregarPedido(pedidoEnviado);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => Principalcliente(url: widget.url, estadoPedido: "pendiente"),
      ),
    );
  }

  confirmarPedido() async {
    String pedidoMensaje = "";
    var tiempoMaximo = await obtenerTiempoPromedio();

    final Map<int, String> idANombre = {
      for (var producto in productos) producto.id!: producto.nombre,
    };

    for (var idproducto in pedido.keys) {
      var nombre = idANombre[idproducto] ?? 'Nombre no encontrado';
      pedidoMensaje += "$nombre: ${pedido[idproducto]}\n";
    }

    setState(() {
      mensajePedido = pedidoMensaje;
      mensajePedido +=
          "\nTiempo estimado: $tiempoMaximo min\nImporte final: \$${importe.toStringAsFixed(2)}";
    });
  }

  List<Producto> get productosFiltrados {
    return productos
        .where(
          (producto) =>
              producto.tipo.toLowerCase() == tipoSeleccionado.toLowerCase(),
        )
        .toList();
  }

  Widget buildProductoCard(Producto producto) {
    int cantidad = pedido[producto.id] ?? 0;
    String imageUrl = producto.foto1!;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                GestureDetector(
                  onTap: () => _mostrarGaleriaImagenes(context, producto),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          producto.foto1 != ""
                              ? Image.network(
                                producto.foto1!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error cargando imagen: $error');
                                  print('URL: $imageUrl');
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[600],
                                      size: 40,
                                    ),
                                  );
                                },
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              )
                              : Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[600],
                                  size: 40,
                                ),
                              ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre en mayúsculas
                      Text(
                        producto.nombre.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Precio
                      Text(
                        '\$${producto.precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Descripción en mayúsculas
            Text(
              producto.descripcion.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
            SizedBox(height: 8),
            // Tiempo promedio de producción
            Text(
              'TIEMPO PROMEDIO DE PRODUCCIÓN: ${producto.tiempoPromedio} MIN',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            // Controles de cantidad centrados debajo de la imagen
            Row(
              children: [
                // Espacio para alinear con la imagen
                SizedBox(width: 116), // 100 de imagen + 16 de padding
                // Botón restar
                GestureDetector(
                  onTap: cantidad > 0 ? () => sacarPedido(producto.id!) : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cantidad > 0 ? Colors.red[400] : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove,
                      color: cantidad > 0 ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Cantidad
                Container(
                  width: 40,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      '$cantidad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Botón agregar
                GestureDetector(
                  onTap: () => agregarPedido(producto.id!),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.green[400],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarGaleriaImagenes(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GaleriaImagenes(producto: producto);
      },
    );
  }

  Widget buildDesplegablePedido() {
    final Map<int, String> idANombre = {
      for (var producto in productos) producto.id!: producto.nombre,
    };

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del desplegable
          GestureDetector(
            onTap: () {
              setState(() {
                desplegableAbierto = !desplegableAbierto;
              });
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius:
                    desplegableAbierto
                        ? BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        )
                        : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'TU PEDIDO:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    '\$${importe.toStringAsFixed(2)}',

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    desplegableAbierto ? Icons.expand_less : Icons.expand_more,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Contenido del desplegable
          if (desplegableAbierto)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  if (pedido.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No hay productos en tu pedido',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    )
                  else
                    ...pedido.entries.map((entry) {
                      var idProducto = entry.key;
                      var cantidad = entry.value;
                      var nombreProducto =
                          idANombre[idProducto] ?? 'Producto desconocido';
                      var precio =
                          productos
                              .firstWhere((p) => p.id == idProducto)
                              .precio;
                      var subtotal = precio * cantidad;

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '$nombreProducto',
                              style: TextStyle(fontSize: 16),
                            ),
                            Spacer(),
                            Text(
                              '$cantidad x \$${precio.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              '\$${subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                  if (pedido.isNotEmpty) ...[
                    Divider(height: 24),
                    Row(
                      children: [
                        Text(
                          'TIEMPO APROXIMADO:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '$tiempoPromedio minutos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '\$${importe.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          await confirmarPedido();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              if (pedido.isEmpty) {
                                return AlertDialog(
                                  title: Text("Error"),
                                  content: Text(
                                    "Debe elegir al menos un producto",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text("Aceptar"),
                                    ),
                                  ],
                                );
                              } else {
                                return AlertDialog(
                                  title: Text("Confirmar pedido"),
                                  content: Text(
                                    "Confirme el pedido:\n$mensajePedido",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text("Cancelar"),
                                    ),
                                    Builder(
                                      builder: (BuildContext dialogContext) {
                                        return ElevatedButton(
                                          onPressed: () async {
                                            final messenger =
                                                ScaffoldMessenger.of(
                                                  dialogContext,
                                                );
                                            Navigator.of(dialogContext).pop();
                                            await enviarPedido();
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Pedido enviado con éxito",
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            await Future.delayed(
                                              Duration(seconds: 2),
                                            );
                                            if (mounted) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          Principalcliente(
                                                            url: widget.url,
                                                          ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Text("Confirmar"),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              }
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'CONFIRMAR PEDIDO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header estático con título y botón volver
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                SizedBox(width: 8),
                Text(
                  'Menú',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Combo box estático
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: tipoSeleccionado,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      tipoSeleccionado = newValue!;
                    });
                  },
                  items:
                      <String>[
                        'Comida',
                        'Bebida',
                        'Postre',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),

          // Lista scrolleable de productos
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              itemCount: productosFiltrados.length,
              itemBuilder: (context, index) {
                return buildProductoCard(productosFiltrados[index]);
              },
            ),
          ),

          // Desplegable estático del pedido
          buildDesplegablePedido(),
        ],
      ),
    );
  }
}

class GaleriaImagenes extends StatefulWidget {
  final Producto producto;

  const GaleriaImagenes({Key? key, required this.producto}) : super(key: key);

  @override
  State<GaleriaImagenes> createState() => _GaleriaImagenesState();
}

class _GaleriaImagenesState extends State<GaleriaImagenes> {
  int imagenActual = 0;
  PageController pageController = PageController();
  late List<String> imagenesUrls;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    imagenesUrls = [
      widget.producto.foto1!,
      widget.producto.foto2!,
      widget.producto.foto3!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (imagenesUrls.isEmpty) {
      return Dialog(
        child: Container(
          height: 300,
          child: Center(
            child: Text(
              'No hay imágenes disponibles',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Stack(
          children: [
            // Fondo semi-transparente
            Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // PageView para las imágenes
            PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                setState(() {
                  imagenActual = index;
                });
              },
              itemCount: imagenesUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.all(20),
                  child: Center(
                    child: Image.network(
                      imagenesUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error cargando imagen en galería: $error');
                        print('URL: ${imagenesUrls[index]}');
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[600],
                            size: 80,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            // Botón cerrar
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            // Flecha izquierda
            if (imagenesUrls.length > 1)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (imagenActual > 0) {
                        pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            imagenActual > 0
                                ? Colors.black54
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color:
                            imagenActual > 0
                                ? Colors.white
                                : Colors.transparent,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            // Flecha derecha
            if (imagenesUrls.length > 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (imagenActual < imagenesUrls.length - 1) {
                        pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            imagenActual < imagenesUrls.length - 1
                                ? Colors.black54
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color:
                            imagenActual < imagenesUrls.length - 1
                                ? Colors.white
                                : Colors.transparent,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            // Indicadores de página
            if (imagenesUrls.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    imagenesUrls.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            imagenActual == index
                                ? Colors.white
                                : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

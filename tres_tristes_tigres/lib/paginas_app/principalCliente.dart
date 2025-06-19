import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tres_tristes_tigres/encuestas/encuesta_clientes.dart';
import 'package:tres_tristes_tigres/encuestas/estadisticas_page.dart';
import 'package:tres_tristes_tigres/home.dart';
import '../supabase_service.dart';
import '../login.dart';
import '../paginas_app/escanerQR.dart';
import '../paginas_app/menu.dart';

class Principalcliente extends StatefulWidget {
  final String url;
  final String estadoPedido; 
   final bool escaneoRealizado;

  const Principalcliente({
    super.key,
    required this.url,
    this.estadoPedido = "",
    this.escaneoRealizado = false,
  });

  @override
  State<Principalcliente> createState() => _PrincipalclienteState();
}

class _PrincipalclienteState extends State<Principalcliente> {
  final supabaseService = SupabaseService();
  String estadoMesa = "libre";
  String usuarioMesa = "";
  int numeroMesa = 0;
  int? numeroMesaCorrecta;
  bool mesaCorrecta = false;
  bool yaRealizoEncuesta = false;

  @override
  void initState() {
    super.initState();
    obtenerNumeroMesa();
    comprobarEstadoMesa();
    obtenerMesaCorrecta();
    verificarEncuesta();
  }
Future<void> verificarEncuesta() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return;

 final response = await supabase
    .from('encuestas')
    .select('realizo_encuesta')
    .eq('usuario_id', user.id)
    .order('fecha_creacion', ascending: false) // 🔽 ordena por fecha
    .limit(1) // 🔝 solo la más reciente
    .maybeSingle(); // ✅ ahora sí, seguro devuelve una o ninguna


  print('Respuesta encuesta: $response');
  setState(() {
    yaRealizoEncuesta = response?['realizo_encuesta'] ?? false;
  });
  print('Estado yaRealizoEncuesta actualizado a: $yaRealizoEncuesta');
}


  obtenerMesaCorrecta() async {
    int? resultado = await supabaseService.comprobarNumeroMesa(
      SupabaseService.client.auth.currentUser!.email!,
    );
    setState(() {
      numeroMesaCorrecta = resultado;
      mesaCorrecta = (numeroMesa == numeroMesaCorrecta);
    });
  }

  obtenerNumeroMesa() {
    var parteUrl = (widget.url.split('/')).last;
    numeroMesa = int.parse(parteUrl);
  }

  asignarMesa(String usuario) async {
    supabaseService.asignarMesa(usuario, numeroMesa);
  }

  void logout(BuildContext context) async {
    await SupabaseService.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(showLogoutMessage: true),
        ),
      );
    }
  }

  comprobarEstadoMesa() async {
    estadoMesa = await supabaseService.comprobarEstadoMesa(numeroMesa);
    setState(() {
      estadoMesa;
    });
  }

  comprobarUsuarioMesa() async {
    usuarioMesa = await supabaseService.comprobarUsuarioMesa(numeroMesa);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Cuadriculado superior
          Container(
            height: 40,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/imagenes/cuadriculado.png',
                ), // Patrón cuadriculado superior
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Contenido principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.99,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26639C),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sección superior con logo y título
                        Container(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              // Logo del tigre chef
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/imagenes/icono_blanco.png',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Título INICIO
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HomePage(),
                                    ),
                                    (route) =>
                                        false, // elimina todas las pantallas anteriores
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFD9400),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: const Text(
                                    'INICIO',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Opciones del menú
                        if (estadoMesa == "ocupada" && mesaCorrecta) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              children: [
                                // Botón Consultar Mozo
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 15),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginPage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.person_add,
                                        color: Color(0xFF26639C),
                                      ),
                                      label: const Text(
                                        'CONSULTAR MOZO',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF26639C,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),

                                // Botón Menú
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 15),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => Menu(url: widget.url),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.restaurant_menu,
                                        color: Color(0xFF26639C),
                                      ),
                                      label: const Text(
                                        'MENÚ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF26639C,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),

                                //BOTON DE ESCANEO
                                if (widget.estadoPedido == "pendiente" ||
                                    widget.estadoPedido ==
                                        "enProceso") // mostrar sólo si aplica
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 15),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const Escanerqr(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.list_alt,
                                        color: Color(0xFF26639C),
                                      ),
                                      label: const Text(
                                        'ESCANEA PARA VER MAS OPCIONES',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF26639C,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),

                                //BOTON ESTADO DEL PEDIDO
                                if (widget.escaneoRealizado &&
                                    (widget.estadoPedido == "pendiente" ||
                                    widget.estadoPedido == "enProceso" ||
                                    widget.estadoPedido == "paraEnviar"))
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 15),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              backgroundColor: const Color(
                                                0xFF0E6BB7,
                                              ),
                                              title: const Text(
                                                "Estado del Pedido",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Tu pedido se encuentra actualmente:",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    widget.estadoPedido ==
                                                            "pendiente"
                                                        ? "⏳ Pendiente de confirmación por el mozo."
                                                        : "🍽️ En proceso. El equipo ya está preparando tu pedido.",
                                                    style: const TextStyle(
                                                      color: Colors.amber,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Text(
                                                    "Gracias por tu paciencia 😊",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                  child: const Text(
                                                    "Cerrar",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.list_alt,
                                        color: Color(0xFF26639C),
                                      ),
                                      label: const Text(
                                        'ESTADO PEDIDOS',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF26639C,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),

                              //BOTON ENCUESTA SATISFACCION
                               if (widget.estadoPedido == "pendiente" ||
                                    widget.estadoPedido == "enProceso" ||
                                    widget.estadoPedido == "paraEnviar")
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 15),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                  if (yaRealizoEncuesta) {
                                    print("Mostrando resultados porque ya realizó encuesta");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => EstadisticasPage()),
                                    );
                                  } else {
                                    print("Todavía no realizó encuesta, mostrando formulario");
                                    final resultado = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => EncuestaPage_cliente()),
                                    );

                                    print("Resultado al volver de encuesta: $resultado");
                                    if (resultado == true) {
                                      verificarEncuesta(); // 🔄 se actualiza yaRealizoEncuesta
                                    }
                                  }
                                },


                                  icon: Icon(
                                    yaRealizoEncuesta ? Icons.bar_chart : Icons.star_rate,
                                    color: const Color(0xFF26639C),
                                  ),
                                  label: Text(
                                    yaRealizoEncuesta ? 'VER RESULTADOS ENCUESTA' : 'ENCUESTA SATISFACCIÓN',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF26639C),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    elevation: 3,
                                  ),
                                ),
                              ),

                                // Botón Juegos
                                if (widget.estadoPedido == "enProceso")
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginPage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.games,
                                        color: Color(0xFF26639C),
                                      ),
                                      label: const Text(
                                        'JUEGOS',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF26639C,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),

                                // Botón de logout en la parte inferior
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 15),
                                  child: ElevatedButton.icon(
                                    onPressed: () => logout(context),
                                    icon: const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'CERRAR SESIÓN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFD9400),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!mesaCorrecta) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              children: [
                                // Icono de advertencia
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFD9400),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Mensaje principal
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.table_restaurant,
                                        color: Color(0xFF26639C),
                                        size: 30,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        '¡Mesa Incorrecta!',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF26639C),
                                          fontFamily: 'Roboto',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        'Esta mesa ya fue asignada a otro cliente.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                          fontFamily: 'Roboto',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFD9400),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Su mesa es la Nº $numeroMesaCorrecta',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Botón de logout
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 15),
                                  child: ElevatedButton.icon(
                                    onPressed: () => logout(context),
                                    icon: const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'VOLVER AL INICIO',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFD9400),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        //2
                        if (numeroMesaCorrecta == null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              children: [
                                // Icono de advertencia
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFD9400),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Mensaje principal
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.table_restaurant,
                                        color: Color(0xFF26639C),
                                        size: 30,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        '¡Mesa Incorrecta!',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF26639C),
                                          fontFamily: 'Roboto',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        'Esta mesa ya fue asignada a otro cliente.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                          fontFamily: 'Roboto',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFD9400),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Aguarde a que se le asigne una mesa.',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Botón de logout
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 15),
                                  child: ElevatedButton.icon(
                                    onPressed: () => logout(context),
                                    icon: const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'VOLVER AL INICIO',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFD9400),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (numeroMesaCorrecta == null) ...[
                          Text(
                            "Esta mesa ya fue asignada a otro cliente. Aguarde a que se le asigne una mesa.",
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Cuadriculado inferior
          Container(
            height: 40,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/imagenes/cuadriculado.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

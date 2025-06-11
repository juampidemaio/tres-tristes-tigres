import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../supabase_service.dart';
import '../login.dart';

class Principalcliente extends StatefulWidget {
  final String url;
  const Principalcliente({super.key, required this.url});

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

  @override
  void initState() {
    obtenerNumeroMesa();
    comprobarEstadoMesa();
    obtenerMesaCorrecta();
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
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Título INICIO
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 12,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

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
                                      foregroundColor: const Color(0xFF26639C),
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

                                // Botón Menú
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
                                      foregroundColor: const Color(0xFF26639C),
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

                                // Botón Estado Pedidos
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
                                      foregroundColor: const Color(0xFF26639C),
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

                                // Botón Encuesta Satisfacción
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
                                      Icons.star_rate,
                                      color: Color(0xFF26639C),
                                    ),
                                    label: const Text(
                                      'ENCUESTA SATISFACCIÓN',
                                      style: TextStyle(
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ),

                                // Botón Juegos
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
                                      foregroundColor: const Color(0xFF26639C),
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

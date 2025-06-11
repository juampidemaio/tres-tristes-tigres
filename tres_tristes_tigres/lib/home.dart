import 'package:flutter/material.dart';
import 'package:tres_tristes_tigres/gestion_maitre.dart';
import 'package:tres_tristes_tigres/supabase_service.dart';
import 'package:tres_tristes_tigres/qrs/ingreso_local.dart';
import 'login.dart';
import './registros/registro_mesa.dart';
import './registros/registro_dueno.dart';
import './registros/registro_cliente.dart';
import 'paginas_app/escanerQR.dart';
import './gestion_clientes.dart';
import 'package:tres_tristes_tigres/encuestas/estadisticas_page.dart';
import 'package:tres_tristes_tigres/encuestas/encuesta_clientes.dart';

// Paleta de colores
final backgroundColor = const Color(0xFF0E6BB7);
final textColor = const Color(0xFFF7F4EB);
final chartColors = [
  const Color(0xFFFF9100),
  const Color(0xFF26639D),
  const Color(0xFF98A6C2),
  const Color(0xFFF7F4EB),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? perfil;
  String? tipoEmpleado;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    obtenerPerfilUsuario();
  }

  Future<void> obtenerPerfilUsuario() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final response =
          await SupabaseService.client
              .from('usuarios')
              .select('perfil, tipo_empleado')
              .eq('id', user.id)
              .maybeSingle();

      setState(() {
        perfil = response?['perfil'];
        tipoEmpleado = response?['tipo_empleado'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
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

  Future<bool> tieneMesaAsignada() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;

    final ingreso =
        await SupabaseService.client
            .from('ingresos_local')
            .select('id')
            .eq('usuario_id', user.id)
            .eq('estado', 'asignado')
            .maybeSingle();

    return ingreso != null;
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;

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
                                width: 100,
                                height: 100,
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
                              // Título de Bienvenida
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFD9400),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  '¡Hola, ${user?.email?.split('@')[0] ?? "Usuario"}!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Loading indicator
                        if (isLoading) ...[
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 20),
                        ],

                        // Opciones para Dueño o Supervisor
                        if (!isLoading &&
                            (perfil == 'dueño' || perfil == 'supervisor')) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              children: [
                                _buildStyledButton(
                                  icon: Icons.person_add,
                                  label: 'ALTA DE SUPERVISOR',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const RegistroDueno(
                                              perfil: 'supervisor',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                _buildStyledButton(
                                  icon: Icons.person_add_alt,
                                  label: 'ALTA DE DUEÑO',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const RegistroDueno(
                                              perfil: 'dueño',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                _buildStyledButton(
                                  icon: Icons.group,
                                  label: 'GESTIÓN DE CLIENTES',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => GestionClientesPage(
                                              perfilActual: perfil!,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                _buildStyledButton(
                                  icon: Icons.table_restaurant,
                                  label: 'GESTIÓN DE MESAS',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegistroMesa(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Opciones para Cliente Registrado o Maitre
                        if (!isLoading &&
                            (perfil == 'cliente_registrado' ||
                                (perfil == 'empleado' &&
                                    tipoEmpleado == 'maitre'))) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              children: [
                                _buildStyledButton(
                                  icon: Icons.person,
                                  label: 'ALTA DE CLIENTE',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const RegistroCliente(
                                              perfil: 'cliente_registrado',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                _buildStyledButton(
                                  icon: Icons.person_outline,
                                  label: 'ALTA CLIENTE ANÓNIMO',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const RegistroCliente(
                                              perfil: 'cliente_anonimo',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Opciones para Cliente (Anónimo o Registrado)
                        if (!isLoading &&
                            (perfil == 'cliente_anonimo' ||
                                perfil == 'cliente_registrado')) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              children: [
                                _buildStyledButton(
                                  icon: Icons.qr_code,
                                  label: 'ESCANEAR QR PARA INGRESAR',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const QrIngresoPage(),
                                      ),
                                    );
                                  },
                                ),
                                _buildStyledButton(
                                  icon: Icons.qr_code_scanner,
                                  label: 'ESCANEAR QR DE MESA',
                                  onPressed: () async {
                                    bool asignada = await tieneMesaAsignada();
                                    if (!asignada && context.mounted) {
                                      _showNoTableDialog(context);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const Escanerqr(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                _buildStyledButton(
                                  icon: Icons.bar_chart,
                                  label: 'VER RESULTADOS ENCUESTAS',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const EstadisticasPage(),
                                      ),
                                    );
                                  },
                                ),
                                _buildStyledButton(
                                  icon: Icons.edit_note,
                                  label: 'COMPLETAR ENCUESTA',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const EncuestaPage_cliente(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Opciones para Maitre
                        if (!isLoading && tipoEmpleado == 'maitre') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              children: [
                                _buildStyledButton(
                                  icon: Icons.people,
                                  label: 'LISTADO DE CLIENTES',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ClientesMaitrePage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Botón de logout
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 20, bottom: 15),
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
                        ),
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

  Widget _buildStyledButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF26639C)),
        label: Text(
          label,
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
    );
  }

  void _showNoTableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFF26639C),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const Text(
                    'Sin mesa asignada',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Todavía no tenés una mesa asignada.\n'
                    'Primero tenés que ponerte en lista de espera y esperar a que te asignen una.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF26639C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

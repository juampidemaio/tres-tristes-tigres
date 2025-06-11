import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tres_tristes_tigres/push_notification_service.dart';
import 'home.dart';
import 'registro_page.dart';
import 'package:tres_tristes_tigres/supabase_service.dart';

class LoginPage extends StatefulWidget {
  final bool showLogoutMessage;

  const LoginPage({super.key, this.showLogoutMessage = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final supabase = SupabaseService.client;

  final quickUsers = [
    {'label': 'Anónimo', 'email': 'anonimo01@gmail.com', 'password': '123456'},
    {
      'label': 'Registrado',
      'email': 'registrado01@gmail.com',
      'password': '123456',
    },
    {'label': 'Dueño', 'email': 'dueno01@gmail.com', 'password': '123456'},
    {
      'label': 'Supervisor',
      'email': 'supervisor01@gmail.com',
      'password': '123456',
    },
    {'label': 'Mozo', 'email': 'mozo01@gmail.com', 'password': '123456'},
    {'label': 'Maitre', 'email': 'maitre01@gmail.com', 'password': '123456'},
    {
      'label': 'Cocinero',
      'email': 'cocinero01@gmail.com',
      'password': '123456',
    },
    {
      'label': 'Bartender',
      'email': 'bartender01@gmail.com',
      'password': '123456',
    },
  ];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showLogoutMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showMessage("✅ Sesión cerrada correctamente.");
      });
    }
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final res = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = res.user;
      if (user == null) throw 'Usuario o contraseña incorrectos.';

      final perfil =
          await supabase
              .from('usuarios')
              .select('perfil, aprobado')
              .eq('id', user.id)
              .maybeSingle();

      if (perfil == null) {
        showMessage("❌ Usuario sin perfil registrado.");
      } else if (perfil['perfil'] == 'cliente_registrado' &&
          perfil['aprobado'] == "pendiente") {
        showMessage("⏳ Esperando aprobación del supervisor o dueño.");
      } else if (perfil['perfil'] == 'cliente_registrado' &&
          perfil['aprobado'] == "rechazado") {
        showMessage("❌ La solicitud se te rechazó, no podrás ingresar.");
      } else {
         //guardamos el token y el usuario en user_tokens
         await PushNotificationService().initialize();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      showMessage("❌ Error al iniciar sesión: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> quickLogin(String email, String password) async {
    setState(() => isLoading = true);
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw 'Usuario o contraseña incorrectos.';

      final perfil =
          await supabase
              .from('usuarios')
              .select('perfil, aprobado')
              .eq('id', user.id)
              .maybeSingle();

      if (perfil == null) {
        showMessage("❌ Usuario sin perfil registrado.");
      } else if (perfil['perfil'] == 'cliente_registrado' &&
          perfil['aprobado'] == false) {
        showMessage("⏳ Esperando aprobación del supervisor o dueño.");
      } else {
          //guardamos el token y el usuario en user_tokens
         await PushNotificationService().initialize();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      showMessage("❌ Error al iniciar sesión rápida: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF0E6BB7),
            content: Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
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
                          child: Form(
                            key: formKey,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.99,
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
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
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
                                        // Título INGRESO
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFD9400),
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                          ),
                                          child: const Text(
                                            'INGRESO',
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
                                  // Formulario
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 25,
                                    ),
                                    child: Column(
                                      children: [
                                        // Campo de correo
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: TextFormField(
                                            controller: emailController,
                                            decoration: InputDecoration(
                                              hintText: 'Correo electrónico',
                                              hintStyle: TextStyle(
                                                color: Colors.grey[600],
                                                fontFamily: 'Roboto',
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                borderSide: BorderSide.none,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontFamily: 'Roboto',
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return "Por favor ingresa tu correo.";
                                              }
                                              final emailRegex = RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                              );
                                              if (!emailRegex.hasMatch(value)) {
                                                return "El correo no es válido.";
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Campo de contraseña
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: TextFormField(
                                            controller: passwordController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              hintText: 'Contraseña',
                                              hintStyle: TextStyle(
                                                color: Colors.grey[600],
                                                fontFamily: 'Roboto',
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                borderSide: BorderSide.none,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontFamily: 'Roboto',
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return "Por favor ingresa tu contraseña.";
                                              }
                                              if (value.length < 6) {
                                                return "La contraseña debe tener al menos 6 caracteres.";
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Botón Iniciar Sesión
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: ElevatedButton(
                                            onPressed: login,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(
                                                0xFF26639C,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              elevation: 3,
                                            ),
                                            child: const Text(
                                              "INICIAR SESION",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Texto "¿Todavía no tienes una cuenta?" y Registrarse en la misma línea
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              '¿Todavía no tienes una cuenta? ',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            const RegistroPage(),
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text(
                                                'Registrarse',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      14, // Reducido de 16 a 14
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor: Colors.white,
                                                  fontFamily: 'Roboto',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Sección de acceso rápido
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      25,
                                      8,
                                      25,
                                      15,
                                    ),
                                    child: GridView.count(
                                      shrinkWrap: true,
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio:
                                          3.2, // Más ancho y menos alto
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children:
                                          quickUsers.map((user) {
                                            return ElevatedButton(
                                              onPressed:
                                                  () => quickLogin(
                                                    user['email']!,
                                                    user['password']!,
                                                  ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: const Color(
                                                  0xFF26639C,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                elevation: 2,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 6,
                                                    ),
                                              ),
                                              child: Text(
                                                user['label']!,
                                                style: const TextStyle(
                                                  fontSize:
                                                      12, // Reducido de 12 a 10
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Roboto',
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ],
                              ),
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metro_gestion_proyecto/screens/home/home_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:metro_gestion_proyecto/register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage =
            'Error: Credenciales no válidas. Intente de nuevo.';
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          errorMessage = 'Email o contraseña incorrectos.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Formato de email inválido.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese su correo electrónico'),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // LOGO CON LA RUTA CORRECTA
                  Image.asset(
                    'assets/imagen/Logo.png', // Ruta corregida
                    height: 120,
                    width: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.directions_subway,
                        size: 80,
                        color: Colors.blue,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'METROGESTIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Inicie sesión para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Campo Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Ingrese su correo electrónico'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Campo Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Ingrese su contraseña'
                        : null,
                  ),
                  const SizedBox(height: 10),

                  // Olvidó contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: const Text(
                        '¿Olvidó su contraseña?',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BOTÓN INICIAR SESIÓN
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('INICIAR SESIÓN'),
                  ),

                  const SizedBox(height: 20),

                  // Registro
                  // ---- REEMPLAZA EL TextButton CON ESTO: ----
                  Text.rich(
                    TextSpan(
                      text: '¿Aún no tienes cuenta? ',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors
                            .blueGrey, // <-- Usando el color que ya tenías
                      ),
                      children: [
                        TextSpan(
                          text: 'Regístrate aquí',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors
                                .orange, // <-- Naranja, para que combine con tu botón
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),

                          // --- Esto es lo que hace el clic ---
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Navega a la pantalla de registro
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

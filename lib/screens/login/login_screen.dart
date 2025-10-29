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
    // ... (Tu lógica de login no cambia)
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
    // ... (Tu lógica de reset no cambia)
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese su correo electrónico'),
        ),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se ha enviado un correo para restablecer su contraseña',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al enviar correo de restablecimiento.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No existe un usuario con ese correo.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Formato de correo inválido.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CAMBIO: AppBar para dar sensación de página web
      appBar: AppBar(title: const Text('Iniciar Sesión'), elevation: 0),
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
                  // LOGO
                  Image.asset(
                    'assets/imagen/Logo.png', // Ruta de tu logo
                    height: 100,
                  ),
                  const SizedBox(height: 32),

                  // --- Campo de Email ---
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? 'Ingrese un correo válido'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // --- Campo de Contraseña ---
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Ingrese su contraseña'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // --- Olvidé mi contraseña ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        'Olvidé mi contraseña',
                        // CAMBIO: Color naranja del tema
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Botón de Login ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    // CAMBIO: Estilo ya se toma del ThemeData
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
                  const SizedBox(height: 24),

                  // --- Enlace a Registro ---
                  RichText(
                    text: TextSpan(
                      text: '¿No tienes una cuenta? ',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(
                          text: 'Regístrate aquí',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).primaryColor, // CAMBIO
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
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

import 'package:flutter/material.dart';
import 'package:metro_gestion_proyecto/screens/home/home_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:metro_gestion_proyecto/services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String? error = await _authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (error == null) {
          if (!mounted) return; // <-- AÑADIR ESTA LÍNEA
          // Navegar si el login fue exitoso
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          if (!mounted) return; // <-- AÑADIR ESTA LÍNEA (Buena práctica)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      } finally {
        if (mounted) { // <-- AÑADIR ESTA COMPROBACIÓN (Buena práctica)
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    final String? error = await _authService.sendPasswordResetEmail(email: email);
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se ha enviado un correo para restablecer su contraseña.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

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


                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        'Olvidé mi contraseña',

                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),


                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,

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
                            color: Theme.of(context).primaryColor,
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

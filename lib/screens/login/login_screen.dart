import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metro_gestion_proyecto/screens/home/home_screen.dart';

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

  // Lógica de inicio de sesión con Firebase
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Muestra el indicador de carga
      });
      
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // ÉXITO: Navegar a HomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );

      } on FirebaseAuthException catch (e) {
        // ERROR: Mostrar mensaje al usuario
        String errorMessage = 'Error: Credenciales no válidas. Intente de nuevo.';
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          errorMessage = 'Email o contraseña incorrectos.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );

      } finally {
        setState(() {
          _isLoading = false; // Oculta el indicador de carga
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Utilizamos SingleChildScrollView para evitar desbordamientos del teclado
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // Diseño responsivo básico
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Logo y Marca (Mismo que en Figma)
                  const Icon(Icons.business_center, size: 80, color: Colors.blue),
                  const SizedBox(height: 8),
                  const Text('METROGESTIÓN', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 32),
                  const Text('Inicie sesión para continuar', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 32),

                  // Campo Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                    validator: (value) => (value == null || value.isEmpty) ? 'Ingrese su correo electrónico' : null,
                  ),
                  const SizedBox(height: 20),

                  // Campo Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                    validator: (value) => (value == null || value.isEmpty) ? 'Ingrese su contraseña' : null,
                  ),
                  const SizedBox(height: 10),

                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('¿Olvidó su contraseña?', style: TextStyle(color: Colors.grey)))),
                  const SizedBox(height: 24),

                  // BOTÓN INICIAR SESIÓN (con manejo de carga)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin, // Deshabilitado si está cargando
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('INICIAR SESIÓN'),
                  ),

                  const SizedBox(height: 20),
                  TextButton(onPressed: () {}, child: const Text('¿Aún no tienes cuenta? Regístrate aquí', style: TextStyle(color: Colors.blueGrey))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
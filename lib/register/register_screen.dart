import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ----- 1. Variables para controlar el formulario -----
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // <-- Nuevo
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _selectedRole;
  // ----- 2. Función para manejar el registro -----
  void _handleRegister() async {
    // Primero, valida que los campos no estén vacíos
    if (_formKey.currentState!.validate()) {
      // Segundo, valida que las contraseñas coincidan
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden.')),
        );
        return; // No continúes si no coinciden
      }

      // Si todo está bien, muestra el ícono de carga
      setState(() {
        _isLoading = true;
      });

      // ----- 3. Lógica de Firebase para crear usuario -----
      try {
          UserCredential cred = await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),

        );
        // Guardar datos adicionales (del rol) en Firestore
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(cred.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'rol': _selectedRole,
          'fechaRegistro': DateTime.now(), //dato que pudise llegar a ser util
        });

        // Si sale bien, ¡Felicidades!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Cuenta creada con éxito! Ya puedes iniciar sesión.',
            ),
          ),
        );
        // Regresa a la pantalla de login
        Navigator.of(context).pop();
      } on FirebaseAuthException catch (e) {
        // Manejo de errores comunes
        String errorMessage = 'Error al registrar. Intente de nuevo.';
        if (e.code == 'weak-password') {
          errorMessage =
              'La contraseña es muy débil (debe tener al menos 6 caracteres).';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Este correo electrónico ya está en uso.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'El formato del correo no es válido.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        // siempre apagar el loading
        setState(() {
          _isLoading = false;
        });
    }
  }
}


  // ----- 4. Diseño (UI) de la pantalla -----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar para poder regresar ---
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.blue, // Color del tema
        foregroundColor: Colors.white, // Color del texto
        elevation: 0,
      ),
      // --- Cuerpo del formulario (muy similar al login) ---
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
                  // --- Título ---
                  const Text(
                    'Completa tus datos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Campo Email (Igual al login) ---
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
                        ? 'Ingrese su correo'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // --- Campo Contraseña (Igual al login) ---
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
                        ? 'Ingrese una contraseña'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // --- NUEVO: Campo Confirmar Contraseña ---
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Confirme su contraseña'
                        : null,
                  ),
                  const SizedBox(height: 32),
                //boton para seleccionar rol
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'estudiante', child: Text('Estudiante')),
                    DropdownMenuItem(value: 'profesor', child: Text('Profesor')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                  validator: (value) => value == null ? 'Seleccione un rol' : null,
                ),
                    const SizedBox(height: 32),
                  // --- Botón de Registro (Igual al login) ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                        : const Text('REGISTRAR'), // <-- Texto del botón
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _selectedRole;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden.')),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(cred.user!.uid)
            .set({
              'email': _emailController.text.trim(),
              'rol': _selectedRole,
              'fechaRegistro': DateTime.now(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Cuenta creada con éxito! Ya puedes iniciar sesión.',
            ),
          ),
        );
        Navigator.of(context).pop();
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Error al registrar. Intente de nuevo.';
        if (e.code == 'weak-password') {
          errorMessage =
              'La contraseña es muy débil (debe tener al menos 6 caracteres).';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Este correo electrónico ya está en uso.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'El formato del correo no es válido.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text('Crear Cuenta'), elevation: 0),
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
                  Text(
                    'Registro de Nuevo Usuario',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor, // CAMBIO
                    ),
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
                      labelText: 'Contraseña (mín. 6 caracteres)',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) => (value == null || value.length < 6)
                        ? 'La contraseña debe tener al menos 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Confirme su contraseña'
                        : null,
                  ),
                  const SizedBox(height: 24),


                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: '¿Cuál es tu rol?',
                      prefixIcon: Icon(Icons.person_search),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'estudiante',
                        child: Text('Estudiante'),
                      ),
                      DropdownMenuItem(
                        value: 'profesor',
                        child: Text('Profesor'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Seleccione un rol' : null,
                  ),
                  const SizedBox(height: 32),


                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,

                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('REGISTRAR'),
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

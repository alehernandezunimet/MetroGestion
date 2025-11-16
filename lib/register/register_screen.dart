import 'package:flutter/material.dart';
import 'package:metro_gestion_proyecto/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final AuthService _authService = AuthService();
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

      // Verificación del dominio del correo
      if (!_emailController.text.trim().endsWith('@correo.unimet.edu.ve')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Solo se permiten correos institucionales.')),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });

      try {
        // Combinar nombre y apellido en un solo campo
        String nombreCompleto = '${_nombreController.text.trim()} ${_apellidoController.text.trim()}';

        final String? error = await _authService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          nombreCompleto: nombreCompleto,
          rol: _selectedRole!,
        );

        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta creada con éxito! Ya puedes iniciar sesión.'),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
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
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo para Nombre
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      hintText: 'Ingrese su nombre',
                    ),
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                    (value == null || value.isEmpty)
                        ? 'Ingrese su nombre'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Campo para Apellido
                  TextFormField(
                    controller: _apellidoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      hintText: 'Ingrese su apellido',
                    ),
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                    (value == null || value.isEmpty)
                        ? 'Ingrese su apellido'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Campo para Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return 'Ingrese un correo válido';
                      }
                      if (!value.endsWith('@correo.unimet.edu.ve')) {
                        return 'Solo se permiten correos @correo.unimet.edu.ve';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo para Contraseña
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

                  // Campo para Confirmar Contraseña
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

                  // Selector de Rol
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
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

                  // Botón de Registro
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
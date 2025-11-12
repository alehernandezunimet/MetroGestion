import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String? userEmail;
  final String? userRole;
  final String? userName;
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({
    super.key,
    this.userEmail,
    this.userRole,
    this.userName,
    this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Actualizar en Firestore
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .update({
            'nombre': _nameController.text,
          });

          // Actualizar email en Firebase Auth
          if (_emailController.text != user.email) {
            await user.updateEmail(_emailController.text);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );

          setState(() {
            _isEditing = false;
          });

          // Notificar al padre que los datos se actualizaron
          widget.onProfileUpdated?.call();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mi Perfil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                    if (!_isEditing) {
                      // Resetear valores si cancela
                      _nameController.text = widget.userName ?? '';
                      _emailController.text = widget.userEmail ?? '';
                    }
                  });
                },
                tooltip: _isEditing ? 'Cancelar' : 'Editar',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInfoField(
                      label: 'Nombre',
                      controller: _nameController,
                      isEditable: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      isEditable: _isEditing,
                      isEmail: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Rol',
                      widget.userRole == 'profesor' ? 'Profesor/a' : 'Estudiante',
                    ),
                    const SizedBox(height: 20),
                    if (_isEditing)
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Guardar Cambios'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        isEditable
            ? TextFormField(
          controller: controller,
          enabled: isEditable,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            if (isEmail && !value.contains('@')) {
              return 'Ingrese un email válido';
            }
            return null;
          },
        )
            : Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(controller.text),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }
}
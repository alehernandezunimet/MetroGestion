import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil de Usuario"),
      ),
      body: user == null
          ? const Center(child: Text("No hay usuario autenticado"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Correo: ${user.email}"),
                      const SizedBox(height: 10),
                      Text("Rol: ${data?['rol'] ?? 'No definido'}"),
                      const SizedBox(height: 10),
                      Text("Fecha de registro: ${data?['fechaRegistro'] ?? '---'}"),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
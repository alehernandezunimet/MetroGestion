import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:metro_gestion_proyecto/screens/perfil/perfil_estudiante_screen.dart';
import 'package:metro_gestion_proyecto/screens/perfil/perfil_profesor_screen.dart';

Future<void> irAlPerfil(BuildContext context, String uid) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario no encontrado en Firestore")),
      );
      return;
    }

    final rol = doc['rol'];

    if (rol == 'estudiante') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PerfilEstudianteScreen()),
      );
    } else if (rol == 'profesor') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PerfilProfesorScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rol no reconocido")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al cargar perfil: $e")),
    );
  }
}
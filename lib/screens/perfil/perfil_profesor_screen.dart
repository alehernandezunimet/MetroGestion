import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilProfesorScreen extends StatelessWidget {
  const PerfilProfesorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil Profesor")),
      body: const Center(child: Text("Aquí va la info del profesor")),
    );
  }
}
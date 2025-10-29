import 'package:flutter/material.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CAMBIO: AppBar eliminado, ahora está en home_screen.dart
      // appBar: AppBar( ... ),

      // CAMBIO: Centrado para consistencia
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 80,
                  color: Colors.orange,
                ), // Esto ya estaba naranja
                SizedBox(height: 20),
                Text(
                  '¡Aún no tienes proyectos!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Esta es la pantalla donde aparecerán tus proyectos inscritos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

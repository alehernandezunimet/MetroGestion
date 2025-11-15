import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  final String projectId;
  final String projectName;

  const TasksScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tareas: $projectName'), elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment, // Tareas
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              Text(
                'Gestión de Tareas para el Proyecto "$projectName"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Aquí podrás ver, crear y asignar las tareas para este proyecto (ID: $projectId).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Abriendo formulario de Nueva Tarea...'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_box),
                label: const Text('AÑADIR NUEVA TAREA'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

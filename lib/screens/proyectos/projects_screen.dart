import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectsScreen extends StatefulWidget {
  // PASO 1: Aceptamos el rol que nos pasa el home_screen
  final String? userRole;

  const ProjectsScreen({super.key, this.userRole});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // PASO 2: Método para obtener el Stream (flujo de datos) correcto
  Stream<QuerySnapshot> _getProjectsStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      // Devuelve un stream vacío si no hay usuario
      return const Stream.empty(); 
    }

    // Lógica de roles:
    if (widget.userRole == 'profesor') {
      // Profesores: ven proyectos donde son líderes
      return _firestore
          .collection('proyectos')
          .where('liderProyecto', isEqualTo: user.uid)
          .where('estado', isEqualTo: 'activo') // Mostramos solo activos
          .snapshots();
    } else {
      // Estudiantes: ven proyectos donde son miembros
      return _firestore
          .collection('proyectos')
          .where('miembros', arrayContains: user.uid)
          .where('estado', isEqualTo: 'activo') // Mostramos solo activos
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PASO 3: El body ahora es un StreamBuilder dinámico
      body: StreamBuilder<QuerySnapshot>(
        stream: _getProjectsStream(),
        builder: (context, snapshot) {
          // A. Estado de Carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // B. Estado de Error
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error al cargar los proyectos.'));
          }

          // C. Sin datos (lista vacía)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // REUTILIZAMOS TU UI de "Aún no tienes proyectos"
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber, size: 80, color: Colors.orange),
                      SizedBox(height: 20),
                      Text(
                        '¡Aún no tienes proyectos!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aquí aparecerán tus proyectos inscritos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // D. Tenemos datos (Mostrar la lista)
          final projects = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final projectData = projects[index].data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    projectData['nombre'] ?? 'Sin Nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    projectData['descripcion'] ?? 'Sin Descripción',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Próximo paso: navegar al detalle del proyecto
                  },
                ),
              );
            },
          );
        },
      ),

      // PASO 4: El botón flotante solo aparece si es 'profesor'
      floatingActionButton: widget.userRole == 'profesor'
          ? FloatingActionButton(
              onPressed: _mostrarDialogoCrearProyecto,
              tooltip: 'Crear Proyecto',
              child: const Icon(Icons.add),
            )
          : null, // Si no es profesor, no muestra el botón
    );
  }

  // --- MÉTODOS (Sin cambios, los mismos de antes) ---

  void _mostrarDialogoCrearProyecto() {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Crear Nuevo Proyecto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Proyecto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del Proyecto',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Crear'),
              onPressed: () {
                _crearProyecto(
                  nombreController.text,
                  descripcionController.text,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _crearProyecto(String nombre, String descripcion) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    if (nombre.isEmpty || descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre y la descripción no pueden estar vacíos.')),
      );
      return;
    }

    try {
      await _firestore.collection('proyectos').add({
        'nombre': nombre,
        'descripcion': descripcion,
        'liderProyecto': user.uid,
        'miembros': [], // Importante: Por ahora los miembros están vacíos
        'fechaCreacion': FieldValue.serverTimestamp(),
        'estado': 'activo',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyecto creado con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el proyecto: $e')),
      );
    }
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/tareas_screen.dart';

class HitosScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const HitosScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<HitosScreen> createState() => _HitosScreenState();
}

class _HitosScreenState extends State<HitosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddHitoDialog() {
    final TextEditingController nombreController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear Nuevo Hito'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre del Hito'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Ingrese un nombre' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _createHito(nombreController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createHito(String name) async {
    try {
      await _firestore
          .collection('proyectos')
          .doc(widget.projectId)
          .collection('hitos')
          .add({
        'nombre': name,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hito creado con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el hito: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hitos de: ${widget.projectName}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('proyectos')
            .doc(widget.projectId)
            .collection('hitos')
            .orderBy('fechaCreacion', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay hitos creados para este proyecto.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final hitos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: hitos.length,
            itemBuilder: (context, index) {
              final hito = hitos[index];
              final hitoData = hito.data() as Map<String, dynamic>;
              final hitoName = hitoData['nombre'] ?? 'Hito sin nombre';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: Icon(Icons.flag, color: Theme.of(context).primaryColor),
                  title: Text(hitoName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TasksScreen(
                          projectId: widget.projectId,
                          hitoId: hito.id,
                          hitoName: hitoName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHitoDialog,
        icon: const Icon(Icons.add),
        label: const Text('Crear Hito'),
      ),
    );
  }
}
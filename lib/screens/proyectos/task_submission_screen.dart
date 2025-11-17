import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class TaskSubmissionScreen extends StatefulWidget {
  final String projectId;
  final String hitoId;
  final String taskId;

  const TaskSubmissionScreen({
    super.key,
    required this.projectId,
    required this.hitoId,
    required this.taskId,
  });

  @override
  State<TaskSubmissionScreen> createState() => _TaskSubmissionScreenState();
}

class _TaskSubmissionScreenState extends State<TaskSubmissionScreen> {
  final TextEditingController _commentController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadFile(PlatformFile file) async {
    final path = 'submissions/${widget.projectId}/${widget.taskId}/${file.name}';
    final fileOnWeb = File(file.path!);

    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(fileOnWeb);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir el archivo: $e')),
      );
      return null;
    }
  }

  Future<void> _submitDelivery() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      String? fileUrl;
      if (_pickedFile != null) {
        fileUrl = await _uploadFile(_pickedFile!);
        if (fileUrl == null) {
          // Si la subida del archivo falla, detenemos el proceso.
          setState(() => _isSubmitting = false);
          return;
        }
      }

      final submissionData = {
        'comment': _commentController.text.trim(),
        'fileUrl': fileUrl,
        'fileName': _pickedFile?.name,
        'submittedAt': FieldValue.serverTimestamp(),
      };

      // Actualizamos la tarea en Firestore
      await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(widget.projectId)
          .collection('hitos')
          .doc(widget.hitoId)
          .collection('tareas')
          .doc(widget.taskId)
          .update({
        'estado': 'completada',
        'submission': submissionData,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Tarea entregada con éxito!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la entrega: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realizar Entrega')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('proyectos')
            .doc(widget.projectId)
            .collection('hitos')
            .doc(widget.hitoId)
            .collection('tareas')
            .doc(widget.taskId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final taskData = snapshot.data!.data() as Map<String, dynamic>;
          final deadline = taskData['fechaLimite'] as Timestamp?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskData['nombre'] ?? 'Tarea',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (deadline != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Fecha límite: ${DateFormat('dd/MM/yyyy').format(deadline.toDate())}',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(taskData['descripcion'] ?? 'Sin descripción.'),
                const Divider(height: 32),
                const Text(
                  'Tu Entrega',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comentario (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Adjuntar Archivo (Opcional)'),
                ),
                if (_pickedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: Text(_pickedFile!.name),
                      onDeleted: () {
                        setState(() {
                          _pickedFile = null;
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitDelivery,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Enviar Entrega'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
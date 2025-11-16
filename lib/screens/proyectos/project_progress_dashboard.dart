import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class Task {
  final String name;
  final String id;
  final bool isCompleted;

  Task({required this.id, required this.name, this.isCompleted = false});
}

class Hito { // Milestone
  final String name;
  final String id;
  final List<Task> tasks;

  Hito({required this.id, required this.name, required this.tasks});

  /// Calcula el progreso del hito (0.0 a 1.0)
  double get progress {
    if (tasks.isEmpty) {
      return 0.0;
    }
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    return completedTasks / tasks.length;
  }
}

class Project {
  final String name;
  final String id;
  final List<Hito> milestones;

  Project({required this.id, required this.name, required this.milestones});

  /// Calcula el número total de tareas en el proyecto
  int get totalTasks {
    return milestones.fold(0, (sum, hito) => sum + hito.tasks.length);
  }

  /// Calcula el número total de tareas completadas
  int get completedTasks {
    return milestones.fold(0, (sum, hito) {
      return sum + hito.tasks.where((task) => task.isCompleted).length;
    });
  }

  /// Calcula el progreso total del proyecto (0.0 a 1.0)
  double get progress {
    if (totalTasks == 0) {
      return 0.0;
    }
    return completedTasks / totalTasks;
  }
}

// --- WIDGET DEL DASHBOARD ---

class ProjectProgressDashboard extends StatelessWidget {
  final Project project;

  const ProjectProgressDashboard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Progreso General del Proyecto
            _buildProjectProgress(context),

            const Divider(height: 32, thickness: 1),

            // 2. Progreso por Hitos
            _buildMilestonesProgress(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectProgress(BuildContext context) {
    final progressPercent = (project.progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Progreso Total del Proyecto',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        LinearPercentIndicator(
          lineHeight: 20.0,
          percent: project.progress,
          center: Text(
            '$progressPercent%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          barRadius: const Radius.circular(10),
          backgroundColor: Colors.grey[300],
          progressColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Widget _buildMilestonesProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso por Hitos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 20),
        if (project.milestones.isEmpty)
          const Center(
            child: Text('No hay hitos definidos para este proyecto.'),
          )
        else
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.center,
            children: project.milestones.map((hito) {
              final progressPercent = (hito.progress * 100).toStringAsFixed(0);
              return GestureDetector(
                onTap: () => _showHitoTasksDialog(context, hito),
                child: SizedBox(
                  width: 150,
                  child: Column(
                    children: [
                      CircularPercentIndicator(
                        radius: 60.0,
                        lineWidth: 12.0,
                        percent: hito.progress,
                        center: Text(
                          '$progressPercent%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        progressColor: Colors.green,
                        backgroundColor: Colors.grey[300]!,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hito.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showHitoTasksDialog(BuildContext context, Hito hito) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Tareas de: ${hito.name}'),
              content: SizedBox(
                width: double.maxFinite,
                child: hito.tasks.isEmpty
                    ? const Text('Este hito no tiene tareas asignadas.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: hito.tasks.length,
                        itemBuilder: (context, index) {
                          final task = hito.tasks[index];
                          return CheckboxListTile(
                            title: Text(
                              task.name,
                              style: TextStyle(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: task.isCompleted ? Colors.grey : null,
                              ),
                            ),
                            value: task.isCompleted,
                            onChanged: (bool? newValue) async {
                              if (newValue == null) return;

                              // Actualizar en Firestore
                              await _toggleTaskCompletion(
                                project.id,
                                hito.id,
                                task.id,
                                newValue,
                              );

                              // Actualizar la UI del diálogo
                              setDialogState(() {
                                final updatedTask = Task(
                                  id: task.id,
                                  name: task.name,
                                  isCompleted: newValue,
                                );
                                hito.tasks[index] = updatedTask;
                              });
                            },
                            activeColor: Colors.green,
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleTaskCompletion(
    String projectId,
    String hitoId,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(projectId)
          .collection('hitos')
          .doc(hitoId)
          .collection('tareas')
          .doc(taskId)
          .update({'estado': isCompleted ? 'completada' : 'pendiente'});
    } catch (e) {
      // Manejar el error si es necesario, por ejemplo, mostrando un SnackBar
    }
  }
}
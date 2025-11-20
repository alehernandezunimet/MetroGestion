import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarioScreen extends StatefulWidget {
  final String userRole;

  const CalendarioScreen({super.key, required this.userRole});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configuración del Calendario
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Aquí guardaremos los eventos agrupados por día
  // Map<Fecha, Lista de Eventos>
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _cargarEventosDesdeFirebase();
  }

  // --- LÓGICA: Extraer fechas de Proyectos y Tareas ---
  Future<void> _cargarEventosDesdeFirebase() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Variable temporal para armar el calendario
    Map<DateTime, List<Map<String, dynamic>>> tempEvents = {};

    try {
      // 1. Definir qué proyectos buscar según el rol
      Query queryProyectos;
      if (widget.userRole == 'profesor') {
        // Profesor: Proyectos donde es líder
        queryProyectos = _firestore
            .collection('proyectos')
            .where('liderProyecto', isEqualTo: uid)
            .where('estado', isEqualTo: 'activo');
      } else {
        // Estudiante: Proyectos donde es miembro
        queryProyectos = _firestore
            .collection('proyectos')
            .where('miembros', arrayContains: uid)
            .where('estado', isEqualTo: 'activo');
      }

      // Ejecutamos la consulta
      final proyectosSnapshot = await queryProyectos.get();

      // Recorremos cada proyecto encontrado
      for (var doc in proyectosSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final projectId = doc.id;

        // --- A. AGREGAR FECHA DE ENTREGA DEL PROYECTO ---
        if (data['fechaEntrega'] != null) {
          DateTime fecha = (data['fechaEntrega'] as Timestamp).toDate();
          // Normalizamos la fecha (quitamos la hora) para que coincida con el calendario
          DateTime fechaNormalizada = DateTime(fecha.year, fecha.month, fecha.day);
          
          if (tempEvents[fechaNormalizada] == null) {
            tempEvents[fechaNormalizada] = [];
          }
          
          tempEvents[fechaNormalizada]!.add({
            'titulo': 'Entrega Proyecto: ${data['nombre']}',
            'tipo': 'proyecto', // Para ponerlo rojo
            'color': Colors.red,
          });
        }

        // --- B. BUSCAR TAREAS DENTRO DE ESTE PROYECTO ---
        // (Buscamos en la subcolección hitos -> tareas)
        final hitosSnapshot = await doc.reference.collection('hitos').get();
        
        for (var hito in hitosSnapshot.docs) {
          final tareasSnapshot = await hito.reference.collection('tareas').get();
          
          for (var tarea in tareasSnapshot.docs) {
            final tareaData = tarea.data();
            
            // Solo nos importan las tareas pendientes con fecha límite
            if (tareaData['fechaLimite'] != null && tareaData['estado'] == 'pendiente') {
              DateTime fecha = (tareaData['fechaLimite'] as Timestamp).toDate();
              DateTime fechaNormalizada = DateTime(fecha.year, fecha.month, fecha.day);

              if (tempEvents[fechaNormalizada] == null) {
                tempEvents[fechaNormalizada] = [];
              }

              tempEvents[fechaNormalizada]!.add({
                'titulo': 'Tarea: ${tareaData['nombre']}',
                'tipo': 'tarea', // Para ponerlo naranja
                'color': Colors.orange,
              });
            }
          }
        }
      }

      // Actualizamos la pantalla con los datos encontrados
      if (mounted) {
        setState(() {
          _events = tempEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando calendario: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper para obtener eventos de un día específico
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario Académico')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. EL CALENDARIO
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  
                  // Estilos Visuales
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.red, // Color por defecto de los puntos
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Interacción
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  
                  // AQUÍ SE CARGAN LOS PUNTITOS
                  eventLoader: _getEventsForDay,
                ),
                
                const SizedBox(height: 8.0),
                const Divider(thickness: 2),
                const SizedBox(height: 8.0),
                
                // Título de la lista
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Eventos para el ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}:',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),

                // 2. LA LISTA DE EVENTOS DEL DÍA
                Expanded(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: ValueNotifier(_getEventsForDay(_selectedDay!)),
                    builder: (context, value, _) {
                      if (value.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available, size: 50, color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              const Text('No hay entregas para este día.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: value.length,
                        itemBuilder: (context, index) {
                          final evento = value[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: 2,
                            child: ListTile(
                              leading: Icon(
                                Icons.circle, 
                                size: 16,
                                color: evento['color'], // Rojo o Naranja
                              ),
                              title: Text(
                                evento['titulo'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                evento['tipo'] == 'proyecto' ? 'Entrega Final' : 'Tarea Pendiente',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
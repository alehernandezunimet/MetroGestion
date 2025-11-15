import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metro_gestion_proyecto/screens/login/login_screen.dart';
import 'package:metro_gestion_proyecto/screens/perfil/perfil_profesor_screen.dart';
import 'package:metro_gestion_proyecto/screens/perfil/perfil_screen.dart';
import 'package:metro_gestion_proyecto/screens/proyectos/projects_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  String? _userEmail;
  String? _userName;
  bool _isLoading = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user == null) {
      _redirectToLogin();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userRole = doc.data()?['rol'];
          final String nombre = doc.data()?['nombre'] ?? '';
          final String apellido = doc.data()?['apellido'] ?? '';
          _userName = nombre.isNotEmpty && apellido.isNotEmpty
              ? '$nombre $apellido'
              : nombre.isNotEmpty
              ? nombre
              : 'Usuario';

          _userEmail = user!.email;
          _isLoading = false;
        });
      } else {
        _redirectToLogin();
      }
    } catch (e) {
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onProfileUpdated() {
    _fetchUserData();
  }

  // --- WIDGET: Construye el menú lateral (Drawer) ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              _userName ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(_userEmail ?? 'No disponible'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          // Opciones de navegación
          _buildDrawerItem(0, Icons.dashboard, 'Inicio'),
          _buildDrawerItem(1, Icons.work, 'Proyectos'),
          _buildDrawerItem(
            2,
            Icons.person,
            _userRole == 'profesor' ? 'Perfil' : 'Mi Perfil',
          ),

          const Divider(),

          // Opción de Cerrar Sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              _redirectToLogin();
            },
          ),
        ],
      ),
    );
  }

  // Helper para construir los ítems del Drawer
  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index
            ? Theme.of(context).primaryColor
            : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: _selectedIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
          color: _selectedIndex == index
              ? Theme.of(context).primaryColor
              : Colors.black87,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        Navigator.of(context).pop();
        _onItemTapped(index);
      },
    );
  }

  // --- Widgets de navegación para el body ---
  Widget _getBodyWidget() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardBody();
      case 1:
        return ProjectsScreen(userRole: _userRole);
      case 2:
        if (_userRole == 'profesor') {
          return PerfilProfesorScreen(
            userEmail: _userEmail,
            userRole: _userRole,
            userName: _userName,
            onProfileUpdated: _onProfileUpdated,
          );
        } else {
          return ProfileScreen(
            userEmail: _userEmail,
            userRole: _userRole,
            userName: _userName,
            onProfileUpdated: _onProfileUpdated,
          );
        }
      default:
        return const Center(child: Text('Pantalla no encontrada'));
    }
  }

  // --- DASHBOARD BODY (NUEVO DISEÑO) ---
  Widget _buildDashboardBody() {
    final bool isProfessor = _userRole == 'profesor';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BANNER DE BIENVENIDA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSaludo(),
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  _userName?.split(' ')[0] ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isProfessor
                      ? 'Rol: Profesor - Gestor de proyectos'
                      : 'Rol: Estudiante',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // 2. SECCIÓN DE ACCIONES RÁPIDAS
          Padding(
            padding: const EdgeInsets.only(
              top: 24,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),

          ActionListItem(
            title: 'Proyectos',
            subtitle: isProfessor
                ? 'Gestionar equipos y tareas'
                : 'Ver mis asignaciones',
            icon: Icons.work_history,
            iconColor: Colors.deepOrange,
            onTap: () => _onItemTapped(1),
          ),

          ActionListItem(
            title: isProfessor ? 'Perfil de Profesor' : 'Mi Perfil',
            subtitle: 'Actualizar información personal y contactos',
            icon: Icons.person_pin,
            iconColor: Colors.blue,
            onTap: () => _onItemTapped(2),
          ),

          ActionListItem(
            title: 'Cerrar Sesión',
            subtitle: 'Desconectar y salir de la cuenta',
            icon: Icons.logout,
            iconColor: Colors.red,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              _redirectToLogin();
            },
          ),

          // 3. SECCIÓN DE ESTADÍSTICAS (Ejemplo)
          const Padding(
            padding: EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 8),
            child: Text(
              'Estadísticas Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Tarjeta de Proyectos/Tareas (Ejemplo de información)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isProfessor
                              ? 'Proyectos Activos'
                              : 'Tareas Pendientes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isProfessor
                              ? '3'
                              : '8', // **Aquí puedes poner el conteo real de Firestore**
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      isProfessor ? Icons.group_work : Icons.assignment_late,
                      size: 40,
                      color: Colors.amber[700],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- Método de saludo ---
  String _getSaludo() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días';
    } else if (hour < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  // --- ESTRUCTURA PRINCIPAL DEL WIDGET ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('METROGESTIÓN'), actions: const []),
      drawer: _buildDrawer(context),
      body: _getBodyWidget(),
    );
  }
}

// --- WIDGET NUEVO: ActionListItem (Fila de acción) ---
class ActionListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const ActionListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

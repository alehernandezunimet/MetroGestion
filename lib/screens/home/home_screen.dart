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
          _userEmail = user!.email;
          _userName =
              doc.data()?['nombre'] + ' ' + (doc.data()?['apellido'] ?? '');
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
    // Cuando el perfil se actualiza, recargamos los datos
    _fetchUserData();
  }

  // --- Widgets de navegación para el body ---
  Widget _getBodyWidget() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardBody(); // El nuevo widget que contiene el SingleChildScrollView
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

  // --- FUNCIÓN CORREGIDA: Incluye SingleChildScrollView ---
  Widget _buildDashboardBody() {
    final bool isProfessor = _userRole == 'profesor';

    return SingleChildScrollView(
      // <-- SOLUCIÓN AL OVERFLOW
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo
          Text(
            '${_getSaludo()}, ${_userName?.split(' ')[0] ?? 'Usuario'}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isProfessor
                ? 'Bienvenido/a a la gestión de proyectos.'
                : 'Revisa tus proyectos y tareas asignadas.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),

          // Título de sección
          const Text(
            'Acciones Rápidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Grid de Elementos
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 1. Proyectos
              HomeGridItem(
                title: 'Proyectos',
                subtitle: isProfessor
                    ? 'Gestionar proyectos'
                    : 'Ver asignaciones',
                icon: Icons.folder_open,
                iconColor: Colors.deepOrange,
                color: Colors.orange.shade50,
                onTap: () => _onItemTapped(1),
              ),

              // 2. Perfil/Usuarios
              HomeGridItem(
                title: isProfessor ? 'Perfil' : 'Mi Perfil',
                subtitle: 'Actualizar datos',
                icon: Icons.person,
                iconColor: Colors.blue,
                color: Colors.blue.shade50,
                onTap: () => _onItemTapped(2),
              ),

              // 3. Cerrar Sesión (Siempre útil en el Dashboard)
              HomeGridItem(
                title: 'Cerrar Sesión',
                subtitle: 'Desconectar cuenta',
                icon: Icons.logout,
                iconColor: Colors.red,
                color: Colors.red.shade50,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  _redirectToLogin();
                },
              ),

              // Puedes añadir un cuarto elemento aquí si lo deseas.
              // Por ejemplo:
              // HomeGridItem(
              //   title: 'Notificaciones',
              //   subtitle: 'Ver alertas',
              //   icon: Icons.notifications,
              //   iconColor: Colors.green,
              //   color: Colors.green.shade50,
              //   onTap: () {},
              // ),
            ],
          ),

          const SizedBox(height: 40),

          // Puedes añadir un gráfico o lista de tareas pendientes aquí.
          // Ejemplo:
          // Center(
          //   child: Text('Gráfico de progreso aquí (próximamente)'),
          // ),
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

  // --- Estructura principal de la pantalla ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              _redirectToLogin();
            },
          ),
        ],
      ),
      body: _getBodyWidget(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Proyectos',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: _userRole == 'profesor' ? 'Perfil' : 'Mi Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- Widget para las tarjetas del Home ---
class HomeGridItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color color;
  final VoidCallback onTap;

  const HomeGridItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[100]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Texto oscuro
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600], // Texto gris
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

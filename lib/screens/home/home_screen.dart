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
              Navigator.of(context).pop(); // Cierra el Drawer
              await FirebaseAuth.instance.signOut();
              _redirectToLogin();
            },
          ),
        ],
      ),
    );
  }

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

  Widget _getBodyWidget() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardBody(); // Contiene el saludo "Buenos días..."
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

  Widget _buildDashboardBody() {
    final bool isProfessor = _userRole == 'profesor';

    return SingleChildScrollView(
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

          const Text(
            'Acciones Rápidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

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

              // 3. Cerrar Sesión
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
            ],
          ),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('METROGESTIÓN'), actions: const []),
      drawer: _buildDrawer(context),
      body: _getBodyWidget(),
    );
  }
}

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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[100]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  int _selectedIndex = 0; // Controla la pestaña (0=Perfil, 1=Proyectos)
  String? _userRole;
  bool _isLoading = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  // Buscamos el rol para saber qué perfil mostrar
  Future<void> _fetchUserRole() async {
    if (user == null) {
      _logout(context);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userRole = doc['rol'];
          _isLoading = false;
        });
      } else {
        _logout(context);
      }
    } catch (e) {
      _logout(context);
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos los títulos de la AppBar
    final List<String> pageTitles = ['Mi Perfil', 'Mis Proyectos'];

    return Scaffold(
      appBar: AppBar(
        // CAMBIO: El título cambia según la selección
        title: Text(pageTitles[_selectedIndex]),
        automaticallyImplyLeading: false, // Oculta la flecha "atrás"
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              // CAMBIO: Indicador de carga naranja
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : Row(
              children: [
                // --- CAMBIO: Menú Lateral (Estilo Web) ---
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).canvasColor,
                  // CAMBIO: Colores Naranja
                  indicatorColor: Colors.orange.withOpacity(0.2),
                  selectedIconTheme: IconThemeData(color: Colors.orange[800]),
                  selectedLabelTextStyle: TextStyle(color: Colors.orange[800]),
                  unselectedIconTheme: IconThemeData(color: Colors.grey[700]),

                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Perfil'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.folder_outlined),
                      selectedIcon: Icon(Icons.folder),
                      label: Text('Proyectos'),
                    ),
                  ],
                ),

                const VerticalDivider(thickness: 1, width: 1),

                // --- CAMBIO: Contenido principal ---
                Expanded(child: _buildPage(_selectedIndex)),
              ],
            ),
    );
  }

  // Función que decide qué pantalla mostrar en el "Expanded"
  Widget _buildPage(int index) {
    switch (index) {
      case 0: // Perfil
        return _userRole == 'profesor'
            ? const PerfilProfesorScreen()
            : const ProfileScreen();
      case 1: // Proyectos
        return const ProjectsScreen();
      default:
        return const ProfileScreen();
    }
  }
}

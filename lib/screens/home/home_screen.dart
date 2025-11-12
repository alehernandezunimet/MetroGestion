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
          _userRole = doc['rol'];
          _userEmail = user!.email;
          _userName = doc['nombre'] ?? user!.displayName ?? 'Usuario';
          _isLoading = false;
        });
      } else {
        setState(() {
          _userRole = 'estudiante';
          _userEmail = user!.email;
          _userName = user!.displayName ?? 'Usuario';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userRole = 'estudiante';
        _userEmail = user!.email;
        _userName = user!.displayName ?? 'Usuario';
        _isLoading = false;
      });
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
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
    if (user == null && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToLogin();
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<String> pageTitles = ['Inicio', 'Mi Perfil', 'Mis Proyectos'];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange, // Color sólido
        foregroundColor: Colors.white, // Texto blanco para contraste
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.orange, // Color sólido
        ),
      )
          : Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.grey[50],
            indicatorColor: Colors.orange.withOpacity(0.3), // Naranja con transparencia
            selectedIconTheme: const IconThemeData(color: Colors.orange), // Color sólido
            selectedLabelTextStyle: const TextStyle(
              color: Colors.orange, // Color sólido
              fontWeight: FontWeight.bold,
            ),
            unselectedIconTheme: IconThemeData(color: Colors.grey[600]),
            unselectedLabelTextStyle: TextStyle(color: Colors.grey[600]),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Inicio'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outlined),
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

          Expanded(child: _buildPage(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildHomePage();
      case 1:
        return _userRole == 'profesor'
            ? PerfilProfesorScreen(
          userEmail: _userEmail,
          userRole: _userRole,
          userName: _userName,
          onProfileUpdated: _fetchUserData,
        )
            : ProfileScreen(
          userEmail: _userEmail,
          userRole: _userRole,
          userName: _userName,
          onProfileUpdated: _fetchUserData,
        );
      case 2:
        return const ProjectsScreen();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    String saludo = _getSaludo();
    String rolTexto = _userRole == 'profesor' ? 'Profesor/a' : 'Estudiante';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange,
                  child: Text(
                    _userName!.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$saludo,',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _userName!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        rolTexto,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Tarjeta de bienvenida
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange[100]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.rocket_launch,
                      size: 40,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bienvenido/a al Sistema de\nGestión de Proyectos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestiona tus proyectos académicos de manera eficiente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),


            const Text(
              'Accesos Rápidos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),


            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.person,
                    title: 'Mi Perfil',
                    subtitle: 'Gestiona tu información',
                    color: Colors.orange[50]!,
                    iconColor: Colors.orange,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.folder,
                    title: 'Proyectos',
                    subtitle: 'Ver mis proyectos',
                    color: Colors.orange[50]!,
                    iconColor: Colors.orange,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange[100]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: iconColor,
              ),
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
}
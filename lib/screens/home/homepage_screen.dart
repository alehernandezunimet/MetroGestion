import 'package:flutter/material.dart';
import 'package:metro_gestion_proyecto/screens/login/login_screen.dart';
import 'package:metro_gestion_proyecto/register/register_screen.dart';

class HomePageScreen extends StatelessWidget {
  const HomePageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo de pantalla
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/imagen/fondo_homepage.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(color: Colors.black.withOpacity(0.3)),

          Column(
            children: [
              // Barra de navegación superior MODIFICADA
              _buildNavBar(context),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Botón de acceso
                      Align(
                        alignment: Alignment.topRight,
                        child: ElevatedButton(
                          onPressed: () {
                            _showAccessMenu(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'ACCESO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Título
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'METROGESTIÓN',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Sistema de Gestión de Proyectos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Laboratorios de Ingeniería - UNIMET',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Barra de navegación superior MODIFICADA
  Widget _buildNavBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo de la universidad y nombre
          Row(
            children: [
              // Logo de la universidad
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Image.asset(
                  'assets/imagen/unimet.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'UNIMET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNIVERSIDAD METROPOLITANA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Laboratorios de Ingeniería',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Menús de navegación SIMPLIFICADOS (sin Consultorías ni Laboratorios)
          Row(
            children: [
              // Menú Proyectos
              _buildProjectsMenu(context),

              const SizedBox(width: 15),

              // Menú Recursos
              _buildRecursosMenu(context),

              const SizedBox(width: 15),

              // Menú Roles
              _buildRolesMenu(context),

              const SizedBox(width: 15),

              // Sobre Nosotros (sin menú desplegable)
              _buildAboutUsButton(context),

              const SizedBox(width: 15),

              // Soporte (con menú desplegable)
              _buildSupportMenu(context),
            ],
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS PARA LOS MENÚS ==========

  // Menú desplegable de Proyectos
  Widget _buildProjectsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 45),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'nuevo_proyecto',
          child: Row(
            children: [
              Icon(Icons.add_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Nuevo Proyecto'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'proyectos_activos',
          child: Row(
            children: [
              Icon(Icons.assignment, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Proyectos Activos'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'en_curso',
          child: Row(
            children: [
              Icon(Icons.autorenew, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('En Curso'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'finalizados',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Finalizados'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'suspendidos',
          child: Row(
            children: [
              Icon(Icons.pause_circle, color: Colors.yellow, size: 20),
              SizedBox(width: 8),
              Text('Suspendidos'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'info_proyectos',
          enabled: false,
          child: Text(
            'Inicia sesión para gestionar proyectos',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
      onSelected: (String value) {
        _handleProjectsMenuSelection(value, context);
      },
      child: _buildNavItem('Proyectos', Icons.work_outline),
    );
  }

  // Menú desplegable de Recursos
  Widget _buildRecursosMenu(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 45),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'equipos',
          child: Row(
            children: [
              Icon(Icons.computer, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Equipos'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'personal',
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Personal'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'presupuestos',
          child: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Presupuestos'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'reportes',
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text('Reportes'),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        _handleRecursosMenuSelection(value, context);
      },
      child: _buildNavItem('Recursos', Icons.assignment_turned_in),
    );
  }

  // Menú desplegable de Roles
  Widget _buildRolesMenu(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 45),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'director',
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Director de Laboratorio'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'investigador',
          child: Row(
            children: [
              Icon(Icons.biotech, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text('Investigador'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'profesor',
          child: Row(
            children: [
              Icon(Icons.school, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Profesor'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'estudiante',
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Estudiante'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'cliente',
          child: Row(
            children: [
              Icon(Icons.business, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Cliente Externo'),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        _handleRolesMenuSelection(value, context);
      },
      child: _buildNavItem('Roles', Icons.people_outline),
    );
  }

  // Botón "Sobre Nosotros" (sin menú desplegable)
  Widget _buildAboutUsButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showAboutUsDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.orange),
            SizedBox(width: 6),
            Text(
              'Sobre Nosotros',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menú desplegable de Soporte
  Widget _buildSupportMenu(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 45),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'contacto',
          child: Row(
            children: [
              Icon(Icons.contact_support, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Contacto'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'faq',
          child: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Preguntas Frecuentes'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'manual',
          child: Row(
            children: [
              Icon(Icons.menu_book, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text('Manual de Usuario'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'reportar_problema',
          child: Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Reportar Problema'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'email',
          child: Row(
            children: [
              Icon(Icons.email, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text('soporte@unimet.edu.ve'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'telefono',
          child: Row(
            children: [
              Icon(Icons.phone, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text('+58 212-555-1234'),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        _handleSupportMenuSelection(value, context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.support_agent, size: 16, color: Colors.orange),
            SizedBox(width: 6),
            Text(
              'Soporte',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  // Widget reusable para items de navegación
  Widget _buildNavItem(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.orange),
        ],
      ),
    );
  }

  // ========== MANEJADORES DE SELECCIÓN ==========

  // Manejar selección del menú Proyectos
  void _handleProjectsMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'nuevo_proyecto':
        _showMessage(context, 'Nuevo Proyecto', 'Crear nuevo proyecto de consultoría');
        break;
      case 'proyectos_activos':
        _showMessage(context, 'Proyectos Activos', 'Ver proyectos activos');
        break;
      case 'en_curso':
        _showMessage(context, 'Proyectos en Curso', 'Proyectos en ejecución');
        break;
      case 'finalizados':
        _showMessage(context, 'Proyectos Finalizados', 'Proyectos completados');
        break;
      case 'suspendidos':
        _showMessage(context, 'Proyectos Suspendidos', 'Proyectos en pausa');
        break;
    }
  }

  // Manejar selección del menú Recursos
  void _handleRecursosMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'equipos':
        _showMessage(context, 'Gestión de Equipos', 'Control de equipos de laboratorio');
        break;
      case 'personal':
        _showMessage(context, 'Gestión de Personal', 'Administración del equipo de trabajo');
        break;
      case 'presupuestos':
        _showMessage(context, 'Presupuestos', 'Control de presupuestos de proyectos');
        break;
      case 'reportes':
        _showMessage(context, 'Reportes', 'Generación de reportes y estadísticas');
        break;
    }
  }

  // Manejar selección del menú Roles
  void _handleRolesMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'director':
        _showMessage(context, 'Director de Laboratorio', 'Rol con acceso completo al sistema');
        break;
      case 'investigador':
        _showMessage(context, 'Investigador', 'Acceso a proyectos y datos de investigación');
        break;
      case 'profesor':
        _showMessage(context, 'Profesor', 'Gestión de proyectos académicos');
        break;
      case 'estudiante':
        _showMessage(context, 'Estudiante', 'Participación en proyectos');
        break;
      case 'cliente':
        _showMessage(context, 'Cliente Externo', 'Seguimiento de proyectos contratados');
        break;
    }
  }

  // Manejar selección del menú Soporte
  void _handleSupportMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'contacto':
        _showContactDialog(context);
        break;
      case 'faq':
        _showMessage(context, 'Preguntas Frecuentes', 'Accediendo a las preguntas frecuentes...');
        break;
      case 'manual':
        _showMessage(context, 'Manual de Usuario', 'Descargando manual de usuario...');
        break;
      case 'reportar_problema':
        _showReportProblemDialog(context);
        break;
      case 'email':
        _showMessage(context, 'Email de Soporte', 'soporte@unimet.edu.ve');
        break;
      case 'telefono':
        _showMessage(context, 'Teléfono de Soporte', '+58 212-555-1234');
        break;
    }
  }

  // ========== DIÁLOGOS Y MÉTODOS AUXILIARES ==========

  // Diálogo "Sobre Nosotros"
  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.school, color: Colors.orange),
              SizedBox(width: 10),
              Text('Sobre Nosotros'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Laboratorios de Ingeniería UNIMET',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Los Laboratorios de la Facultad de Ingeniería de la Universidad Metropolitana brindan consultoría especializada en:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                _buildBulletPoint('🏭 Calidad ambiental (agua, residuos)'),
                _buildBulletPoint('⚡ Lubricantes y combustibles'),
                _buildBulletPoint('🏗️ Servicios a empresas de construcción'),
                _buildBulletPoint('🔬 Diseño, construcción e inspección de obras'),
                const SizedBox(height: 15),
                const Text(
                  'Misión:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Proporcionar servicios de consultoría especializada y formar profesionales en el área de ingeniería mediante la investigación y desarrollo tecnológico.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Visión:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Ser el centro de referencia nacional en consultoría técnica y formación de ingenieros de excelencia.',
                ),
                const SizedBox(height: 15),
                const Divider(),
                const Text(
                  'Sistema METROGESTIÓN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const Text(
                  'Desarrollado para el control y gestión eficiente de proyectos generados por las consultorías realizadas por los laboratorios.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Widget para puntos de lista
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // Diálogo de Contacto
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.contact_support, color: Colors.blue),
              SizedBox(width: 10),
              Text('Contacto y Soporte'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laboratorios de Ingeniería UNIMET',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('📍 Universidad Metropolitana'),
              Text('   Caracas, Venezuela'),
              SizedBox(height: 10),
              Text('📞 Teléfono: +58 212-555-1234'),
              Text('📧 Email: soporte@unimet.edu.ve'),
              SizedBox(height: 10),
              Text('🕒 Horario de atención:'),
              Text('   Lunes a Viernes: 8:00 AM - 5:00 PM'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo para Reportar Problema
  void _showReportProblemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red),
              SizedBox(width: 10),
              Text('Reportar Problema'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Por favor describe el problema que has encontrado:'),
              SizedBox(height: 10),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe el problema aquí...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showMessage(context, 'Problema Reportado', 'Hemos recibido tu reporte. Te contactaremos pronto.');
              },
              child: const Text('Enviar Reporte'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar mensaje temporal
  void _showMessage(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // --- Menú inferior que aparece al presionar "ACCESO" ---
  void _showAccessMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 16,
            children: <Widget>[
              const Text(
                'Acceso al Sistema',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24, width: double.infinity),

              // Botón para ir a Login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Iniciar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              // Botón para ir a Registro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text(
                    'Crear Cuenta',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
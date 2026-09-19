import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Datos simulados globales de Alumnos (Características completas)
  final List<Map<String, dynamic>> _students = [
    {
      'nombre': 'Ana García Solís',
      'gpa': 9.8,
      'sexo': 'Femenino',
      'ingles': true,
      'mod': 'Residencias',
      'correo': 'ana.garcia@tesoem.edu.mx',
      'habilidades': ['Flutter', 'Dart', 'Firebase']
    },
    {
      'nombre': 'Carlos Ruiz Mendoza',
      'gpa': 8.5,
      'sexo': 'Masculino',
      'ingles': false,
      'mod': 'Servicio Social',
      'correo': 'carlos.ruiz@tesoem.edu.mx',
      'habilidades': ['Java', 'SQL', 'Git']
    },
    {
      'nombre': 'María López Hernández',
      'gpa': 9.2,
      'sexo': 'Femenino',
      'ingles': true,
      'mod': 'Recién Egresado',
      'correo': 'maria.lopez@tesoem.edu.mx',
      'habilidades': ['Python', 'Data Science']
    },
  ];

  // Datos simulados globales de Empresas
  final List<Map<String, dynamic>> _companies = [
    {'nombre': 'Intellect Systems México', 'rfc': 'ISM120423AA1', 'rubro': 'Desarrollo de Software', 'ubicacion': 'CDMX / Remoto', 'estado': 'Pendiente'},
    {'nombre': 'Consultoría Oriente S.A.', 'rfc': 'COR090815B23', 'rubro': 'Infraestructura y Redes', 'ubicacion': 'Chalco, EdoMex', 'estado': 'Pendiente'},
    {'nombre': 'Tech Solutions TESOEM', 'rfc': 'TST180512XYZ', 'rubro': 'Innovación Tecnológica', 'ubicacion': 'La Paz, EdoMex', 'estado': 'Aprobada'},
  ];

  // Reportes de vacantes
  final List<Map<String, dynamic>> _reportedVacancies = [
    {
      'id': 'v1',
      'puesto': 'Desarrollador Sin Pago C++',
      'empresa': 'Startup Incierta',
      'motivo': 'No ofrece apoyo económico mínimo para residencias',
    },
    {
      'id': 'v2',
      'puesto': 'Asistente de Cafetería',
      'empresa': 'Comidas Rápidas S.A.',
      'motivo': 'No corresponde al perfil de Ingeniería en Sistemas',
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _approveCompany(int index) {
    setState(() {
      _companies[index]['estado'] = 'Aprobada';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Empresa "${_companies[index]['nombre']}" aprobada institucionalmente.'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _removeVacancy(String id, String title) {
    setState(() {
      _reportedVacancies.removeWhere((v) => v['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Vacante "$title" dada de baja con éxito.'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Panel de Control Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Alumnos'),
            Tab(icon: Icon(Icons.business), text: 'Empresas'),
            Tab(icon: Icon(Icons.gavel), text: 'Moderación'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsTab(),
          _buildCompaniesTab(),
          _buildModerationTab(),
        ],
      ),
    );
  }

  // PESTAÑA 1: VISUALIZAR CARACTERÍSTICAS DE ALUMNOS (RF 9.1.13)
  Widget _buildStudentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final s = _students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      child: Text(s['nombre'][0], style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(s['correo'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
                      child: Text('Promedio: ${s['gpa']}', style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const Divider(height: 24),
                Text('Modalidad Actual: ${s['mod']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('Idioma Inglés: ${s['ingles'] ? "✅ Fluido / Acreditado" : "❌ Básico"}', style: TextStyle(color: s['ingles'] ? AppTheme.primaryGreen : Colors.grey)),
                const SizedBox(height: 8),
                const Text('Habilidades declaradas:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: (s['habilidades'] as List<String>).map((h) {
                    return Chip(
                      label: Text(h, style: const TextStyle(fontSize: 11)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // PESTAÑA 2: VISUALIZAR Y VALIDAR CARACTERÍSTICAS DE EMPRESAS (RF 9.1.13)
  Widget _buildCompaniesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _companies.length,
      itemBuilder: (context, index) {
        final c = _companies[index];
        final isApproved = c['estado'] == 'Aprobada';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(c['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c['estado'] as String,
                        style: TextStyle(color: isApproved ? AppTheme.primaryGreen : Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    )
                  ],
                ),
                const Divider(height: 20),
                Text('RFC Comercial: ${c['rfc']}', style: const TextStyle(fontSize: 13)),
                Text('Giro / Rubro: ${c['rubro']}', style: const TextStyle(fontSize: 13)),
                Text('Ubicación Matriz: ${c['ubicacion']}', style: const TextStyle(fontSize: 13)),
                if (!isApproved) ...[
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _approveCompany(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.verified, size: 16, color: Colors.white),
                      label: const Text('Validar y Dar de Alta', style: TextStyle(fontSize: 13, color: Colors.white)),
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  // PESTAÑA 3: MODERACIÓN DE PUBLICACIONES (RF 9.1.14)
  Widget _buildModerationTab() {
    return _reportedVacancies.isEmpty
        ? const Center(child: Text('No hay publicaciones reportadas.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _reportedVacancies.length,
            itemBuilder: (context, index) {
              final v = _reportedVacancies[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(v['puesto'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Empresa: ${v['empresa']}\nMotivo: ${v['motivo']}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _removeVacancy(v['id'] as String, v['puesto'] as String),
                  ),
                ),
              );
            },
          );
  }
}

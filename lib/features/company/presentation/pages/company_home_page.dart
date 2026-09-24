import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';
import 'package:red_teso/core/widgets/notification_bell.dart';

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  double _minGpa = 7.0;
  String _filterGender = 'Todos';
  bool _requireEnglish = false;
  String _filterModality = 'Todos';

  void _resetFilters() {
    setState(() {
      _minGpa = 7.0;
      _filterGender = 'Todos';
      _requireEnglish = false;
      _filterModality = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buscador de Talento', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          const NotificationBell(color: AppTheme.primaryGreen),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Filtros (Igual a la anterior pero conectada a la lógica)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Promedio mínimo: ${_minGpa.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _minGpa,
                    min: 7.0, max: 10.0, divisions: 30,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) => setState(() => _minGpa = val),
                  ),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Solo Mujeres'),
                        selected: _filterGender == 'Femenino',
                        onSelected: (val) => setState(() => _filterGender = val ? 'Femenino' : 'Todos'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Inglés'),
                        selected: _requireEnglish,
                        onSelected: (val) => setState(() => _requireEnglish = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // LISTADO REAL-TIME DESDE FIRESTORE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('users').where('type', isEqualTo: 'alumno').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error de conexión'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final students = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final matchesGpa = (data['gpa'] ?? 0.0) >= _minGpa;
                  final matchesGender = _filterGender == 'Todos' || data['gender'] == _filterGender;
                  final matchesEnglish = !_requireEnglish || (data['speaksEnglish'] ?? false);
                  final matchesModality = _filterModality == 'Todos' || data['modality'] == _filterModality;
                  return matchesGpa && matchesGender && matchesEnglish && matchesModality;
                }).toList();

                if (students.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  itemCount: students.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final data = students[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(data['name'][0])),
                        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${data['modality']} | GPA: ${data['gpa']}'),
                        trailing: (data['speaksEnglish'] ?? false) 
                          ? const Icon(Icons.g_translate, color: Colors.blue, size: 18) 
                          : null,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentDetailViewPage(student: data))),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search, size: 60, color: Colors.grey),
          const Text('No hay alumnos registrados con esos filtros'),
          TextButton(onPressed: _resetFilters, child: const Text('Restablecer búsqueda')),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/student/presentation/pages/vacancy_detail_page.dart';
import 'package:red_teso/core/widgets/notification_bell.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('RedTESO Estudiante', style: TextStyle(fontWeight: FontWeight.bold)),
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
        children: [
          _buildStudentHeader(user?.uid),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar vacantes o empresas...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),

          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['Todos', 'Servicio Social', 'Residencias', 'Empleo Egresados']
                  .map((cat) => _buildCategoryChip(cat))
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('vacancies').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final vacancies = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final matchesCat = _selectedCategory == 'Todos' || data['tipo'] == _selectedCategory;
                  final matchesSearch = data['puesto'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
                  return matchesCat && matchesSearch;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: vacancies.length,
                  itemBuilder: (context, index) {
                    final data = vacancies[index].data() as Map<String, dynamic>;
                    return _buildVacancyCard({...data, 'id': vacancies[index].id});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader(String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox(height: 100);
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Text(data['name']?[0] ?? 'U', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Usuario', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Ing. Sistemas Computacionales', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text(data['gpa']?.toString() ?? '0.0', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const Text('Promedio', style: TextStyle(color: Colors.white60, fontSize: 8)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progreso Académico', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('75%', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.75,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category, style: TextStyle(color: isSelected ? Colors.white : AppTheme.primaryGreen, fontSize: 12)),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedCategory = category),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryGreen,
        shape: StadiumBorder(side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.2))),
      ),
    );
  }

  Widget _buildVacancyCard(Map<String, dynamic> v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.business, color: AppTheme.primaryGreen),
        ),
        title: Text(v['puesto'] ?? 'Vacante', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${v['empresa'] ?? 'Empresa'} • ${v['ubicacion'] ?? 'Remoto'}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VacancyDetailPage(vacancy: v))),
      ),
    );
  }
}

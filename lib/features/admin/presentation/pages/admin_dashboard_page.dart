import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/core/widgets/notification_bell.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<void> _approveCompany(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({'status': 'Aprobada'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empresa aprobada institucionalmente.'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      debugPrint('Error al aprobar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin RedTESO', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: Column(
        children: [
          // Resumen de Métricas Reales (Conectado a Firestore)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildCountCard('Alumnos', 'users', 'type', 'alumno', Icons.people, Colors.blue),
                const SizedBox(width: 8),
                _buildCountCard('Empresas', 'users', 'type', 'empresa', Icons.business, AppTheme.primaryGreen),
                const SizedBox(width: 8),
                _buildCountCard('Vacantes', 'vacancies', null, null, Icons.layers, Colors.orange),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRealTimeList('alumno'),
                _buildRealTimeList('empresa'),
                _buildModerationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget que cuenta documentos en tiempo real
  Widget _buildCountCard(String label, String collection, String? field, String? value, IconData icon, Color color) {
    Query query = _db.collection(collection);
    if (field != null && value != null) {
      query = query.where(field, isEqualTo: value);
    }

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          String count = '...';
          if (snapshot.hasData) {
            count = snapshot.data!.docs.length.toString();
          }
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRealTimeList(String userType) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').where('type', isEqualTo: userType).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error al cargar datos'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;
        if (users.isEmpty) return Center(child: Text('No hay ${userType}s registrados.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final String uid = users[index].id;
            final bool isApproved = data['status'] == 'Aprobada';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Text(data['name']?[0] ?? '?', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ),
                title: Text(data['name'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(userType == 'alumno' 
                  ? '${data['modality']} | GPA: ${data['gpa']}'
                  : 'RFC: ${data['rfc'] ?? 'N/A'}'),
                trailing: userType == 'empresa' && !isApproved
                  ? IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.orange),
                      onPressed: () => _approveCompany(uid),
                    )
                  : (isApproved ? const Icon(Icons.verified, color: AppTheme.primaryGreen) : null),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModerationTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('vacancies').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final vacancies = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vacancies.length,
          itemBuilder: (context, index) {
            final v = vacancies[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.layers, color: AppTheme.primaryGreen),
                title: Text(v['puesto'] ?? 'Vacante', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Empresa: ${v['empresa']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => _db.collection('vacancies').doc(vacancies[index].id).delete(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

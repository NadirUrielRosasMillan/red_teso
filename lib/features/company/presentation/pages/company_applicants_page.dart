import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/pages/student_evaluation_page.dart';

class CompanyApplicantsPage extends StatefulWidget {
  const CompanyApplicantsPage({super.key});

  @override
  State<CompanyApplicantsPage> createState() => _CompanyApplicantsPageState();
}

class _CompanyApplicantsPageState extends State<CompanyApplicantsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Actualiza el estado de la postulación en la nube (Sincronización total)
  Future<void> _updateStatus(String docId, String newStatus, String studentId) async {
    try {
      await _db.collection('applications').doc(docId).update({'status': newStatus});

      // Enviamos una notificación automática al alumno
      await _db.collection('notifications').add({
        'toUserId': studentId,
        'title': 'Actualización de Postulación',
        'message': 'Tu postulación ha cambiado a estado: $newStatus',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a $newStatus'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Inicia sesión'));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Postulaciones Recibidas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Escuchamos solo las postulaciones dirigidas a esta empresa
        stream: _db.collection('applications')
            .where('companyId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error al cargar datos'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                  const Text('Aún no tienes candidatos postulados.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final app = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final status = app['status'] ?? 'Enviado';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(app['studentName'] ?? 'Alumno', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          _buildStatusBadge(status),
                        ],
                      ),
                      Text('Vacante: ${app['vacancyName']}', style: TextStyle(color: Colors.grey[600])),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _updateStatus(id, 'Rechazado', app['studentId']),
                            child: const Text('DESCARTAR', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateStatus(id, 'Aceptado', app['studentId']),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, minimumSize: const Size(100, 36)),
                            child: const Text('ACEPTAR', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.star_outline, color: Colors.amber),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => StudentEvaluationPage(student: app)),
                              );
                            },
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Aceptado') color = AppTheme.primaryGreen;
    if (status == 'Rechazado') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}

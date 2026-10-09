import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/notification_bell.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/professor/presentation/pages/create_course_page.dart';

class ProfessorDashboardPage extends StatefulWidget {
  const ProfessorDashboardPage({super.key});

  @override
  State<ProfessorDashboardPage> createState() => _ProfessorDashboardPageState();
}

class _ProfessorDashboardPageState extends State<ProfessorDashboardPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Panel de Docente TESOEM 🎓', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          const NotificationBell(color: AppTheme.primaryGreen),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Cerrar Sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateCoursePage()),
        ),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('NUEVO CURSO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner del Profesor
            _buildProfessorHeader(user?.uid),

            const SizedBox(height: 24),

            // Estadísticas rápidas
            Row(
              children: [
                Expanded(child: _buildStatCard('Cursos Activos', '4', Icons.school_outlined, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Empresas Interesadas', '12', Icons.business_outlined, AppTheme.primaryGreen)),
              ],
            ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mis Cursos y Capacitaciones',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateCoursePage()),
                  ),
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 18),
                  label: Text('Crear', style: GoogleFonts.outfit(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stream de cursos creados por el profesor en Firestore
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('courses').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar cursos', style: GoogleFonts.inter()));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.class_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'Aún no has publicado cursos',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Publica capacitaciones ejecutivas para que las empresas de la Red TESOEM las coticen.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateCoursePage()),
                          ),
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          label: Text('PUBLICAR PRIMER CURSO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        )
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildCourseCard(data, docs[index].id);
                  },
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessorHeader(String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? _auth.currentUser?.displayName ?? 'Profesor TESOEM';
        final dept = data['department'] ?? 'División de Ingeniería en Sistemas';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, Color(0xFF4A1222)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                child: Text(
                  name.isNotEmpty ? name[0] : 'P',
                  style: GoogleFonts.outfit(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dept,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Docente Verificado 🎓',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF0F172A))),
                Text(title, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> c, String docId) {
    final title = c['title'] ?? 'Curso';
    final category = c['category'] ?? 'Tecnología';
    final price = c['price'] ?? 'Por cotizar';
    final duration = c['duration'] ?? '40 Horas';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school_rounded, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('$category • $duration', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 4),
                Text(price, style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                tooltip: 'Editar Curso',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateCoursePage(
                        courseData: c,
                        courseId: docId,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                tooltip: 'Eliminar Curso',
                onPressed: () async {
                  await _db.collection('courses').doc(docId).delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Curso "$title" eliminado.'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

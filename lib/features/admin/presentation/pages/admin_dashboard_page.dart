import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/notification_bell.dart';
import 'package:red_teso/core/widgets/liquid_glass_ambient_background.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveUser(String uid, String role) async {
    try {
      await _db.collection('users').doc(uid).update({'status': 'Aprobada'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$role aprobado e incorporado a la Red TESOEM.'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al aprobar: $e');
    }
  }

  DateTime? _getDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Control Escolar & Vinculación 🏛️', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF090D16).withOpacity(0.85),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión Admin',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentColor,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.verified_user_rounded), text: 'Aprobaciones'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Log de Actividad 📊'),
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Alumnos'),
            Tab(icon: Icon(Icons.gavel_rounded), text: 'Moderación'),
          ],
        ),
      ),
      body: LiquidGlassAmbientBackground(
        child: Column(
          children: [
            // Resumen de Métricas Universitarias Reales
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildCountCard('Alumnos', 'users', 'type', 'alumno', Icons.people_outline_rounded, Colors.blueAccent),
                  const SizedBox(width: 8),
                  _buildCountCard('Empresas', 'users', 'type', 'empresa', Icons.business_center_rounded, AppTheme.accentColor),
                  const SizedBox(width: 8),
                  _buildCountCard('Docentes', 'users', 'type', 'profesor', Icons.school_rounded, AppTheme.primaryGreen),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildApprovalsTab(),
                  _buildActivityLogTab(),
                  _buildRealTimeList('alumno'),
                  _buildModerationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          return GlassmorphicCard(
            glowColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(count, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tab 1: Aprobación de Empresas & Validación de Docentes
  Widget _buildApprovalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildShimmerList();

        final docs = snapshot.data!.docs;
        final pendingApprovals = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] ?? data['userType'] ?? '';
          final status = data['status'] ?? 'Pendiente';
          return (type == 'empresa' || type == 'profesor') && status != 'Aprobada';
        }).toList();

        if (pendingApprovals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 54, color: AppTheme.primaryGreen),
                  const SizedBox(height: 12),
                  Text('Todas las solicitudes están al día', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  Text('No hay empresas ni docentes pendientes de validación', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12.5)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingApprovals.length,
          itemBuilder: (context, index) {
            final data = pendingApprovals[index].data() as Map<String, dynamic>;
            final uid = pendingApprovals[index].id;
            final name = data['name'] ?? 'Usuario';
            final type = data['type'] ?? 'empresa';
            final email = data['email'] ?? '';

            return GlassmorphicCard(
              glowColor: type == 'empresa' ? AppTheme.accentColor : AppTheme.primaryGreen,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: type == 'empresa' ? AppTheme.accentColor.withOpacity(0.2) : AppTheme.primaryGreen.withOpacity(0.2),
                    child: Icon(
                      type == 'empresa' ? Icons.business_rounded : Icons.school_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                        Text('$email • $type', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _approveUser(uid, type == 'empresa' ? 'Empresa' : 'Docente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text('APROBAR ✅', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                  ),
                ],
              ),
            ).animate(delay: (index * 70).ms).fadeIn().slideY(begin: 0.15, end: 0);
          },
        );
      },
    );
  }

  /// Tab 2: Log de Actividad en Tiempo Real (Auditoría Universitaria)
  Widget _buildActivityLogTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('activity_logs').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildShimmerList();

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = _getDateTime(aData['timestamp']);
          final bTime = _getDateTime(bData['timestamp']);
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return -1;
          if (bTime == null) return 1;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_toggle_off_rounded, size: 54, color: Colors.white38),
                const SizedBox(height: 12),
                Text('No hay registros de actividad aún', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text('Los movimientos de los usuarios aparecerán aquí en tiempo real', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12.5)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final userName = data['userName'] ?? 'Usuario';
            final action = data['action'] ?? 'Realizó una consulta';
            final details = data['details'] ?? '';
            final userType = data['userType'] ?? 'alumno';
            final status = data['status'] ?? 'Activo';

            String timeStr = 'Reciente';
            final date = _getDateTime(data['timestamp']);
            if (date != null) {
              timeStr = DateFormat('dd/MM HH:mm').format(date);
            }

            return GlassmorphicCard(
              glowColor: status == 'Activo' ? AppTheme.primaryGreen : Colors.grey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white12,
                        child: Text(userName[0], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: status == 'Activo' ? Colors.greenAccent : Colors.grey,
                          border: Border.all(color: const Color(0xFF090D16), width: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(userName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            Text(timeStr, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                        Text('$action • $userType', style: GoogleFonts.inter(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(details, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1, end: 0);
          },
        );
      },
    );
  }

  Widget _buildRealTimeList(String userType) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').where('type', isEqualTo: userType).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildShimmerList();

        final users = snapshot.data!.docs;
        if (users.isEmpty) return Center(child: Text('No hay ${userType}s registrados.', style: GoogleFonts.inter(color: Colors.white)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;

            return GlassmorphicCard(
              glowColor: AppTheme.primaryColor,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: Text(data['name']?[0] ?? '?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Usuario', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                        Text(
                          userType == 'alumno'
                              ? '${data['modality'] ?? 'Sistemas'} | GPA: ${data['gpa'] ?? '8.5'}'
                              : 'RFC: ${data['rfc'] ?? 'N/A'}',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.15, end: 0);
          },
        );
      },
    );
  }

  Widget _buildModerationTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('vacancies').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildShimmerList();
        final vacancies = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vacancies.length,
          itemBuilder: (context, index) {
            final v = vacancies[index].data() as Map<String, dynamic>;
            final id = vacancies[index].id;

            return GlassmorphicCard(
              glowColor: Colors.redAccent,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['puesto'] ?? 'Vacante', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                        Text('Empresa: ${v['empresa'] ?? 'Empresa'}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                    tooltip: 'Eliminar Vacante',
                    onPressed: () => _db.collection('vacancies').doc(id).delete(),
                  ),
                ],
              ),
            ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.15, end: 0);
          },
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.08),
        highlightColor: Colors.white.withOpacity(0.18),
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

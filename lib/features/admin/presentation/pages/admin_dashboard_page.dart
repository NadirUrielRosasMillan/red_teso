import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/liquid_glass_ambient_background.dart';
import 'package:red_teso/features/auth/presentation/pages/login_page.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart'
    as app_auth;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo aprobar: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  DateTime? _getDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF171B27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 34),
        title: Text(
          'Cerrar sesión',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Seguro que deseas salir del panel administrativo?',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.exit_to_app_rounded, size: 18),
            label: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Cerrar Firebase primero: un error de Firestore no debe bloquear la salida.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error cerrando sesión de Firebase: $e');
    }

    if (!mounted) return;

    // Navegación directa al login, sin depender de rutas nombradas.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const _AdminLogoutLoginRedirect(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 78,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5BD78), Color(0xFF9B713A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5BD78).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Color(0xFF17131B),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Control Escolar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 19,
                    ),
                  ),
                  Text(
                    'RED TESOEM  •  Administración',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF090D16).withValues(alpha: 0.96),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton.filledTonal(
              onPressed: _confirmLogout,
              tooltip: 'Cerrar sesión',
              style: IconButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.13),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.25),
                  ),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE5BD78),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFFE5BD78),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.white10,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.verified_user_rounded, size: 19), text: 'Aprobaciones'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 19), text: 'Actividad'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 19), text: 'Alumnos'),
            Tab(icon: Icon(Icons.gavel_rounded, size: 19), text: 'Moderación'),
          ],
        ),
      ),
      body: LiquidGlassAmbientBackground(
        child: Column(
          children: [
            // Resumen de Métricas Universitarias Reales
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
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

  Widget _buildStreamError(Object error, VoidCallback reintentar) {
    debugPrint('Error de Firestore en Control Escolar: $error');

    final mensaje = error is FirebaseException
        ? 'Firebase: ${error.code}'
        : 'Ocurrió un error inesperado.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.orangeAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los datos',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: reintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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
          if (snapshot.hasError) {
            debugPrint('Error al contar $label: ${snapshot.error}');
          }
          final String count = snapshot.hasError
              ? '!'
              : snapshot.hasData
                  ? snapshot.data!.docs.length.toString()
                  : '...';
          return GlassmorphicCard(
            glowColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(count, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: snapshot.hasError ? Colors.orangeAccent : Colors.white)),
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
        if (snapshot.hasError) {
          return _buildStreamError(snapshot.error!, () => setState(() {}));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }

        final docs = snapshot.data?.docs ?? [];
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 0,
                      maxWidth: 124,
                    ),
                    child: ElevatedButton(
                      onPressed: () => _approveUser(
                        uid,
                        type == 'empresa' ? 'Empresa' : 'Docente',
                      ),
                      // Fuerza un tamaño finito y evita heredar un ancho infinito
                      // de ButtonStyle o de las restricciones del Row en Flutter Web.
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        maximumSize: const Size(124, 42),
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                      ),
                      ),
                      child: Text(
                        'APROBAR',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
        if (snapshot.hasError) {
          return _buildStreamError(snapshot.error!, () => setState(() {}));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }

        final docs = (snapshot.data?.docs ?? []).toList();
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
                        child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
        if (snapshot.hasError) {
          return _buildStreamError(snapshot.error!, () => setState(() {}));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }

        final users = snapshot.data?.docs ?? [];
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
                    child: Text(
                      (data['name'] is String && (data['name'] as String).isNotEmpty)
                          ? (data['name'] as String)[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
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
        if (snapshot.hasError) {
          return _buildStreamError(snapshot.error!, () => setState(() {}));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }
        final vacancies = snapshot.data?.docs ?? [];

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


/// Pantalla de destino después de cerrar sesión desde el panel de administración.
class _AdminLogoutLoginRedirect extends StatelessWidget {
  const _AdminLogoutLoginRedirect();

  @override
  Widget build(BuildContext context) => const LoginPage();
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/widgets/theme_toggle_button.dart';
import 'impulsa_create_project_page.dart';
import 'impulsa_modals.dart';
import 'impulsa_models.dart';
import 'impulsa_project_detail_page.dart';

class AgoraImpulsaPage extends StatefulWidget {
  const AgoraImpulsaPage({super.key});

  @override
  State<AgoraImpulsaPage> createState() => _AgoraImpulsaPageState();
}

class _AgoraImpulsaPageState extends State<AgoraImpulsaPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _tab = 0; // 0: Mis Proyectos, 1: Red de Proyectos
  String _query = '';
  String _userName = 'Estudiante TESOEM';
  bool _inactivityAuditRan = false;

  String get _uid => _auth.currentUser?.uid ?? '';
  String get _email =>
      _auth.currentUser?.email?.toLowerCase().trim() ?? 'invitado@agora.local';

  @override
  void initState() {
    super.initState();
    _loadCurrentStudentProfile();
  }

  Future<void> _loadCurrentStudentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = asJsonMap(doc.data());
        setState(() {
          _userName =
              (data['name'] ?? user.displayName ?? _email.split('@').first)
                  .toString();
        });
      }
    } catch (_) {}
  }

  bool _isProjectMember(ImpulsaProject p) {
    if (_uid.isNotEmpty && p.ownerUid == _uid) return true;
    return p.ownerEmail == _email || p.memberEmails.contains(_email);
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ImpulsaPalette.flagGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openCreateProject() async {
    final created = await Navigator.push<ImpulsaProject>(
      context,
      MaterialPageRoute(
        builder: (_) => ImpulsaCreateProjectPage(
          ownerUid: _uid,
          ownerEmail: _email,
          ownerName: _userName,
        ),
      ),
    );
    if (!mounted || created == null) return;

    try {
      await _db.collection('agora_impulsa_projects').add(created.toMap());
      setState(() => _tab = 0);
      _notify('Proyecto "${created.name}" guardado correctamente');
    } catch (e) {
      _notify('Error al guardar en Firestore: $e');
    }
  }

  void _openProjectDetail(ImpulsaProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImpulsaProjectDetailPage(
          projectId: project.id,
          initialProject: project,
          currentUid: _uid,
          currentEmail: _email,
          currentName: _userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);
    final wide = MediaQuery.sizeOf(context).width >= 880;

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('agora_impulsa_projects')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, projectSnap) {
        final allProjects = projectSnap.hasData
            ? projectSnap.data!.docs.map(ImpulsaProject.fromDoc).toList()
            : <ImpulsaProject>[];

        if (projectSnap.hasData && !_inactivityAuditRan) {
          _inactivityAuditRan = true;
          ImpulsaLifecycleService.auditProjectsInactivity(allProjects);
        }

        final filtered = allProjects.where((p) {
          // Los proyectos solicitados o donados se retiran automáticamente de Públicos
          final isPublicVisible =
              p.published && !p.isRequested && !p.isDonated;
          final visible = _tab == 0 ? _isProjectMember(p) : isPublicVisible;
          final searchBlob =
          '${p.name} ${p.subject} ${p.professor} ${p.description} ${p.technologies.join(' ')}'
              .toLowerCase();
          return visible && searchBlob.contains(_query.toLowerCase().trim());
        }).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('agora_impulsa_notifications')
              .where('targetEmail', isEqualTo: _email)
              .snapshots(),
          builder: (context, notifSnap) {
            final myNotifications = notifSnap.hasData
                ? notifSnap.data!.docs
                .map(ImpulsaNotificationItem.fromDoc)
                .toList()
                : <ImpulsaNotificationItem>[];
            myNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final unreadCount = myNotifications.where((n) => !n.read).length;

            return Scaffold(
              backgroundColor: pal.bg,
              appBar: AppBar(
                backgroundColor: pal.card,
                surfaceTintColor: pal.card,
                elevation: 0,
                shape: Border(bottom: BorderSide(color: pal.border)),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: pal.badgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: pal.primary.withValues(alpha: 0.35)),
                      ),
                      child: Icon(Icons.rocket_launch_rounded,
                          color: pal.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'NEXUS IMPULSA',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        fontSize: 16,
                        color: pal.textPrimary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  ThemeToggleButton(color: pal.textPrimary),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Notificaciones 🔔',
                        onPressed: () => showImpulsaNotificationsModal(
                          context: context,
                          notifications: myNotifications,
                          allProjects: allProjects,
                          currentEmail: _email,
                          onOpenProject: _openProjectDetail,
                        ),
                        icon: Icon(Icons.notifications_none_rounded,
                            color: pal.textPrimary),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: ImpulsaPalette.flagGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              body: Row(
                children: [
                  if (wide)
                    Container(
                      width: 245,
                      decoration: BoxDecoration(
                        color: pal.sidebarBg,
                        border: Border(right: BorderSide(color: pal.border)),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'REPOSITORIO ACADÉMICO',
                              style: TextStyle(
                                color: pal.textSecondary,
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sideNavTile(
                            index: 0,
                            label: 'Mis Proyectos 📕',
                            icon: Icons.book_outlined,
                          ),
                          _sideNavTile(
                            index: 1,
                            label: 'Red de Proyectos 📱',
                            icon: Icons.public_rounded,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: pal.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: pal.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: pal.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1220),
                        child: Padding(
                          padding: EdgeInsets.all(wide ? 28 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!wide)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: SegmentedButton<int>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 0,
                                        label: Text('Mis Proyectos 📕'),
                                      ),
                                      ButtonSegment(
                                        value: 1,
                                        label: Text('Red de Proyectos 📱'),
                                      ),
                                    ],
                                    selected: {_tab},
                                    onSelectionChanged: (s) =>
                                        setState(() => _tab = s.first),
                                  ),
                                ),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 14,
                                runSpacing: 14,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _tab == 0
                                            ? 'Mis Proyectos 📕'
                                            : 'Red de Proyectos 📱',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: pal.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _tab == 0
                                            ? 'Proyectos creados por ti o etiquetados a tu correo electrónico.'
                                            : 'Explora repositorios publicados por la comunidad universitaria.',
                                        style: TextStyle(
                                          color: pal.textSecondary,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  FilledButton.icon(
                                    onPressed: _openCreateProject,
                                    icon: const Icon(Icons.add_rounded, color: Colors.black),
                                    label:
                                    const Text('Comenzar Proyecto Nuevo'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                      ImpulsaPalette.buttonGreen,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                onChanged: (s) => setState(() => _query = s),
                                style: TextStyle(color: pal.textPrimary),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.search,
                                      color: pal.textSecondary),
                                  hintText:
                                  'Buscar proyectos por título, tecnología, semestre o asesor...',
                                  hintStyle:
                                  TextStyle(color: pal.textSecondary),
                                  filled: true,
                                  fillColor: pal.card,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: pal.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: pal.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: pal.primary, width: 1.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: projectSnap.connectionState ==
                                    ConnectionState.waiting &&
                                    !projectSnap.hasData
                                    ? Center(
                                  child: CircularProgressIndicator(
                                      color: pal.primary),
                                )
                                    : filtered.isEmpty
                                    ? _buildEmptyState(pal)
                                    : LayoutBuilder(
                                  builder: (ctx, constraints) {
                                    final cols =
                                    constraints.maxWidth >= 900
                                        ? 3
                                        : constraints.maxWidth >=
                                        560
                                        ? 2
                                        : 1;
                                    return GridView.builder(
                                      itemCount: filtered.length,
                                      gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        mainAxisExtent: 285,
                                      ),
                                      itemBuilder: (_, i) =>
                                          _buildProjectCard(
                                              filtered[i], pal),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sideNavTile({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final selected = _tab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? ImpulsaPalette.buttonGreen
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _tab = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: Colors.black, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ImpulsaPalette pal) => Center(
    child: Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_special_outlined, size: 56, color: pal.primary),
          const SizedBox(height: 12),
          Text(
            _tab == 0
                ? 'Aún no tienes proyectos registrados'
                : 'No hay proyectos publicados en la red',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: pal.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tab == 0
                ? 'Pulsa "Comenzar Proyecto Nuevo" para crear y guardar tu repositorio.'
                : 'Cuando los estudiantes publiquen sus proyectos aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: pal.textSecondary, fontSize: 13),
          ),
        ],
      ),
    ),
  );

  Widget _buildProjectCard(ImpulsaProject p, ImpulsaPalette pal) {
    return Container(
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pal.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openProjectDetail(p),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: pal.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (p.isRequested)
                    _statusPill(
                      icon: Icons.hourglass_top_rounded,
                      label: 'Solicitado',
                      color: ImpulsaPalette.flagGreen,
                      bg: ImpulsaPalette.buttonGreen.withValues(alpha: 0.3),
                    )
                  else if (p.isDonated)
                    _statusPill(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Donado',
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFD97706).withValues(alpha: 0.14),
                    )
                  else if (p.published)
                      _statusPill(
                        icon: Icons.public_rounded,
                        label: 'Público',
                        color: pal.primary,
                        bg: pal.badgeBg,
                      )
                    else
                      _statusPill(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Activo',
                        color: pal.primary,
                        bg: pal.badgeBg,
                      ),
                ],
              ),
              if (p.availableForDonation) ...[
                const SizedBox(height: 6),
                _statusPill(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Disponible para donación',
                  color: ImpulsaPalette.flagGreenMid,
                  bg: ImpulsaPalette.buttonGreen.withValues(alpha: 0.3),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                p.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pal.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Desarrollado con:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: pal.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (p.technologies.isEmpty ? ['General'] : p.technologies)
                    .take(3)
                    .map(
                      (tech) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: pal.badgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: pal.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      tech,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: pal.primary,
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
              const Spacer(),
              Divider(color: pal.border, height: 14),
              Row(
                children: [
                  Icon(Icons.school_outlined, size: 15, color: pal.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${p.semester}° Semestre · Avance: ${p.weightedProgressPercent}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: pal.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
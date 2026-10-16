import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:red_teso/core/services/activity_log_service.dart';

class StudentApplicationsPage extends StatelessWidget {
  const StudentApplicationsPage({super.key});

  static const Color _background = Color(0xFFF8F1E8);
  static const Color _wine = Color(0xFF741C3D);
  static const Color _wineLight = Color(0xFF9D3458);
  static const Color _gold = Color(0xFFE6B968);
  static const Color _text = Color(0xFF3A1725);
  static const Color _muted = Color(0xFF75636B);
  static const Color _border = Color(0xFFE8DDE1);
  static const Color _green = Color(0xFF31805A);
  static const Color _blue = Color(0xFF3478B9);
  static const Color _orange = Color(0xFFB77922);
  static const Color _red = Color(0xFFC64B54);

  DateTime? _getDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _isAccepted(String status) {
    return status == 'Interesado' || status == 'Aceptado';
  }

  bool _isInReview(String status) {
    return status == 'En Revisión' || status == 'En Entrevista';
  }

  Future<void> _confirmDeleteApplication(
    BuildContext context,
    String docId,
    String vacancyName,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: Container(
            padding: const EdgeInsets.all(13),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: _red,
              size: 29,
            ),
          ),
          title: Text(
            '¿Eliminar postulación?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _text,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            '¿Quieres eliminar tu postulación para "$vacancyName"? '
            'Esta acción la quitará de tu historial.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _wine,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Eliminar',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(docId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Postulación "$vacancyName" eliminada del historial.',
          ),
          backgroundColor: _wine,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (error) {
      debugPrint('Error al eliminar postulación: $error');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar la postulación. Inténtalo de nuevo.',
          ),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: _wine,
                  size: 48,
                ),
                const SizedBox(height: 15),
                Text(
                  'Inicia sesión para ver tus postulaciones',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: _text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    ActivityLogService.logActivity(action: 'Checó sus postulaciones activas');

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _wine,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: _wine,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis postulaciones',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  Text(
                    'EL SIGUIENTE PASO DE TU CARRERA',
                    style: GoogleFonts.inter(
                      color: _gold,
                      fontSize: 8,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _ApplicationsBackgroundPainter(),
            ),
          ),
          SafeArea(
            top: false,
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('applications')
                  .where('studentId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError();
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _buildLoading();
                }

                final docs = snapshot.data?.docs.toList() ?? [];

                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aDate = _getDateTime(aData['createdAt']);
                  final bDate = _getDateTime(bData['createdAt']);

                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;

                  return bDate.compareTo(aDate);
                });

                int sent = 0;
                int review = 0;
                int accepted = 0;

                for (final doc in docs) {
                  final app = doc.data() as Map<String, dynamic>;
                  final status = (app['status'] ?? 'Enviado').toString();

                  if (_isAccepted(status)) {
                    accepted++;
                  } else if (_isInReview(status)) {
                    review++;
                  } else {
                    sent++;
                  }
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 800;
                    final horizontalPadding = wide ? 30.0 : 18.0;

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1180,
                        ),
                        child: Column(
                          children: [
                            _buildWelcomeHeader(docs.length)
                                .animate()
                                .fadeIn(duration: 350.ms)
                                .slideY(begin: -0.04, end: 0),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                17,
                                horizontalPadding,
                                17,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'Enviadas',
                                      count: sent,
                                      icon: Icons.send_rounded,
                                      color: _wine,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'En revisión',
                                      count: review,
                                      icon: Icons.schedule_rounded,
                                      color: _orange,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'Aceptadas',
                                      count: accepted,
                                      icon: Icons.check_circle_rounded,
                                      color: _green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                0,
                                horizontalPadding,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _wine,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Actividad reciente',
                                          style: GoogleFonts.outfit(
                                            color: _text,
                                            fontWeight: FontWeight.w800,
                                            fontSize: wide ? 23 : 20,
                                          ),
                                        ),
                                        Text(
                                          'Consulta el estado de tus oportunidades.',
                                          style: GoogleFonts.inter(
                                            color: _muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _border),
                                    ),
                                    child: Text(
                                      '${docs.length} ${docs.length == 1 ? 'registro' : 'registros'}',
                                      style: GoogleFonts.inter(
                                        color: _wine,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: docs.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      padding: EdgeInsets.fromLTRB(
                                        horizontalPadding,
                                        0,
                                        horizontalPadding,
                                        120,
                                      ),
                                      itemCount: docs.length,
                                      itemBuilder: (context, index) {
                                        final doc = docs[index];
                                        final app =
                                            doc.data() as Map<String, dynamic>;

                                        return _buildApplicationCard(
                                          context,
                                          doc.id,
                                          app,
                                        )
                                            .animate(
                                              delay:
                                                  (index.clamp(0, 8) * 45).ms,
                                            )
                                            .fadeIn(duration: 300.ms)
                                            .slideY(
                                              begin: 0.04,
                                              end: 0,
                                            );
                                      },
                                    ),
                            ),
                          ],
                        ),
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

  Widget _buildWelcomeHeader(int total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_wineLight, _wine, Color(0xFF4C102B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: _gold.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: _wine.withValues(alpha: 0.15),
            blurRadius: 17,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: _gold.withValues(alpha: 0.7),
              ),
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: _gold,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu camino profesional',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Tu próxima oportunidad puede comenzar hoy.'
                      : 'Tienes $total ${total == 1 ? 'postulación registrada' : 'postulaciones registradas'}.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.school_rounded,
            color: _gold,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _wine.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              color: _text,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> app,
  ) {
    final status = (app['status'] ?? 'Enviado').toString();
    final statusInfo = _getStatusInfo(status);

    final vacancyName = (app['vacancyName'] ?? 'Vacante TESOEM').toString();
    final companyName =
        (app['companyName'] ?? 'Empresa colaboradora').toString();

    final date = _getDateTime(app['createdAt']);
    final dateText = date == null
        ? 'Fecha no disponible'
        : DateFormat('dd/MM/yyyy').format(date);

    final Color statusColor = statusInfo['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _wine.withValues(alpha: 0.065),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 49,
                  height: 49,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_wineLight, _wine],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.business_center_rounded,
                    color: _gold,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vacancyName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(statusInfo),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: _wine,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Fecha de postulación: $dateText',
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDeleteApplication(
                    context,
                    docId,
                    vacancyName,
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: _red,
                    size: 21,
                  ),
                  tooltip: 'Eliminar del historial',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF0F0),
                    padding: const EdgeInsets.all(9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.075),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _getStatusMessage(status),
                      style: GoogleFonts.inter(
                        color: _text,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Interesado':
      case 'Aceptado':
        return {
          'color': _green,
          'icon': Icons.check_circle_rounded,
          'text': 'Aceptado',
        };

      case 'En Entrevista':
        return {
          'color': _blue,
          'icon': Icons.event_available_rounded,
          'text': 'Entrevista',
        };

      case 'En Revisión':
        return {
          'color': _orange,
          'icon': Icons.hourglass_top_rounded,
          'text': 'En revisión',
        };

      case 'Descartado':
      case 'Rechazado':
        return {
          'color': _red,
          'icon': Icons.cancel_rounded,
          'text': 'Descartado',
        };

      default:
        return {
          'color': _wine,
          'icon': Icons.send_rounded,
          'text': 'Enviada',
        };
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Interesado':
      case 'Aceptado':
        return '¡Felicidades! La empresa ha aceptado tu postulación. '
            'Mantente pendiente de las notificaciones.';

      case 'En Entrevista':
        return 'La empresa te ha invitado a una entrevista. '
            'Revisa tus notificaciones para conocer los siguientes pasos.';

      case 'En Revisión':
        return 'Tu postulación está siendo evaluada por el equipo '
            'de reclutamiento de la empresa.';

      case 'Descartado':
      case 'Rechazado':
        return 'En esta ocasión, el proceso para esta vacante ha finalizado. '
            'Puedes explorar otras oportunidades.';

      default:
        return 'Tu postulación ha sido recibida correctamente. '
            'La empresa podrá actualizar el estado durante el proceso.';
    }
  }

  Widget _buildStatusBadge(Map<String, dynamic> info) {
    final color = info['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            info['icon'] as IconData,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            info['text'] as String,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 48),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFE8CF),
                          Color(0xFFFFF8EF),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _gold,
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      color: _wine,
                      size: 47,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tu próxima oportunidad te espera',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: _text,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todavía no tienes postulaciones registradas. '
                    'Explora las vacantes disponibles y encuentra '
                    'una oportunidad para comenzar tu camino profesional.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8CF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: _wine,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar tus postulaciones',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: _text,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Comprueba tu conexión e inténtalo de nuevo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: List.generate(
        3,
        (index) => Shimmer.fromColors(
          baseColor: const Color(0xFFE8DDE1),
          highlightColor: Colors.white,
          child: Container(
            height: 170,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationsBackgroundPainter extends CustomPainter {
  const _ApplicationsBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9F1),
            Color(0xFFF8F0E7),
            Color(0xFFF1E4DD),
          ],
        ).createShader(rect),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x24741C3D);

    canvas.drawCircle(
      Offset(size.width * 0.98, size.height * 0.12),
      size.width * 0.22,
      ringPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.98, size.height * 0.12),
      size.width * 0.28,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x20B47A22),
    );

    final dotPaint = Paint()..color = const Color(0x66B47A22);

    for (int i = 0; i < 24; i++) {
      final x = ((i * 83 + 29) % 997) / 997 * size.width;
      final y = ((i * 137 + 47) % 991) / 991 * size.height;

      canvas.drawCircle(
        Offset(x, y),
        i % 4 == 0 ? 1.8 : 1,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _ApplicationsBackgroundPainter oldDelegate,
  ) {
    return false;
  }
}

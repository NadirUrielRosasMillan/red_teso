import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'impulsa_models.dart';

/// Sección para el Panel de Administrador (Control Escolar -> Donaciones):
/// - Muestra solicitudes listas para liberar (con consenso del equipo dueño).
/// - Muestra solicitudes en proceso de votación por el equipo dueño.
/// - Muestra el historial de proyectos ya donados y liberados.
class ImpulsaAdminProjectsSection extends StatefulWidget {
  const ImpulsaAdminProjectsSection({super.key});

  @override
  State<ImpulsaAdminProjectsSection> createState() =>
      _ImpulsaAdminProjectsSectionState();
}

class _ImpulsaAdminProjectsSectionState
    extends State<ImpulsaAdminProjectsSection> {
  final Set<String> _expandedLetters = <String>{};
  String? _processingRequestId;

  bool _isRequestReadyForAdmin(ImpulsaProject p, ImpulsaRequest req) {
    if (req.status == 'donated' || req.status == 'rejected') return false;
    if (req.status == 'approved_by_team') return true;
    if (p.isRequested && req.status == 'pending') return true;
    // Respaldo por si todos los votos están en 'accept' aunque status no haya cambiado
    if (req.memberVotes.isNotEmpty &&
        req.memberVotes.values.every((v) => v == 'accept')) {
      return true;
    }
    return false;
  }

  Future<void> _executeAdminDonation(
      BuildContext context,
      ImpulsaProject project,
      ImpulsaRequest request,
      ) async {
    if (_processingRequestId != null) return;
    setState(() => _processingRequestId = request.id);

    final db = FirebaseFirestore.instance;

    try {
      // 1. Resolver correos de todos los integrantes del equipo solicitante
      final resolvedApplicants = <ImpulsaMember>[];
      for (final a in request.applicantMembers) {
        String email = a.email.trim().toLowerCase();
        if (email.isEmpty && a.matricula.isNotEmpty) {
          try {
            final snap = await db
                .collection('users')
                .where('matricula', isEqualTo: a.matricula)
                .limit(1)
                .get();
            if (snap.docs.isNotEmpty) {
              email = (snap.docs.first.data()['email'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
            }
          } catch (_) {}
        }
        if (email.isEmpty && a.matricula.isNotEmpty) {
          email = '${a.matricula.toLowerCase()}@tesoem.edu.mx';
        }
        resolvedApplicants.add(ImpulsaMember(name: a.fullName, email: email));
      }

      if (resolvedApplicants.isEmpty) {
        resolvedApplicants.add(
          ImpulsaMember(
            name: request.requesterName,
            email: request.requesterEmail.toLowerCase().trim(),
          ),
        );
      }

      // 2. Crear la copia del proyecto para el equipo solicitante ("Mis proyectos")
      final donatedProject = project.createDonatedProjectForApplicants(
        request,
        resolvedApplicants,
      );
      final newDocRef = await db
          .collection('agora_impulsa_projects')
          .add(donatedProject.toMap());

      // 3. Actualizar el proyecto original a "donado" y retirarlo de "Red de proyectos"
      request.status = 'donated';
      project.status = 'donado';
      project.published = false;
      await db
          .collection('agora_impulsa_projects')
          .doc(project.id)
          .update(project.toMap());

      // 4. Notificar a CADA miembro del equipo solicitante con la carta de motivos
      final notifiedEmails = <String>{
        request.requesterEmail.toLowerCase().trim(),
        ...resolvedApplicants.map((m) => m.normalizedEmail),
      };

      for (final email in notifiedEmails) {
        if (email.isEmpty) continue;
        await db.collection('agora_impulsa_notifications').add(
          ImpulsaNotificationItem(
            id: '',
            targetEmail: email,
            type: 'donation_received',
            projectId: newDocRef.id,
            projectName: project.name,
            title: '🌱 ¡Te han donado el proyecto "${project.name}"!',
            message:
            'Control Escolar liberó la donación para el equipo "${request.teamName}". Ya aparece en tu sección "Mis proyectos".',
            requestId: request.id,
            motivationLetterFileName: request.motivationLetterFileName,
            motivationLetterContent: request.motivationLetterContent,
          ).toMap(),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Proyecto "${project.name}" liberado 🌱. Asignado a "${request.teamName}" y retirado de la Red de Proyectos.',
            ),
            backgroundColor: ImpulsaPalette.flagGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al liberar la donación: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingRequestId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('agora_impulsa_projects')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error cargando solicitudes de donación: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final projects =
        snapshot.data!.docs.map(ImpulsaProject.fromDoc).toList();

        final readyToRelease = <({ImpulsaProject project, ImpulsaRequest req})>[];
        final pendingOwnerVotes =
        <({ImpulsaProject project, ImpulsaRequest req})>[];
        final completedDonations =
        <({ImpulsaProject project, ImpulsaRequest req})>[];

        for (final p in projects) {
          for (final req in p.requests) {
            if (req.status == 'donated') {
              completedDonations.add((project: p, req: req));
            } else if (_isRequestReadyForAdmin(p, req)) {
              readyToRelease.add((project: p, req: req));
            } else if (req.status == 'pending') {
              pendingOwnerVotes.add((project: p, req: req));
            }
          }
        }

        if (readyToRelease.isEmpty &&
            pendingOwnerVotes.isEmpty &&
            completedDonations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volunteer_activism_outlined,
                      size: 48, color: pal.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'Aún no hay solicitudes de donación registradas en Ágora Impulsa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: pal.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(
              pal: pal,
              icon: Icons.check_circle_rounded,
              color: ImpulsaPalette.flagGreen,
              title: 'Listas para liberar por Control Escolar',
              count: readyToRelease.length,
              subtitle:
              'El equipo dueño ya aceptó la carta de motivos. Libera el proyecto para transferirlo al nuevo equipo.',
            ),
            const SizedBox(height: 10),
            if (readyToRelease.isEmpty)
              _buildEmptyBox(
                pal,
                'No hay solicitudes con aprobación completa pendientes de liberar.',
              )
            else
              ...readyToRelease.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRequestCard(
                    context: context,
                    pal: pal,
                    project: item.project,
                    req: item.req,
                    badgeText: 'APROBADO POR DUEÑOS · LISTO PARA LIBERAR',
                    badgeColor: ImpulsaPalette.flagGreen,
                    canRelease: true,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _buildSectionHeader(
              pal: pal,
              icon: Icons.hourglass_top_rounded,
              color: Colors.amber.shade700,
              title: 'En espera de votación del equipo dueño',
              count: pendingOwnerVotes.length,
              subtitle:
              'Solicitudes enviadas cuya carta de motivos aún está siendo votada por los dueños del proyecto.',
            ),
            const SizedBox(height: 10),
            if (pendingOwnerVotes.isEmpty)
              _buildEmptyBox(
                pal,
                'No hay solicitudes pendientes de voto de los dueños.',
              )
            else
              ...pendingOwnerVotes.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRequestCard(
                    context: context,
                    pal: pal,
                    project: item.project,
                    req: item.req,
                    badgeText: 'ESPERANDO VOTOS DEL EQUIPO DUEÑO',
                    badgeColor: Colors.amber.shade700,
                    canRelease: false,
                  ),
                ),
              ),
            if (completedDonations.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(
                pal: pal,
                icon: Icons.inventory_2_rounded,
                color: pal.primary,
                title: 'Donaciones ya liberadas',
                count: completedDonations.length,
                subtitle:
                'Proyectos retirados de la Red de Proyectos y asignados a su nuevo equipo.',
              ),
              const SizedBox(height: 10),
              ...completedDonations.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRequestCard(
                    context: context,
                    pal: pal,
                    project: item.project,
                    req: item.req,
                    badgeText: 'DONADO Y LIBERADO 🌱',
                    badgeColor: pal.primary,
                    canRelease: false,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required ImpulsaPalette pal,
    required IconData icon,
    required Color color,
    required String title,
    required int count,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title ($count)',
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: pal.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(ImpulsaPalette pal, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pal.border),
      ),
      child: Text(
        text,
        style: TextStyle(color: pal.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildRequestCard({
    required BuildContext context,
    required ImpulsaPalette pal,
    required ImpulsaProject project,
    required ImpulsaRequest req,
    required String badgeText,
    required Color badgeColor,
    required bool canRelease,
  }) {
    final isExpanded = _expandedLetters.contains(req.id);
    final isProcessing = _processingRequestId == req.id;
    final totalVotes = req.memberVotes.isEmpty
        ? project.memberEmails.length
        : req.memberVotes.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Proyecto: ${project.name}',
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Equipo solicitante: ${req.teamName} · Asesor: ${req.advisor} · Semestre/Grupo: ${req.semester} ${req.group}',
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Periodo solicitado: ${fmtImpulsaDate(req.start)} al ${fmtImpulsaDate(req.end)} · Consenso dueños: ${req.acceptedCount}/$totalVotes',
            style: TextStyle(color: pal.textSecondary, fontSize: 12.5),
          ),
          if (req.memberVotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: req.memberVotes.entries.map((e) {
                final vColor = e.value == 'accept'
                    ? ImpulsaPalette.flagGreen
                    : e.value == 'reject'
                    ? Colors.redAccent
                    : Colors.amber.shade700;
                final vLabel = e.value == 'accept'
                    ? 'Aceptó'
                    : e.value == 'reject'
                    ? 'Rechazó'
                    : 'Pendiente';
                return Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: vColor.withValues(alpha: 0.12),
                  side: BorderSide(color: vColor.withValues(alpha: 0.4)),
                  label: Text(
                    'Dueño (${e.key}): $vLabel',
                    style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Integrantes que recibirán el proyecto (${req.applicantMembers.length}):',
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 4),
          ...req.applicantMembers.map(
                (m) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• ${m.fullName} · Matrícula: ${m.matricula} · ${m.email.isEmpty ? "Correo automático @tesoem.edu.mx" : m.email}',
                style: TextStyle(color: pal.textSecondary, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedLetters.remove(req.id);
                    } else {
                      _expandedLetters.add(req.id);
                    }
                  });
                },
                icon: Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.description_outlined,
                  color: pal.primary,
                ),
                label: Text(
                  isExpanded
                      ? 'Ocultar Carta de Motivos'
                      : 'Ver Carta de Motivos (${req.motivationLetterFileName})',
                  style: TextStyle(
                    color: pal.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (canRelease)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ImpulsaPalette.flagGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () => _executeAdminDonation(context, project, req),
                  icon: isProcessing
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.volunteer_activism_rounded),
                  label: Text(
                    isProcessing
                        ? 'Liberando proyecto...'
                        : 'Liberar y Donar proyecto 🌱',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.subCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: pal.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  req.motivationLetterContent.isEmpty
                      ? 'Sin extracto de texto adjunto.'
                      : req.motivationLetterContent,
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
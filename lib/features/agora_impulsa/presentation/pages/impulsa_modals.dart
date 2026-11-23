import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'impulsa_models.dart';

/// Modal para solicitar un proyecto: captura todos los integrantes del equipo solicitante
/// y permite adjuntar la Carta de Motivos sin bloquear el hilo principal.
Future<void> showImpulsaRequestModal({
  required BuildContext context,
  required ImpulsaProject project,
  required String currentEmail,
  required String currentName,
}) async {
  final db = FirebaseFirestore.instance;
  final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);

  final teamCtrl = TextEditingController();
  final advisorCtrl = TextEditingController();
  final semesterCtrl = TextEditingController();
  final groupCtrl = TextEditingController();
  final degreeCtrl =
  TextEditingController(text: 'Ingeniería en Sistemas Computacionales');
  final letterSummaryCtrl = TextEditingController();

  final memberNameCtrl = TextEditingController();
  final memberMatCtrl = TextEditingController();
  final memberEmailCtrl = TextEditingController();
  final memberSemCtrl = TextEditingController();
  final memberGroupCtrl = TextEditingController();
  final memberTeamCtrl = TextEditingController();
  final memberAdvisorCtrl = TextEditingController();

  final applicants = <ImpulsaApplicantMember>[];
  DateTime start = DateTime.now();
  DateTime end = DateTime.now().add(const Duration(days: 90));

  String? letterFileName;
  String letterFileSizeLabel = '';
  String letterContent = '';
  bool letterIsBinary = false;
  bool isReadingFile = false;

  const int maxFileBytes = 3 * 1024 * 1024; // 3 MB máximo
  const int maxPreviewChars = 12000; // Evita saturar SelectableText y Firestore

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => AlertDialog(
        backgroundColor: pal.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: pal.border),
        ),
        title: Text(
          'Solicitar Proyecto · ${project.name}',
          style: TextStyle(color: pal.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Datos generales del equipo solicitante',
                  style: TextStyle(
                      color: pal.textPrimary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: teamCtrl,
                        onChanged: (v) => memberTeamCtrl.text = v,
                        style: TextStyle(color: pal.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Nombre del equipo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: advisorCtrl,
                        onChanged: (v) => memberAdvisorCtrl.text = v,
                        style: TextStyle(color: pal.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Asesor',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: semesterCtrl,
                        onChanged: (v) => memberSemCtrl.text = v,
                        style: TextStyle(color: pal.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Semestre',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: groupCtrl,
                        onChanged: (v) => memberGroupCtrl.text = v,
                        style: TextStyle(color: pal.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Grupo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: degreeCtrl,
                        style: TextStyle(color: pal.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Carrera',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '2. Integrantes del equipo (todos los miembros)',
                  style: TextStyle(
                      color: pal.textPrimary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pal.subCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: pal.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: memberNameCtrl,
                              style: TextStyle(color: pal.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Nombre completo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: memberMatCtrl,
                              style: TextStyle(color: pal.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Matrícula',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: memberEmailCtrl,
                              style: TextStyle(color: pal.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Correo (notificación)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: memberSemCtrl,
                              style: TextStyle(color: pal.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Semestre',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: memberGroupCtrl,
                              style: TextStyle(color: pal.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Grupo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: memberTeamCtrl,
                              style: TextStyle(color: pal.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Equipo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: memberAdvisorCtrl,
                              style: TextStyle(color: pal.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Asesor',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (memberNameCtrl.text.trim().isEmpty ||
                                memberMatCtrl.text.trim().isEmpty) {
                              return;
                            }
                            setModalState(() {
                              applicants.add(
                                ImpulsaApplicantMember(
                                  fullName: memberNameCtrl.text.trim(),
                                  matricula:
                                  memberMatCtrl.text.trim().toUpperCase(),
                                  semester: memberSemCtrl.text.trim().isEmpty
                                      ? semesterCtrl.text.trim()
                                      : memberSemCtrl.text.trim(),
                                  group: memberGroupCtrl.text.trim().isEmpty
                                      ? groupCtrl.text.trim()
                                      : memberGroupCtrl.text.trim(),
                                  teamName: memberTeamCtrl.text.trim().isEmpty
                                      ? teamCtrl.text.trim()
                                      : memberTeamCtrl.text.trim(),
                                  advisor: memberAdvisorCtrl.text.trim().isEmpty
                                      ? advisorCtrl.text.trim()
                                      : memberAdvisorCtrl.text.trim(),
                                  email: memberEmailCtrl.text
                                      .trim()
                                      .toLowerCase(),
                                ),
                              );
                              memberNameCtrl.clear();
                              memberMatCtrl.clear();
                              memberEmailCtrl.clear();
                            });
                          },
                          icon: Icon(Icons.person_add, color: pal.primary),
                          label: Text('+ Agregar integrante',
                              style: TextStyle(color: pal.primary)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...applicants.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.badge_outlined, color: pal.primary),
                    title: Text(
                      '${a.fullName} · Matrícula: ${a.matricula}',
                      style: TextStyle(
                          color: pal.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Semestre: ${a.semester} · Grupo: ${a.group} · Equipo: ${a.teamName} · Asesor: ${a.advisor}',
                      style: TextStyle(color: pal.textSecondary, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.redAccent),
                      onPressed: () =>
                          setModalState(() => applicants.removeAt(i)),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                Text(
                  '3. Carta de Motivos (PDF, DOCX o TXT · Máx. 3 MB)',
                  style: TextStyle(
                      color: pal.textPrimary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isReadingFile
                      ? null
                      : () async {
                    setModalState(() => isReadingFile = true);
                    await Future<void>.delayed(
                        const Duration(milliseconds: 30));

                    try {
                      final picked = await FilePicker.pickFiles();
                      if (picked.isEmpty) {
                        if (ctx.mounted) {
                          setModalState(() => isReadingFile = false);
                        }
                        return;
                      }

                      final file = picked.first;
                      final lower = file.name.toLowerCase();
                      final allowed = lower.endsWith('.pdf') ||
                          lower.endsWith('.doc') ||
                          lower.endsWith('.docx') ||
                          lower.endsWith('.txt') ||
                          lower.endsWith('.md');

                      if (!allowed) {
                        if (ctx.mounted) {
                          setModalState(() => isReadingFile = false);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Formato no compatible. Sube un archivo .pdf, .docx, .doc o .txt',
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      final bytes = await file.readAsBytes();
                      if (bytes.length > maxFileBytes) {
                        if (ctx.mounted) {
                          setModalState(() => isReadingFile = false);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'El archivo supera los 3 MB. Sube una versión más ligera.',
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      final sizeKb =
                      (bytes.length / 1024).toStringAsFixed(1);
                      final isBin = lower.endsWith('.pdf') ||
                          lower.endsWith('.doc') ||
                          lower.endsWith('.docx');

                      String previewText;
                      if (isBin) {
                        previewText =
                        'Documento adjunto: ${file.name} ($sizeKb KB)\n'
                            'Archivo validado y listo para revisión del equipo original y del administrador.';
                      } else {
                        final rawText =
                        utf8.decode(bytes, allowMalformed: true);
                        previewText = rawText.length > maxPreviewChars
                            ? '${rawText.substring(0, maxPreviewChars)}\n\n... [Vista previa recortada a $maxPreviewChars caracteres]'
                            : rawText;
                        letterSummaryCtrl.text = previewText;
                      }

                      if (ctx.mounted) {
                        setModalState(() {
                          letterFileName = file.name;
                          letterFileSizeLabel = '$sizeKb KB';
                          letterContent = previewText;
                          letterIsBinary = isBin;
                          isReadingFile = false;
                        });
                      }
                    } catch (_) {
                      if (ctx.mounted) {
                        setModalState(() => isReadingFile = false);
                      }
                    }
                  },
                  icon: isReadingFile
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: pal.primary),
                  )
                      : Icon(Icons.upload_file_rounded, color: pal.primary),
                  label: Text(
                    isReadingFile
                        ? 'Cargando archivo...'
                        : letterFileName == null
                        ? 'Subir archivo de Carta de Motivos'
                        : 'Cambiar archivo ($letterFileName)',
                    style: TextStyle(
                        color: pal.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                if (letterFileName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: pal.subCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: pal.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              letterIsBinary
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.description_rounded,
                              color: pal.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$letterFileName ($letterFileSizeLabel)',
                                style: TextStyle(
                                  color: pal.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Chip(
                              label: const Text('Adjunto'),
                              backgroundColor: pal.badgeBg,
                              labelStyle: TextStyle(
                                color: pal.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (letterIsBinary) ...[
                          Text(
                            'Extracto o motivos principales (visible al instante en las notificaciones):',
                            style: TextStyle(
                              color: pal.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: letterSummaryCtrl,
                            maxLines: 4,
                            style: TextStyle(
                                color: pal.textPrimary, fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText:
                              'Escribe o pega aquí el texto de tu carta de motivos para que el equipo original lo lea directamente...',
                              filled: true,
                              fillColor: pal.card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ] else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 160),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                letterContent,
                                style: TextStyle(
                                  color: pal.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: start,
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) setModalState(() => start = d);
                        },
                        child: Text('Inicio: ${fmtImpulsaDate(start)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: end,
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) setModalState(() => end = d);
                        },
                        child: Text('Entrega: ${fmtImpulsaDate(end)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: pal.primary),
            onPressed: () async {
              if (teamCtrl.text.trim().isEmpty ||
                  applicants.isEmpty ||
                  letterFileName == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Completa el equipo, agrega al menos un integrante y sube la carta de motivos.',
                    ),
                  ),
                );
                return;
              }

              final finalLetterContent = letterIsBinary
                  ? (letterSummaryCtrl.text.trim().isNotEmpty
                  ? 'Archivo adjunto: $letterFileName ($letterFileSizeLabel)\n\n${letterSummaryCtrl.text.trim()}'
                  : letterContent)
                  : letterContent;

              final resolvedApplicants = <ImpulsaApplicantMember>[];
              for (int i = 0; i < applicants.length; i++) {
                final a = applicants[i];
                String email = a.email.isNotEmpty
                    ? a.email
                    : (i == 0 ? currentEmail : '');
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
                          .toLowerCase();
                    }
                  } catch (_) {}
                }
                resolvedApplicants.add(
                  ImpulsaApplicantMember(
                    fullName: a.fullName,
                    matricula: a.matricula,
                    semester: a.semester,
                    group: a.group,
                    teamName: a.teamName,
                    advisor: a.advisor,
                    email: email,
                  ),
                );
              }

              final initialVotes = <String, String>{};
              for (final memberEmail in project.memberEmails) {
                if (memberEmail.isNotEmpty) {
                  initialVotes[memberEmail] = 'pending';
                }
              }

              final req = ImpulsaRequest(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                requesterEmail: currentEmail,
                requesterName: currentName,
                teamName: teamCtrl.text.trim(),
                advisor: advisorCtrl.text.trim(),
                semester: semesterCtrl.text.trim(),
                group: groupCtrl.text.trim(),
                degree: degreeCtrl.text.trim(),
                start: start,
                end: end,
                motivationLetterFileName: letterFileName!,
                motivationLetterContent: finalLetterContent,
                motivationLetterIsBinary: letterIsBinary,
                applicantMembers: resolvedApplicants,
                memberVotes: initialVotes,
              );

              project.requests.add(req);
              await db
                  .collection('agora_impulsa_projects')
                  .doc(project.id)
                  .update(project.toMap());

              for (final memberEmail in project.memberEmails) {
                if (memberEmail.isEmpty) continue;
                await db.collection('agora_impulsa_notifications').add(
                  ImpulsaNotificationItem(
                    id: '',
                    targetEmail: memberEmail,
                    type: 'request',
                    projectId: project.id,
                    projectName: project.name,
                    title: 'Solicitud recibida para "${project.name}"',
                    message:
                    'El equipo "${req.teamName}" solicita la donación de este proyecto. Revisa su carta de motivos y emite tu voto.',
                    requestId: req.id,
                    motivationLetterFileName: req.motivationLetterFileName,
                    motivationLetterContent: req.motivationLetterContent,
                  ).toMap(),
                );
              }

              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Solicitud y carta de motivos enviadas a todos los integrantes del proyecto.',
                    ),
                    backgroundColor: ImpulsaPalette.flagGreen,
                  ),
                );
              }
            },
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    ),
  );
}

/// Modal para revisar una solicitud específica desde el detalle del proyecto y emitir voto.
Future<void> showImpulsaRequestReviewModal({
  required BuildContext context,
  required ImpulsaProject project,
  required ImpulsaRequest request,
  required String currentEmail,
  String? notificationId,
}) async {
  final db = FirebaseFirestore.instance;
  final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);
  final normalizedEmail = currentEmail.toLowerCase().trim();

  Future<void> submitVote(BuildContext dialogCtx, String decision) async {
    final docRef = db.collection('agora_impulsa_projects').doc(project.id);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final freshProject = ImpulsaProject.fromDoc(snap);
    final idx = freshProject.requests.indexWhere((r) => r.id == request.id);
    if (idx == -1) return;

    final targetReq = freshProject.requests[idx];
    targetReq.memberVotes[normalizedEmail] = decision;

    if (decision == 'reject') {
      targetReq.status = 'rejected';
    } else if (targetReq.isUnanimouslyAccepted) {
      targetReq.status = 'approved_by_team';
      freshProject.status = 'solicitado';
    }

    await docRef.update(freshProject.toMap());
    if (notificationId != null && notificationId.isNotEmpty) {
      await db
          .collection('agora_impulsa_notifications')
          .doc(notificationId)
          .update({'read': true});
    }

    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == 'accept'
                ? 'Voto registrado: Aceptado'
                : 'Voto registrado: Rechazado',
          ),
          backgroundColor: decision == 'accept'
              ? ImpulsaPalette.flagGreen
              : Colors.redAccent,
        ),
      );
    }
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      final myVote = request.memberVotes[normalizedEmail] ?? 'pending';
      final canVote = request.status == 'pending' &&
          (project.memberEmails.contains(normalizedEmail) ||
              request.memberVotes.containsKey(normalizedEmail));

      return AlertDialog(
        backgroundColor: pal.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: pal.border),
        ),
        title: Text(
          'Solicitud de ${request.teamName}',
          style: TextStyle(color: pal.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asesor: ${request.advisor} · Semestre: ${request.semester} · Grupo: ${request.group}',
                  style: TextStyle(color: pal.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Periodo propuesto: ${fmtImpulsaDate(request.start)} - ${fmtImpulsaDate(request.end)}',
                  style: TextStyle(color: pal.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Integrantes del equipo solicitante (${request.applicantMembers.length})',
                  style: TextStyle(
                      color: pal.textPrimary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                ...request.applicantMembers.map(
                      (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${m.fullName} (${m.matricula}) · ${m.email}',
                      style: TextStyle(color: pal.textSecondary, fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Carta de Motivos (${request.motivationLetterFileName})',
                  style: TextStyle(
                      color: pal.textPrimary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
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
                      request.motivationLetterContent,
                      style: TextStyle(
                        color: pal.textPrimary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Consenso del equipo: ${request.acceptedCount}/${request.memberVotes.length} aprobaciones · Tu voto: ${myVote == 'accept' ? 'Aceptado' : myVote == 'reject' ? 'Rechazado' : 'Pendiente'}',
                  style: TextStyle(
                    color: pal.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          if (canVote) ...[
            OutlinedButton.icon(
              onPressed: () => submitVote(ctx, 'reject'),
              icon: const Icon(Icons.close, color: Colors.redAccent),
              label: const Text('Rechazar',
                  style: TextStyle(color: Colors.redAccent)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: ImpulsaPalette.flagGreen),
              onPressed: () => submitVote(ctx, 'accept'),
              icon: const Icon(Icons.check),
              label: const Text('Aceptar donación'),
            ),
          ],
        ],
      );
    },
  );
}

/// Modal de Notificaciones con carta de motivos desplegable y votación por integrante.
Future<void> showImpulsaNotificationsModal({
  required BuildContext context,
  required List<ImpulsaNotificationItem> notifications,
  required String currentEmail,
  List<ImpulsaProject> allProjects = const [],
  void Function(ImpulsaProject project)? onOpenProject,
}) async {
  final db = FirebaseFirestore.instance;
  final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);
  final expandedIds = <String>{};
  final normalizedEmail = currentEmail.toLowerCase().trim();

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => AlertDialog(
        backgroundColor: pal.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: pal.border),
        ),
        title: Text(
          'Notificaciones · Ágora Impulsa',
          style: TextStyle(color: pal.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 640,
          height: 480,
          child: notifications.isEmpty
              ? Center(
            child: Text(
              'No tienes notificaciones por el momento.',
              style: TextStyle(color: pal.textSecondary),
            ),
          )
              : ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = notifications[i];
              final isExpanded = expandedIds.contains(n.id);
              final letterText = n.motivationLetterContent ?? '';
              final letterFile =
                  n.motivationLetterFileName ?? 'Carta de Motivos';
              final reqId = n.requestId ?? '';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: pal.subCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: n.read ? pal.border : pal.primary,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          n.type == 'donation_received'
                              ? Icons.volunteer_activism_rounded
                              : Icons.notifications_active_rounded,
                          color: pal.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              color: pal.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.message,
                      style: TextStyle(
                          color: pal.textSecondary, fontSize: 13),
                    ),
                    if (letterText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            if (isExpanded) {
                              expandedIds.remove(n.id);
                            } else {
                              expandedIds.add(n.id);
                            }
                          });
                        },
                        icon: Icon(
                          isExpanded
                              ? Icons.expand_less
                              : Icons.description_outlined,
                          color: pal.primary,
                        ),
                        label: Text(
                          isExpanded
                              ? 'Ocultar Carta de Motivos'
                              : 'Desplegar Carta de Motivos ($letterFile)',
                          style: TextStyle(
                            color: pal.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          width: double.infinity,
                          constraints:
                          const BoxConstraints(maxHeight: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: pal.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: pal.border),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              letterText,
                              style: TextStyle(
                                color: pal.textPrimary,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    if (n.type == 'request' && reqId.isNotEmpty)
                      _RequestVoteBar(
                        projectId: n.projectId,
                        requestId: reqId,
                        currentEmail: normalizedEmail,
                        notificationId: n.id,
                      ),
                    if (n.type == 'donation_received')
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: pal.primary),
                          onPressed: () async {
                            await db
                                .collection('agora_impulsa_notifications')
                                .doc(n.id)
                                .update({'read': true});
                            ImpulsaProject? target = allProjects
                                .where((p) => p.id == n.projectId)
                                .firstOrNull;
                            if (target == null) {
                              final snap = await db
                                  .collection('agora_impulsa_projects')
                                  .doc(n.projectId)
                                  .get();
                              if (snap.exists) {
                                target = ImpulsaProject.fromDoc(snap);
                              }
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (target != null) {
                              onOpenProject?.call(target);
                            }
                          },
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Abrir proyecto donado'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    ),
  );
}

class _RequestVoteBar extends StatelessWidget {
  final String projectId;
  final String requestId;
  final String currentEmail;
  final String notificationId;

  const _RequestVoteBar({
    required this.projectId,
    required this.requestId,
    required this.currentEmail,
    required this.notificationId,
  });

  Future<void> _vote(BuildContext context, String decision) async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection('agora_impulsa_projects').doc(projectId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final project = ImpulsaProject.fromDoc(snap);
    final reqIdx = project.requests.indexWhere((r) => r.id == requestId);
    if (reqIdx == -1) return;

    final req = project.requests[reqIdx];
    req.memberVotes[currentEmail] = decision;

    if (decision == 'reject') {
      req.status = 'rejected';
    } else if (req.isUnanimouslyAccepted) {
      req.status = 'approved_by_team';
      project.status = 'solicitado';
    }

    await docRef.update(project.toMap());
    await db
        .collection('agora_impulsa_notifications')
        .doc(notificationId)
        .update({'read': true});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == 'accept'
                ? 'Voto registrado: Aceptado'
                : 'Voto registrado: Rechazado',
          ),
          backgroundColor: decision == 'accept'
              ? ImpulsaPalette.flagGreen
              : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('agora_impulsa_projects')
          .doc(projectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final project = ImpulsaProject.fromDoc(snapshot.data!);
        final req = project.requests
            .where((r) => r.id == requestId)
            .cast<ImpulsaRequest?>()
            .firstOrNull;
        if (req == null) return const SizedBox.shrink();

        final myVote = req.memberVotes[currentEmail] ?? 'pending';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consenso del equipo: ${req.acceptedCount}/${project.memberEmails.length} aprobaciones · Tu voto: ${myVote == 'accept' ? 'Aceptado' : myVote == 'reject' ? 'Rechazado' : 'Pendiente'}',
              style: TextStyle(
                color: pal.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (req.status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _vote(context, 'reject'),
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    label: const Text('Rechazar',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: ImpulsaPalette.flagGreen),
                    onPressed: () => _vote(context, 'accept'),
                    icon: const Icon(Icons.check),
                    label: const Text('Aceptar donación'),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
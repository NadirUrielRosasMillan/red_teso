import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

typedef JsonMap = Map<String, dynamic>;

JsonMap asJsonMap(Object? raw) {
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  return <String, dynamic>{};
}

String fmtImpulsaDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class ImpulsaPalette {
  final bool isDark;
  const ImpulsaPalette(this.isDark);

  static const Color flagGreen = Color(0xFF0B6B3A);
  static const Color flagGreenMid = Color(0xFF137B4B);
  static const Color flagGreenBright = Color(0xFF10B981);
  static const Color flagGreenSoftDark = Color(0xFF0F2E22);
  static const Color flagGreenSoftLight = Color(0xFFE8F5EE);

  Color get bg => isDark ? const Color(0xFF0B1210) : const Color(0xFFF4F7F5);
  Color get sidebarBg =>
      isDark ? const Color(0xFF0E1915) : const Color(0xFF094D2A);
  Color get card => isDark ? const Color(0xFF121C19) : Colors.white;
  Color get subCard =>
      isDark ? const Color(0xFF172420) : const Color(0xFFF8FBF9);
  Color get codeBg =>
      isDark ? const Color(0xFF090E0C) : const Color(0xFF101916);
  Color get border =>
      isDark ? const Color(0xFF233831) : const Color(0xFFD6E4DC);
  Color get textPrimary =>
      isDark ? const Color(0xFFF1F7F4) : const Color(0xFF0F241B);
  Color get textSecondary =>
      isDark ? const Color(0xFF9DB5AA) : const Color(0xFF4C665A);
  Color get primary => isDark ? flagGreenBright : flagGreen;
  Color get badgeBg => isDark ? flagGreenSoftDark : flagGreenSoftLight;

  static const List<Color> memberColors = [
    Color(0xFF0B6B3A),
    Color(0xFF0284C7),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF0D9488),
  ];
}

class ImpulsaMember {
  final String name;
  final String email;

  ImpulsaMember({
    required this.name,
    required this.email,
  });

  String get normalizedEmail => email.toLowerCase().trim();

  String get initials {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'AL';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  JsonMap toMap() => {
    'name': name.trim(),
    'email': normalizedEmail,
  };

  factory ImpulsaMember.fromMap(JsonMap map) => ImpulsaMember(
    name: (map['name'] ?? '').toString(),
    email: (map['email'] ?? '').toString().toLowerCase().trim(),
  );
}

class ImpulsaApplicantMember {
  final String fullName;
  final String matricula;
  final String semester;
  final String group;
  final String teamName;
  final String advisor;
  final String email;

  ImpulsaApplicantMember({
    required this.fullName,
    required this.matricula,
    required this.semester,
    required this.group,
    required this.teamName,
    required this.advisor,
    this.email = '',
  });

  JsonMap toMap() => {
    'fullName': fullName.trim(),
    'matricula': matricula.toUpperCase().trim(),
    'semester': semester.trim(),
    'group': group.trim(),
    'teamName': teamName.trim(),
    'advisor': advisor.trim(),
    'email': email.toLowerCase().trim(),
  };

  factory ImpulsaApplicantMember.fromMap(JsonMap map) => ImpulsaApplicantMember(
    fullName: (map['fullName'] ?? map['name'] ?? '').toString(),
    matricula: (map['matricula'] ?? '').toString().toUpperCase(),
    semester: (map['semester'] ?? '').toString(),
    group: (map['group'] ?? '').toString(),
    teamName: (map['teamName'] ?? '').toString(),
    advisor: (map['advisor'] ?? '').toString(),
    email: (map['email'] ?? '').toString().toLowerCase().trim(),
  );
}

enum TaskImportance {
  low('Baja', 1.0, Color(0xFF64748B)),
  medium('Media', 2.0, Color(0xFF0284C7)),
  high('Alta', 3.0, Color(0xFFD97706)),
  critical('Crítica', 4.0, Color(0xFFDC2626));

  final String label;
  final double defaultWeight;
  final Color color;
  const TaskImportance(this.label, this.defaultWeight, this.color);

  static TaskImportance fromKey(String key) {
    return TaskImportance.values.firstWhere(
          (e) => e.name == key,
      orElse: () => TaskImportance.medium,
    );
  }
}

class ImpulsaTask {
  final String id;
  String title;
  int stage;
  String importanceKey;
  double weight;
  List<String> assignedEmails;

  ImpulsaTask({
    required this.id,
    required this.title,
    this.stage = 0,
    this.importanceKey = 'medium',
    double? weight,
    List<String>? assignedEmails,
  })  : weight = weight ?? TaskImportance.fromKey(importanceKey).defaultWeight,
        assignedEmails = assignedEmails ?? [];

  TaskImportance get importance => TaskImportance.fromKey(importanceKey);

  double sharePercentage(List<ImpulsaTask> allTasks) {
    final totalWeight = allTasks.fold<double>(
        0.0, (acc, t) => acc + (t.weight <= 0 ? 1 : t.weight));
    if (totalWeight <= 0) return 0;
    return ((weight <= 0 ? 1 : weight) / totalWeight) * 100.0;
  }

  JsonMap toMap() => {
    'id': id,
    'title': title,
    'stage': stage,
    'importanceKey': importanceKey,
    'weight': weight,
    'assignedEmails': assignedEmails,
  };

  factory ImpulsaTask.fromMap(JsonMap map) {
    final key = (map['importanceKey'] ?? 'medium').toString();
    final parsedWeight = (map['weight'] is num)
        ? (map['weight'] as num).toDouble()
        : TaskImportance.fromKey(key).defaultWeight;
    return ImpulsaTask(
      id: (map['id'] ?? DateTime.now().microsecondsSinceEpoch.toString())
          .toString(),
      title: (map['title'] ?? '').toString(),
      stage: (map['stage'] is num) ? (map['stage'] as num).toInt() : 0,
      importanceKey: key,
      weight: parsedWeight,
      assignedEmails: List<String>.from(
        map['assignedEmails'] ?? map['assignedKeys'] ?? const [],
      ),
    );
  }
}

class ImpulsaFile {
  String path;
  String content;
  DateTime updatedAt;
  bool isBinary;

  ImpulsaFile({
    required this.path,
    required this.content,
    DateTime? updatedAt,
    this.isBinary = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get name => path.contains('/') ? path.split('/').last : path;

  JsonMap toMap() => {
    'path': path,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
    'isBinary': isBinary,
  };

  factory ImpulsaFile.fromMap(JsonMap map) => ImpulsaFile(
    path: (map['path'] ?? map['name'] ?? 'archivo.txt').toString(),
    content: (map['content'] ?? '').toString(),
    updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()) ??
        DateTime.now(),
    isBinary: map['isBinary'] == true,
  );
}

class ImpulsaRequest {
  final String id;
  final String requesterEmail;
  final String requesterName;
  final String teamName;
  final String advisor;
  final String semester;
  final String group;
  final String degree;
  final DateTime start;
  final DateTime end;
  final String motivationLetterFileName;
  final String motivationLetterContent;
  final bool motivationLetterIsBinary;
  final List<ImpulsaApplicantMember> applicantMembers;

  /// Votos por correo de cada miembro original: 'pending' | 'accept' | 'reject'
  Map<String, String> memberVotes;

  /// 'pending' | 'approved_by_team' | 'rejected' | 'donated'
  String status;
  final DateTime createdAt;

  ImpulsaRequest({
    required this.id,
    required this.requesterEmail,
    required this.requesterName,
    required this.teamName,
    required this.advisor,
    required this.semester,
    required this.group,
    required this.degree,
    required this.start,
    required this.end,
    required this.motivationLetterFileName,
    required this.motivationLetterContent,
    this.motivationLetterIsBinary = false,
    required this.applicantMembers,
    Map<String, String>? memberVotes,
    this.status = 'pending',
    DateTime? createdAt,
  })  : memberVotes = memberVotes ?? {},
        createdAt = createdAt ?? DateTime.now();

  bool get hasAnyRejection =>
      memberVotes.values.any((v) => v == 'reject' || v == 'rejected') ||
          status == 'rejected';

  bool get isUnanimouslyAccepted =>
      memberVotes.isNotEmpty &&
          memberVotes.values.every((v) => v == 'accept' || v == 'accepted');

  int get acceptedCount => memberVotes.values
      .where((v) => v == 'accept' || v == 'accepted')
      .length;

  JsonMap toMap() => {
    'id': id,
    'requesterEmail': requesterEmail.toLowerCase().trim(),
    'requesterName': requesterName,
    'teamName': teamName,
    'advisor': advisor,
    'semester': semester,
    'group': group,
    'degree': degree,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'motivationLetterFileName': motivationLetterFileName,
    'motivationLetterContent': motivationLetterContent,
    'motivationLetterIsBinary': motivationLetterIsBinary,
    'applicantMembers': applicantMembers.map((m) => m.toMap()).toList(),
    'memberVotes': memberVotes,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ImpulsaRequest.fromMap(JsonMap map) {
    final rawVotes = asJsonMap(map['memberVotes']);
    final votes = <String, String>{};
    rawVotes.forEach((k, v) => votes[k.toLowerCase().trim()] = v.toString());

    return ImpulsaRequest(
      id: (map['id'] ?? DateTime.now().microsecondsSinceEpoch.toString())
          .toString(),
      requesterEmail: (map['requesterEmail'] ?? '').toString().toLowerCase(),
      requesterName: (map['requesterName'] ?? '').toString(),
      teamName: (map['teamName'] ?? '').toString(),
      advisor: (map['advisor'] ?? map['professor'] ?? '').toString(),
      semester: (map['semester'] ?? '').toString(),
      group: (map['group'] ?? '').toString(),
      degree: (map['degree'] ?? 'Ingeniería en Sistemas Computacionales')
          .toString(),
      start:
      DateTime.tryParse((map['start'] ?? '').toString()) ?? DateTime.now(),
      end: DateTime.tryParse((map['end'] ?? '').toString()) ?? DateTime.now(),
      motivationLetterFileName:
      (map['motivationLetterFileName'] ?? 'carta_motivos.txt').toString(),
      motivationLetterContent:
      (map['motivationLetterContent'] ?? map['description'] ?? '')
          .toString(),
      motivationLetterIsBinary: map['motivationLetterIsBinary'] == true,
      applicantMembers: (map['applicantMembers'] as List? ?? const [])
          .map((e) => ImpulsaApplicantMember.fromMap(asJsonMap(e)))
          .toList(),
      memberVotes: votes,
      status: (map['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class ImpulsaProject {
  String id;
  String name;
  String subject;
  String professor;
  String semester;
  String degree;
  String team;
  String description;
  String ownerUid;
  String ownerEmail;
  String ownerName;
  DateTime start;
  DateTime end;
  DateTime createdAt;
  DateTime updatedAt;
  int updatesCount;
  List<String> technologies;
  List<ImpulsaMember> members;
  List<ImpulsaFile> files;
  List<ImpulsaTask> tasks;
  List<ImpulsaRequest> requests;

  bool published;
  String status; // 'activo' | 'solicitado' | 'donado'

  DateTime? inactivityWarningSentAt;
  DateTime? inactivityDeadline;
  bool availableForDonation;
  String? receivedMotivationLetterName;
  String? receivedMotivationLetterContent;

  ImpulsaProject({
    required this.id,
    required this.name,
    required this.subject,
    required this.professor,
    required this.semester,
    required this.degree,
    required this.team,
    required this.description,
    required this.ownerUid,
    required this.ownerEmail,
    required this.ownerName,
    required this.start,
    required this.end,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.updatesCount = 1,
    required this.technologies,
    required this.members,
    List<ImpulsaFile>? files,
    List<ImpulsaTask>? tasks,
    List<ImpulsaRequest>? requests,
    this.published = false,
    this.status = 'activo',
    this.inactivityWarningSentAt,
    this.inactivityDeadline,
    this.availableForDonation = false,
    this.receivedMotivationLetterName,
    this.receivedMotivationLetterContent,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        files = files ?? [],
        tasks = tasks ?? [],
        requests = requests ?? [];

  bool get isRequested => status == 'solicitado';
  bool get isDonated => status == 'donado';

  /// Etiquetado en otros perfiles únicamente por correo electrónico
  List<String> get memberEmails => {
    ownerEmail.toLowerCase().trim(),
    ...members
        .map((m) => m.normalizedEmail)
        .where((e) => e.isNotEmpty),
  }.toList();

  /// Algoritmo de progreso ponderado según la importancia de cada tarea
  double get weightedProgress {
    if (tasks.isEmpty) return 0.0;
    double totalWeight = 0.0;
    double completedWeight = 0.0;
    for (final t in tasks) {
      final w = t.weight <= 0 ? 1.0 : t.weight;
      totalWeight += w;
      if (t.stage == 4) {
        completedWeight += w;
      }
    }
    if (totalWeight <= 0) return 0.0;
    return (completedWeight / totalWeight).clamp(0.0, 1.0);
  }

  int get weightedProgressPercent => (weightedProgress * 100).round();

  ImpulsaRequest? get approvedRequestPendingAdmin {
    for (final r in requests) {
      if (r.isUnanimouslyAccepted && r.status != 'donated') {
        return r;
      }
    }
    return null;
  }

  JsonMap toMap() => {
    'name': name,
    'subject': subject,
    'professor': professor,
    'semester': semester,
    'degree': degree,
    'team': team,
    'description': description,
    'ownerUid': ownerUid,
    'ownerEmail': ownerEmail.toLowerCase().trim(),
    'ownerName': ownerName,
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(end),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'updatesCount': updatesCount,
    'technologies': technologies,
    'members': members.map((m) => m.toMap()).toList(),
    'memberEmails': memberEmails,
    'files': files.map((f) => f.toMap()).toList(),
    'tasks': tasks.map((t) => t.toMap()).toList(),
    'requests': requests.map((r) => r.toMap()).toList(),
    'published': published,
    'status': status,
    'donated': isDonated,
    'inactivityWarningSentAt': inactivityWarningSentAt != null
        ? Timestamp.fromDate(inactivityWarningSentAt!)
        : null,
    'inactivityDeadline': inactivityDeadline != null
        ? Timestamp.fromDate(inactivityDeadline!)
        : null,
    'availableForDonation': availableForDonation,
    'receivedMotivationLetterName': receivedMotivationLetterName,
    'receivedMotivationLetterContent': receivedMotivationLetterContent,
  };

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory ImpulsaProject.fromDoc(DocumentSnapshot doc) {
    final data = asJsonMap(doc.data());
    final legacyDonated = data['donated'] == true;
    final rawStatus = (data['status'] ?? '').toString();
    final resolvedStatus = rawStatus.isNotEmpty
        ? rawStatus
        : (legacyDonated ? 'donado' : 'activo');

    return ImpulsaProject(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      subject: (data['subject'] ?? '').toString(),
      professor: (data['professor'] ?? '').toString(),
      semester: (data['semester'] ?? '').toString(),
      degree: (data['degree'] ?? '').toString(),
      team: (data['team'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      ownerUid: (data['ownerUid'] ?? '').toString(),
      ownerEmail: (data['ownerEmail'] ?? '').toString().toLowerCase(),
      ownerName: (data['ownerName'] ?? '').toString(),
      start: _parseDate(data['start']),
      end: _parseDate(data['end']),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      updatesCount: (data['updatesCount'] is num)
          ? (data['updatesCount'] as num).toInt()
          : 1,
      technologies: List<String>.from(data['technologies'] ?? const []),
      members: (data['members'] as List? ?? const [])
          .map((e) => ImpulsaMember.fromMap(asJsonMap(e)))
          .toList(),
      files: (data['files'] as List? ?? const [])
          .map((e) => ImpulsaFile.fromMap(asJsonMap(e)))
          .toList(),
      tasks: (data['tasks'] as List? ?? const [])
          .map((e) => ImpulsaTask.fromMap(asJsonMap(e)))
          .toList(),
      requests: (data['requests'] as List? ?? const [])
          .map((e) => ImpulsaRequest.fromMap(asJsonMap(e)))
          .toList(),
      published: data['published'] == true,
      status: resolvedStatus,
      inactivityWarningSentAt:
      _parseNullableDate(data['inactivityWarningSentAt']),
      inactivityDeadline: _parseNullableDate(data['inactivityDeadline']),
      availableForDonation: data['availableForDonation'] == true,
      receivedMotivationLetterName:
      data['receivedMotivationLetterName']?.toString(),
      receivedMotivationLetterContent:
      data['receivedMotivationLetterContent']?.toString(),
    );
  }

  ImpulsaProject createDonatedProjectForApplicants(
      ImpulsaRequest request,
      List<ImpulsaMember> newMembers,
      ) {
    final leadEmail = newMembers.isNotEmpty
        ? newMembers.first.normalizedEmail
        : request.requesterEmail.toLowerCase().trim();
    final leadName = newMembers.isNotEmpty
        ? newMembers.first.name
        : request.requesterName;

    return ImpulsaProject(
      id: '',
      name: name,
      subject: subject,
      professor: request.advisor.isNotEmpty ? request.advisor : professor,
      semester: request.semester.isNotEmpty ? request.semester : semester,
      degree: request.degree.isNotEmpty ? request.degree : degree,
      team: request.teamName.isNotEmpty ? request.teamName : team,
      description: description,
      ownerUid: '',
      ownerEmail: leadEmail,
      ownerName: leadName,
      start: request.start,
      end: request.end,
      technologies: List<String>.from(technologies),
      members: newMembers,
      files: files
          .map(
            (f) => ImpulsaFile(
          path: f.path,
          content: f.content,
          updatedAt: f.updatedAt,
          isBinary: f.isBinary,
        ),
      )
          .toList(),
      tasks: tasks
          .map(
            (t) => ImpulsaTask(
          id: t.id,
          title: t.title,
          stage: t.stage,
          importanceKey: t.importanceKey,
          weight: t.weight,
          assignedEmails: const [],
        ),
      )
          .toList(),
      requests: [],
      published: false,
      status: 'solicitado', // Solo mostrará la etiqueta "Solicitado" al equipo receptor
      receivedMotivationLetterName: request.motivationLetterFileName,
      receivedMotivationLetterContent: request.motivationLetterContent,
    );
  }
}

class ImpulsaNotificationItem {
  final String id;
  final String targetEmail;
  final String type; // 'request' | 'inactivity_warning' | 'donation_received'
  final String projectId;
  final String projectName;
  final String title;
  final String message;
  final String? requestId;
  final String? motivationLetterFileName;
  final String? motivationLetterContent;
  final DateTime createdAt;
  final bool read;

  ImpulsaNotificationItem({
    required this.id,
    required this.targetEmail,
    required this.type,
    required this.projectId,
    required this.projectName,
    required this.title,
    required this.message,
    this.requestId,
    this.motivationLetterFileName,
    this.motivationLetterContent,
    DateTime? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now();

  JsonMap toMap() => {
    'targetEmail': targetEmail.toLowerCase().trim(),
    'type': type,
    'projectId': projectId,
    'projectName': projectName,
    'title': title,
    'message': message,
    'requestId': requestId,
    'motivationLetterFileName': motivationLetterFileName,
    'motivationLetterContent': motivationLetterContent,
    'createdAt': Timestamp.fromDate(createdAt),
    'read': read,
  };

  factory ImpulsaNotificationItem.fromDoc(DocumentSnapshot doc) {
    final data = asJsonMap(doc.data());
    return ImpulsaNotificationItem(
      id: doc.id,
      targetEmail: (data['targetEmail'] ?? '').toString().toLowerCase(),
      type: (data['type'] ?? 'request').toString(),
      projectId: (data['projectId'] ?? '').toString(),
      projectName: (data['projectName'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      requestId: data['requestId']?.toString(),
      motivationLetterFileName: data['motivationLetterFileName']?.toString(),
      motivationLetterContent: data['motivationLetterContent']?.toString(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      read: data['read'] == true,
    );
  }
}

/// Algoritmo de auditoría de inactividad de 4 semanas + plazo de 1 semana
class ImpulsaLifecycleService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> auditProjectsInactivity(
      List<ImpulsaProject> projects,
      ) async {
    final now = DateTime.now();

    for (final p in projects) {
      if (p.isDonated || p.isRequested) continue;

      final daysWithoutUpdates = now.difference(p.updatedAt).inDays;

      // 1. Al cumplir 4 semanas (28 días) sin actualizar, avisa a todo el equipo y al admin
      if (daysWithoutUpdates >= 28 && p.inactivityWarningSentAt == null) {
        final deadline = now.add(const Duration(days: 7));
        p.inactivityWarningSentAt = now;
        p.inactivityDeadline = deadline;

        await _db.collection('agora_impulsa_projects').doc(p.id).update({
          'inactivityWarningSentAt': Timestamp.fromDate(now),
          'inactivityDeadline': Timestamp.fromDate(deadline),
        });

        final recipients = {...p.memberEmails, 'admin'};
        for (final email in recipients) {
          if (email.isEmpty) continue;
          await _db.collection('agora_impulsa_notifications').add(
            ImpulsaNotificationItem(
              id: '',
              targetEmail: email,
              type: 'inactivity_warning',
              projectId: p.id,
              projectName: p.name,
              title: '⚠️ Proyecto sin actualizar (4 semanas): ${p.name}',
              message:
              'El proyecto "${p.name}" lleva 4 semanas sin actualizaciones. '
                  'Tienen 1 semana (hasta ${fmtImpulsaDate(deadline)}) para actualizarlo e innovarlo; '
                  'al detectar movimiento o vencer el plazo se publicará como "Disponible para donación".',
            ).toMap(),
          );
        }
      }
      // 2. Si venció la semana de gracia, pasa a Disponible para donación y Público
      else if (p.inactivityDeadline != null &&
          now.isAfter(p.inactivityDeadline!) &&
          !p.availableForDonation) {
        p.availableForDonation = true;
        p.published = true;
        await _db.collection('agora_impulsa_projects').doc(p.id).update({
          'availableForDonation': true,
          'published': true,
        });
      }
    }
  }

  /// Al detectar movimiento tras la alerta, lo vuelve público y etiqueta "Disponible para donación"
  static Future<void> registerProjectMovement(ImpulsaProject p) async {
    p.updatedAt = DateTime.now();
    p.updatesCount += 1;

    if (p.inactivityWarningSentAt != null) {
      p.availableForDonation = true;
      if (!p.published) {
        p.published = true;
      }
      p.inactivityWarningSentAt = null;
      p.inactivityDeadline = null;
    }

    await _db
        .collection('agora_impulsa_projects')
        .doc(p.id)
        .update(p.toMap());
  }
}
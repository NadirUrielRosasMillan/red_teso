import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';

import '../models/local_course.dart';

/// Resultado de resolver una evaluacion.
class EvaluationResult {
  const EvaluationResult({
    required this.correct,
    required this.total,
    required this.score,
    required this.passed,
  });

  final int correct;
  final int total;
  final int score;
  final bool passed;
}

/// Estado compartido del modulo de cursos, guardado en Firebase.
///
/// Colecciones (todas nuevas, no tocan las existentes de red_teso):
/// - learning_courses/{courseId}: contenido del curso (modulos, lecciones,
///   sesiones, evaluaciones).
/// - learning_enrollments/{uid}_{courseId}: inscripcion y avance del alumno.
/// - learning_certificates/{folio}: certificados emitidos (verificables).
///
/// Los cambios del editor se detectan comparando el curso con la ultima
/// version guardada, por eso las pantallas solo llaman a changed().
class LocalCourseStore extends ChangeNotifier {
  LocalCourseStore._();

  static final LocalCourseStore instance = LocalCourseStore._();

  static const String coursesCol = 'learning_courses';
  static const String enrollCol = 'learning_enrollments';
  static const String certCol = 'learning_certificates';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  final List<LocalCourse> courses = [];
  final Map<String, CourseProgress> _progress = {};
  final Map<String, String> _lastSaved = {};
  final Map<String, Set<String>> _idsBySource = {};
  final Set<String> _remoteIds = {};
  final Set<String> _localOnly = {};
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _syncTimer;

  String? _uid;
  String _role = '';
  String userName = '';

  /// true mientras llegan los primeros datos de Firestore.
  bool loading = false;

  /// Ultimo error de lectura o escritura, para mostrarlo en pantalla.
  String? error;

  // ------------------------------------------------------------- sesion

  String? get uid => _uid;
  String get role => _role;
  bool get isAttached => _uid != null;
  bool get isAdmin => _role == 'admin';
  bool get isTeacher => _role == 'profesor' || _role == 'admin';
  bool get canEnroll => _role == 'alumno';

  bool canEdit(LocalCourse c) => isAdmin || (isTeacher && c.ownerId == _uid);

  /// Cursos que el usuario puede editar (los suyos, o todos si es admin).
  List<LocalCourse> get manageableCourses =>
      courses.where(canEdit).toList(growable: false);

  /// Conecta el modulo con el usuario que inicio sesion. Se puede llamar
  /// varias veces: si el usuario y el rol no cambian, no hace nada.
  Future<void> attach({
    required String uid,
    required String role,
    String name = '',
  }) async {
    final r = role.trim().toLowerCase();
    if (_uid == uid && _role == r && _subs.isNotEmpty) return;

    await detach();
    _uid = uid;
    _role = r;
    userName = name.trim();
    loading = true;
    error = null;
    notifyListeners();

    if (userName.isEmpty) {
      try {
        final d = await _db.collection('users').doc(uid).get();
        userName = (d.data()?['name'] ?? '').toString().trim();
      } catch (e) {
        debugPrint('No se pudo leer el nombre del usuario: $e');
      }
    }

    final col = _db.collection(coursesCol);
    if (isAdmin) {
      _listenCourses('all', col);
    } else {
      _listenCourses('pub', col.where('published', isEqualTo: true));
      if (r == 'profesor') {
        _listenCourses('own', col.where('ownerId', isEqualTo: uid));
      }
    }
    _subs.add(
      _db
          .collection(enrollCol)
          .where('userId', isEqualTo: uid)
          .snapshots()
          .listen(_onEnrollments, onError: _onError),
    );
  }

  /// Cierra las suscripciones y limpia los datos (cierre de sesion).
  Future<void> detach() async {
    if (_syncTimer?.isActive ?? false) {
      _syncTimer!.cancel();
      await _syncNow();
    }
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    courses.clear();
    _progress.clear();
    _lastSaved.clear();
    _idsBySource.clear();
    _remoteIds.clear();
    _localOnly.clear();
    _uid = null;
    _role = '';
    userName = '';
    loading = false;
    error = null;
    notifyListeners();
  }

  // ------------------------------------------------------------- lectura

  void _listenCourses(String source, Query<Map<String, dynamic>> query) {
    _subs.add(
      query.snapshots().listen(
        (snap) => _onCourses(source, snap),
        onError: _onError,
      ),
    );
  }

  void _onError(Object e) {
    loading = false;
    if (e is FirebaseException) {
      error =
          'No se pudieron leer los datos (${e.code}). Revisa las reglas de Firestore.';
    } else {
      error = 'No se pudieron leer los datos: $e';
    }
    notifyListeners();
  }

  void _onCourses(String source, QuerySnapshot<Map<String, dynamic>> snap) {
    final ids = <String>{};
    for (final d in snap.docs) {
      ids.add(d.id);
      _upsert(d.id, d.data());
    }
    _idsBySource[source] = ids;

    final alive = <String>{for (final s in _idsBySource.values) ...s};
    courses.removeWhere((c) {
      if (_localOnly.contains(c.id)) return false;
      final gone = !alive.contains(c.id);
      if (gone) {
        _lastSaved.remove(c.id);
        _remoteIds.remove(c.id);
      }
      return gone;
    });
    courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    loading = false;
    error = null;
    notifyListeners();
  }

  void _upsert(String id, Map<String, dynamic> data) {
    final parsed = LocalCourse.fromMap(data, id);
    final json = jsonEncode(parsed.toMap());
    _remoteIds.add(id);
    _localOnly.remove(id);

    final index = courses.indexWhere((c) => c.id == id);
    if (index < 0) {
      courses.add(parsed);
      _lastSaved[id] = json;
      return;
    }

    final existing = courses[index];
    // Contadores que escriben otros usuarios.
    existing.enrolled = parsed.enrolled;
    existing.rating = parsed.rating;
    existing.ratingCount = parsed.ratingCount;

    // Si hay cambios locales sin guardar, no se pisan.
    final localDirty = _lastSaved[id] != jsonEncode(existing.toMap());
    if (localDirty) return;
    if (_lastSaved[id] != json) {
      existing.updateFrom(parsed);
      _lastSaved[id] = json;
    }
  }

  void _onEnrollments(QuerySnapshot<Map<String, dynamic>> snap) {
    final next = <String, CourseProgress>{};
    for (final d in snap.docs) {
      final p = CourseProgress.fromMap(d.data());
      if (p.courseId.isEmpty) continue;
      // Los cambios locales aun pendientes mandan sobre el servidor.
      if (d.metadata.hasPendingWrites && _progress.containsKey(p.courseId)) {
        next[p.courseId] = _progress[p.courseId]!;
      } else {
        next[p.courseId] = p;
      }
    }
    _progress
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  // ------------------------------------------------------ cursos (escritura)

  void _touch() {
    notifyListeners();
    _scheduleSync();
  }

  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 700), _syncNow);
  }

  Future<void> _syncNow() async {
    for (final c in List<LocalCourse>.of(courses)) {
      if (!canEdit(c)) continue;
      final err = await _writeCourse(c);
      if (err != null) {
        error = err;
        notifyListeners();
      } else if (error != null && error!.startsWith('No se pudo guardar')) {
        error = null;
        notifyListeners();
      }
    }
  }

  /// Escribe un curso en Firestore solo si cambio. Devuelve null si todo
  /// salio bien, o el mensaje de error.
  Future<String?> _writeCourse(LocalCourse c) async {
    final json = jsonEncode(c.toMap());
    if (_lastSaved[c.id] == json) return null;

    final previous = _lastSaved[c.id];
    _lastSaved[c.id] = json;
    try {
      final ref = _db.collection(coursesCol).doc(c.id);
      final data = c.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (_remoteIds.contains(c.id)) {
        await ref.update(data);
      } else {
        data['enrolled'] = 0;
        await ref.set(data);
        _remoteIds.add(c.id);
        _localOnly.remove(c.id);
      }
      return null;
    } on FirebaseException catch (e) {
      _restore(c.id, previous);
      final hint = e.code == 'permission-denied'
          ? 'Faltan permisos: publica las reglas de Firestore y revisa que tu usuario sea profesor.'
          : 'Revisa tu conexion a internet.';
      return 'No se pudo guardar "${c.title}" (${e.code}). $hint';
    } catch (e) {
      _restore(c.id, previous);
      return 'No se pudo guardar "${c.title}": $e';
    }
  }

  /// Guarda el curso ahora mismo y espera la respuesta de Firebase.
  /// Devuelve null si se guardo, o el motivo del fallo.
  Future<String?> saveCourse(LocalCourse c) async {
    if (!isAttached) {
      return 'El modulo no esta conectado a tu sesion. Entra desde AGORA Aprende.';
    }
    if (!canEdit(c)) {
      return 'Tu usuario no puede editar este curso (rol: ${_role.isEmpty ? 'sin rol' : _role}).';
    }
    _syncTimer?.cancel();
    final err = await _writeCourse(c);
    error = err;
    notifyListeners();
    return err;
  }

  void _restore(String id, String? previous) {
    if (previous == null) {
      _lastSaved.remove(id);
    } else {
      _lastSaved[id] = previous;
    }
  }

  void addCourse(LocalCourse course) {
    course.ownerId = _uid ?? '';
    course.ownerName = userName;
    if (course.createdAt == 0) {
      course.createdAt = DateTime.now().millisecondsSinceEpoch;
    }
    if (course.instructor.trim().isEmpty) course.instructor = userName;
    courses.insert(0, course);
    _localOnly.add(course.id);
    _touch();
  }

  /// Las pantallas llaman a changed() despues de modificar un curso.
  void changed() => _touch();

  void addModule(LocalCourse c, String title) {
    c.modules.add(CourseModule(id: _id(), title: title));
    _touch();
  }

  void addLesson(CourseModule m, String title) {
    m.lessons.add(CourseLesson(id: _id(), title: title));
    _touch();
  }

  void addBlock(CourseLesson l, ContentKind kind) {
    l.blocks.add(ContentBlock(id: _id(), kind: kind));
    _touch();
  }

  void removeCourse(LocalCourse c) {
    final id = c.id;
    final wasRemote = _remoteIds.contains(id);
    courses.remove(c);
    _lastSaved.remove(id);
    _localOnly.remove(id);
    _remoteIds.remove(id);
    notifyListeners();
    if (wasRemote && canEdit(c)) {
      _db.collection(coursesCol).doc(id).delete().catchError((Object e) {
        error = 'No se pudo eliminar el curso: $e';
        notifyListeners();
      });
    }
  }

  // ------------------------------------------------- inscripcion y avance

  String _enrollId(String courseId) => '${_uid}_$courseId';

  bool isEnrolled(LocalCourse c) => _progress.containsKey(c.id);

  Future<void> enroll(LocalCourse c) async {
    if (!canEnroll || _uid == null || isEnrolled(c)) return;
    final p = CourseProgress(
      courseId: c.id,
      enrolledAt: DateTime.now().millisecondsSinceEpoch,
    );
    _progress[c.id] = p;
    c.enrolled += 1;
    notifyListeners();
    try {
      await _db
          .collection(enrollCol)
          .doc(_enrollId(c.id))
          .set(p.toMap(_uid!, userName));
      await _db
          .collection(coursesCol)
          .doc(c.id)
          .update({'enrolled': FieldValue.increment(1)});
    } on FirebaseException catch (e) {
      error = 'No se pudo registrar la inscripcion (${e.code}).';
      notifyListeners();
    }
  }

  Future<void> _saveProgress(String courseId) async {
    final p = _progress[courseId];
    if (p == null || _uid == null) return;
    try {
      await _db
          .collection(enrollCol)
          .doc(_enrollId(courseId))
          .set(p.toMap(_uid!, userName), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      error = 'No se pudo guardar tu avance (${e.code}).';
      notifyListeners();
    }
  }

  bool isLessonDone(LocalCourse c, String lessonId) =>
      _progress[c.id]?.completedLessonIds.contains(lessonId) ?? false;

  /// Marca o desmarca una leccion. Solo aplica si el estudiante esta inscrito.
  void toggleLesson(LocalCourse c, String lessonId) {
    final p = _progress[c.id];
    if (p == null) return;
    if (!p.completedLessonIds.remove(lessonId)) {
      p.completedLessonIds.add(lessonId);
    }
    notifyListeners();
    _saveProgress(c.id);
  }

  int completedLessons(LocalCourse c) {
    final p = _progress[c.id];
    if (p == null) return 0;
    final ids = <String>{
      for (final m in c.modules)
        for (final l in m.lessons) l.id,
    };
    return p.completedLessonIds.where(ids.contains).length;
  }

  /// Avance de 0 a 100.
  int percentFor(LocalCourse c) {
    final total = c.lessonCount;
    if (total == 0) return 0;
    return (completedLessons(c) * 100 / total).floor();
  }

  // ------------------------------------------------------- evaluaciones

  /// Mejor calificacion del alumno en la evaluacion, o null si no la ha hecho.
  int? bestScore(LocalCourse c, CourseEvaluation e) =>
      _progress[c.id]?.evaluationScores[e.id];

  bool isEvaluationPassed(LocalCourse c, CourseEvaluation e) =>
      _progress[c.id]?.passedEvaluationIds.contains(e.id) ?? false;

  /// Califica las respuestas (id de pregunta -> indice elegido) y guarda el
  /// mejor resultado. La calificacion se calcula en el dispositivo.
  EvaluationResult submitEvaluation(
    LocalCourse c,
    CourseEvaluation e,
    Map<String, int> answers,
  ) {
    var correct = 0;
    for (final q in e.items) {
      if (answers[q.id] == q.correctIndex) correct++;
    }
    final total = e.items.length;
    final score = total == 0 ? 0 : (correct * 100 / total).round();
    final passed = total > 0 && score >= e.passingScore;

    final p = _progress[c.id];
    if (p != null) {
      final best = p.evaluationScores[e.id] ?? -1;
      if (score > best) p.evaluationScores[e.id] = score;
      if (passed) p.passedEvaluationIds.add(e.id);
      notifyListeners();
      _saveProgress(c.id);
    }
    return EvaluationResult(
      correct: correct,
      total: total,
      score: score,
      passed: passed,
    );
  }

  // ------------------------------------------------------- certificado

  bool meetsCertificateRequirements(LocalCourse c) {
    final p = _progress[c.id];
    if (p == null) return false;
    if (percentFor(c) < c.certificateMinProgress) return false;
    if (c.certificateRequiresEvaluations) {
      for (final e in c.requiredEvaluations) {
        if (!p.passedEvaluationIds.contains(e.id)) return false;
      }
    }
    return true;
  }

  CertificateState certificateStateFor(LocalCourse c) {
    if (!c.certificate) return CertificateState.notOffered;
    final p = _progress[c.id];
    if (p != null && p.certificateIssued) return CertificateState.issued;
    if (meetsCertificateRequirements(c)) return CertificateState.eligible;
    return CertificateState.locked;
  }

  /// Datos del certificado del usuario para el curso, si ya lo obtuvo.
  CertificateData? certificateDataFor(LocalCourse c) {
    final p = _progress[c.id];
    if (p == null || !p.certificateIssued) return null;
    return CertificateData(
      folio: p.certificateFolio,
      studentName: userName.isEmpty ? 'Alumno' : userName,
      courseTitle: c.title,
      instructor: c.instructor.isEmpty ? c.ownerName : c.instructor,
      duration: c.duration,
      issuedAt: DateTime.fromMillisecondsSinceEpoch(p.certificateIssuedAt),
      percent: percentFor(c),
    );
  }

  /// Emite el certificado si se cumplen los requisitos. Devuelve el folio,
  /// o null si no se pudo emitir.
  Future<String?> issueCertificate(LocalCourse c) async {
    final p = _progress[c.id];
    if (p == null || _uid == null || !c.certificate) return null;
    if (p.certificateIssued) return p.certificateFolio;
    if (!meetsCertificateRequirements(c)) return null;

    final folio = _newFolio();
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _db.collection(certCol).doc(folio).set({
        'folio': folio,
        'userId': _uid,
        'studentName': userName.isEmpty ? 'Alumno' : userName,
        'courseId': c.id,
        'courseTitle': c.title,
        'instructor': c.instructor.isEmpty ? c.ownerName : c.instructor,
        'duration': c.duration,
        'percent': percentFor(c),
        'issuedAtMs': now,
        'issuedAt': FieldValue.serverTimestamp(),
      });
      p.certificateFolio = folio;
      p.certificateIssuedAt = now;
      notifyListeners();
      await _saveProgress(c.id);
      return folio;
    } on FirebaseException catch (e) {
      error = 'No se pudo emitir el certificado (${e.code}).';
      notifyListeners();
      return null;
    }
  }

  /// Busca un certificado por folio. Devuelve null si no existe.
  Future<CertificateData?> verifyCertificate(String folio) async {
    final clean = folio.trim().toUpperCase();
    if (clean.isEmpty) return null;
    final d = await _db.collection(certCol).doc(clean).get();
    final data = d.data();
    if (!d.exists || data == null) return null;
    return CertificateData.fromMap(data);
  }

  static String _newFolio() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final code =
        List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
    return 'AGORA-${DateTime.now().year}-$code';
  }

  static String _id() => DateTime.now().microsecondsSinceEpoch.toString();
}

/// Valores de nivel. Deben coincidir con los del editor y los filtros.
/// Se escriben con escapes Unicode para que el archivo siga siendo ASCII.
const String kLevelBasic = 'B\u00E1sico';

enum LessonKind { video, text, live, resource }

enum ContentKind { text, image, video, youtube, document, program }

/// Estado del certificado de un curso para el estudiante.
/// notOffered: el curso no emite certificado.
/// locked: ofrece certificado pero aun no cumple los requisitos.
/// eligible: cumple los requisitos, falta la emision.
/// issued: certificado ya obtenido.
enum CertificateState { notOffered, locked, eligible, issued }

// ---------------------------------------------------------------- helpers

String _str(Object? v, [String d = '']) => v == null ? d : v.toString();

int _int(Object? v, [int d = 0]) =>
    v is num ? v.toInt() : (int.tryParse(_str(v)) ?? d);

double _dbl(Object? v, [double d = 0]) =>
    v is num ? v.toDouble() : (double.tryParse(_str(v)) ?? d);

bool _bool(Object? v, [bool d = false]) => v is bool ? v : d;

List<Map<String, dynamic>> _maps(Object? v) => v is List
    ? [
        for (final e in v)
          if (e is Map) Map<String, dynamic>.from(e),
      ]
    : <Map<String, dynamic>>[];

List<String> _strings(Object? v) =>
    v is List ? [for (final e in v) e.toString()] : <String>[];

// ----------------------------------------------------------------- bloques

class ContentBlock {
  ContentBlock({
    required this.id,
    required this.kind,
    this.title = '',
    this.content = '',
    this.url = '',
    this.caption = '',
  });

  final String id;
  ContentKind kind;
  String title;
  String content;
  String url;
  String caption;

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'content': content,
        'url': url,
        'caption': caption,
      };

  factory ContentBlock.fromMap(Map<String, dynamic> m) => ContentBlock(
        id: _str(m['id']),
        kind: ContentKind.values.firstWhere(
          (k) => k.name == _str(m['kind']),
          orElse: () => ContentKind.text,
        ),
        title: _str(m['title']),
        content: _str(m['content']),
        url: _str(m['url']),
        caption: _str(m['caption']),
      );
}

class CourseLesson {
  CourseLesson({
    required this.id,
    required this.title,
    this.description = '',
    this.duration = '15 min',
    List<ContentBlock>? blocks,
  }) : blocks = blocks ?? [];

  final String id;
  String title;
  String description;
  String duration;
  final List<ContentBlock> blocks;

  String get preview => blocks
      .map((b) => b.content)
      .where((s) => s.trim().isNotEmpty)
      .join('\n\n');

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'duration': duration,
        'blocks': [for (final b in blocks) b.toMap()],
      };

  factory CourseLesson.fromMap(Map<String, dynamic> m) => CourseLesson(
        id: _str(m['id']),
        title: _str(m['title']),
        description: _str(m['description']),
        duration: _str(m['duration'], '15 min'),
        blocks: _maps(m['blocks']).map(ContentBlock.fromMap).toList(),
      );
}

class CourseModule {
  CourseModule({
    required this.id,
    required this.title,
    this.description = '',
    List<CourseLesson>? lessons,
  }) : lessons = lessons ?? [];

  final String id;
  String title;
  String description;
  final List<CourseLesson> lessons;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'lessons': [for (final l in lessons) l.toMap()],
      };

  factory CourseModule.fromMap(Map<String, dynamic> m) => CourseModule(
        id: _str(m['id']),
        title: _str(m['title']),
        description: _str(m['description']),
        lessons: _maps(m['lessons']).map(CourseLesson.fromMap).toList(),
      );
}

class LiveSession {
  LiveSession({
    required this.id,
    required this.title,
    this.date = '',
    this.time = '',
    this.mode = 'En l\u00EDnea',
    this.url = '',
    this.description = '',
  });

  final String id;
  String title;
  String date;
  String time;
  String mode;
  String url;
  String description;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'mode': mode,
        'url': url,
        'description': description,
      };

  factory LiveSession.fromMap(Map<String, dynamic> m) => LiveSession(
        id: _str(m['id']),
        title: _str(m['title']),
        date: _str(m['date']),
        time: _str(m['time']),
        mode: _str(m['mode'], 'En l\u00EDnea'),
        url: _str(m['url']),
        description: _str(m['description']),
      );
}

// ------------------------------------------------------------ evaluaciones

/// Pregunta de opcion multiple con una unica respuesta correcta.
class QuizQuestion {
  QuizQuestion({
    required this.id,
    this.text = '',
    List<String>? options,
    this.correctIndex = 0,
    this.explanation = '',
  }) : options = options ?? [];

  final String id;
  String text;
  final List<String> options;
  int correctIndex;
  String explanation;

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'options': List<String>.of(options),
        'correctIndex': correctIndex,
        'explanation': explanation,
      };

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        id: _str(m['id']),
        text: _str(m['text']),
        options: _strings(m['options']),
        correctIndex: _int(m['correctIndex']),
        explanation: _str(m['explanation']),
      );
}

class CourseEvaluation {
  CourseEvaluation({
    required this.id,
    required this.title,
    this.description = '',
    this.required = false,
    this.questions = 0,
    this.passingScore = 70,
    List<QuizQuestion>? items,
  }) : items = items ?? [];

  final String id;
  String title;
  String description;
  bool required;

  /// Valor heredado. Si hay preguntas cargadas se usa questionCount.
  int questions;

  /// Calificacion minima (0 a 100) para aprobar.
  int passingScore;
  final List<QuizQuestion> items;

  int get questionCount => items.isNotEmpty ? items.length : questions;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'required': required,
        'questions': items.length,
        'passingScore': passingScore,
        'items': [for (final q in items) q.toMap()],
      };

  factory CourseEvaluation.fromMap(Map<String, dynamic> m) => CourseEvaluation(
        id: _str(m['id']),
        title: _str(m['title']),
        description: _str(m['description']),
        required: _bool(m['required']),
        questions: _int(m['questions']),
        passingScore: _int(m['passingScore'], 70),
        items: _maps(m['items']).map(QuizQuestion.fromMap).toList(),
      );
}

// ---------------------------------------------------------------- progreso

/// Avance de un estudiante en un curso. Se guarda en learning_enrollments.
class CourseProgress {
  CourseProgress({
    required this.courseId,
    Set<String>? completedLessonIds,
    Set<String>? passedEvaluationIds,
    Map<String, int>? evaluationScores,
    this.enrolledAt = 0,
    this.certificateFolio = '',
    this.certificateIssuedAt = 0,
  })  : completedLessonIds = completedLessonIds ?? <String>{},
        passedEvaluationIds = passedEvaluationIds ?? <String>{},
        evaluationScores = evaluationScores ?? <String, int>{};

  final String courseId;
  final Set<String> completedLessonIds;
  final Set<String> passedEvaluationIds;

  /// Mejor calificacion (0 a 100) por evaluacion.
  final Map<String, int> evaluationScores;
  int enrolledAt;
  String certificateFolio;
  int certificateIssuedAt;

  bool get certificateIssued => certificateFolio.isNotEmpty;

  Map<String, dynamic> toMap(String userId, String userName) => {
        'userId': userId,
        'userName': userName,
        'courseId': courseId,
        'enrolledAt': enrolledAt,
        'completedLessonIds': completedLessonIds.toList(),
        'passedEvaluationIds': passedEvaluationIds.toList(),
        'evaluationScores': Map<String, int>.of(evaluationScores),
        'certificateFolio': certificateFolio,
        'certificateIssuedAt': certificateIssuedAt,
      };

  factory CourseProgress.fromMap(Map<String, dynamic> m) {
    final scores = <String, int>{};
    final raw = m['evaluationScores'];
    if (raw is Map) {
      raw.forEach((k, v) => scores[k.toString()] = _int(v));
    }
    return CourseProgress(
      courseId: _str(m['courseId']),
      completedLessonIds: _strings(m['completedLessonIds']).toSet(),
      passedEvaluationIds: _strings(m['passedEvaluationIds']).toSet(),
      evaluationScores: scores,
      enrolledAt: _int(m['enrolledAt']),
      certificateFolio: _str(m['certificateFolio']),
      certificateIssuedAt: _int(m['certificateIssuedAt']),
    );
  }
}

/// Datos de un certificado emitido (documento learning_certificates).
class CertificateData {
  const CertificateData({
    required this.folio,
    required this.studentName,
    required this.courseTitle,
    required this.instructor,
    required this.duration,
    required this.issuedAt,
    required this.percent,
  });

  final String folio;
  final String studentName;
  final String courseTitle;
  final String instructor;
  final String duration;
  final DateTime issuedAt;
  final int percent;

  factory CertificateData.fromMap(Map<String, dynamic> m) => CertificateData(
        folio: _str(m['folio']),
        studentName: _str(m['studentName']),
        courseTitle: _str(m['courseTitle']),
        instructor: _str(m['instructor']),
        duration: _str(m['duration']),
        issuedAt: DateTime.fromMillisecondsSinceEpoch(_int(m['issuedAtMs'])),
        percent: _int(m['percent']),
      );
}

// ------------------------------------------------------------------- curso

class LocalCourse {
  LocalCourse({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.summary = '',
    this.career = 'Todas las carreras',
    this.level = kLevelBasic,
    this.modality = 'modulos',
    this.duration = '10 horas',
    this.price = 0,
    this.currency = 'MXN',
    this.published = true,
    this.certificate = true,
    this.videoUrl = '',
    this.instructor = '',
    this.coverUrl = '',
    this.enrolled = 0,
    this.rating = 0,
    this.ratingCount = 0,
    this.certificateMinProgress = 100,
    this.certificateRequiresEvaluations = true,
    this.ownerId = '',
    this.ownerName = '',
    this.createdAt = 0,
    List<String>? objectives,
    List<String>? requirements,
    List<CourseModule>? modules,
    List<LiveSession>? sessions,
    List<CourseEvaluation>? evaluations,
  })  : objectives = objectives ?? [],
        requirements = requirements ?? [],
        modules = modules ?? [],
        sessions = sessions ?? [],
        evaluations = evaluations ?? [];

  final String id;
  String title;
  String category;
  String description;
  String summary;
  String career;
  String level;
  String modality;
  String duration;
  double price;
  String currency;
  bool published;
  bool certificate;
  String videoUrl;

  /// Nombre del docente (vacio si aun no se asigna).
  String instructor;

  /// URL de portada. Vacio: se muestra una portada generada por categoria.
  String coverUrl;

  /// Total de inscritos y valoracion promedio (0 = sin resenas).
  /// No se escriben desde el editor: los actualiza el servicio.
  int enrolled;
  double rating;
  int ratingCount;

  /// Porcentaje minimo de avance (0 a 100) para obtener el certificado.
  int certificateMinProgress;

  /// Si es true, las evaluaciones marcadas como requeridas deben aprobarse.
  bool certificateRequiresEvaluations;

  /// Usuario (uid de Firebase) que creo el curso y su nombre.
  String ownerId;
  String ownerName;
  int createdAt;

  final List<String> objectives;
  final List<String> requirements;
  final List<CourseModule> modules;
  final List<LiveSession> sessions;
  final List<CourseEvaluation> evaluations;

  int get lessonCount =>
      modules.fold(0, (sum, module) => sum + module.lessons.length);
  bool get isLive => modality == 'en_linea';
  bool get isFree => price == 0;
  List<CourseEvaluation> get requiredEvaluations =>
      evaluations.where((e) => e.required).toList();

  /// Carreras a las que va dirigido el curso (guardadas separadas por |).
  List<String> get careerList {
    final parts = career
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? ['Todas las carreras'] : parts;
  }

  /// true si el curso aplica a la carrera indicada.
  bool targetsCareer(String name) =>
      careerList.contains('Todas las carreras') || careerList.contains(name);

  /// Contenido editable del curso. Excluye enrolled, rating y ratingCount.
  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'description': description,
        'summary': summary,
        'career': career,
        'level': level,
        'modality': modality,
        'duration': duration,
        'price': price,
        'currency': currency,
        'published': published,
        'certificate': certificate,
        'videoUrl': videoUrl,
        'instructor': instructor,
        'coverUrl': coverUrl,
        'certificateMinProgress': certificateMinProgress,
        'certificateRequiresEvaluations': certificateRequiresEvaluations,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'createdAt': createdAt,
        'objectives': List<String>.of(objectives),
        'requirements': List<String>.of(requirements),
        'modules': [for (final m in modules) m.toMap()],
        'sessions': [for (final s in sessions) s.toMap()],
        'evaluations': [for (final e in evaluations) e.toMap()],
      };

  factory LocalCourse.fromMap(Map<String, dynamic> m, String id) =>
      LocalCourse(
        id: id,
        title: _str(m['title']),
        category: _str(m['category'], 'Sin categoria'),
        description: _str(m['description']),
        summary: _str(m['summary']),
        career: _str(m['career'], 'Todas las carreras'),
        level: _str(m['level'], kLevelBasic),
        modality: _str(m['modality'], 'modulos'),
        duration: _str(m['duration'], '10 horas'),
        price: _dbl(m['price']),
        currency: _str(m['currency'], 'MXN'),
        published: _bool(m['published']),
        certificate: _bool(m['certificate'], true),
        videoUrl: _str(m['videoUrl']),
        instructor: _str(m['instructor']),
        coverUrl: _str(m['coverUrl']),
        enrolled: _int(m['enrolled']),
        rating: _dbl(m['rating']),
        ratingCount: _int(m['ratingCount']),
        certificateMinProgress: _int(m['certificateMinProgress'], 100),
        certificateRequiresEvaluations:
            _bool(m['certificateRequiresEvaluations'], true),
        ownerId: _str(m['ownerId']),
        ownerName: _str(m['ownerName']),
        createdAt: _int(m['createdAt']),
        objectives: _strings(m['objectives']),
        requirements: _strings(m['requirements']),
        modules: _maps(m['modules']).map(CourseModule.fromMap).toList(),
        sessions: _maps(m['sessions']).map(LiveSession.fromMap).toList(),
        evaluations:
            _maps(m['evaluations']).map(CourseEvaluation.fromMap).toList(),
      );

  /// Copia todos los datos de [o] en este objeto, conservando la identidad
  /// (el editor y las pantallas abiertas siguen apuntando a la misma instancia).
  void updateFrom(LocalCourse o) {
    title = o.title;
    category = o.category;
    description = o.description;
    summary = o.summary;
    career = o.career;
    level = o.level;
    modality = o.modality;
    duration = o.duration;
    price = o.price;
    currency = o.currency;
    published = o.published;
    certificate = o.certificate;
    videoUrl = o.videoUrl;
    instructor = o.instructor;
    coverUrl = o.coverUrl;
    enrolled = o.enrolled;
    rating = o.rating;
    ratingCount = o.ratingCount;
    certificateMinProgress = o.certificateMinProgress;
    certificateRequiresEvaluations = o.certificateRequiresEvaluations;
    ownerId = o.ownerId;
    ownerName = o.ownerName;
    createdAt = o.createdAt;
    objectives
      ..clear()
      ..addAll(o.objectives);
    requirements
      ..clear()
      ..addAll(o.requirements);
    modules
      ..clear()
      ..addAll(o.modules);
    sessions
      ..clear()
      ..addAll(o.sessions);
    evaluations
      ..clear()
      ..addAll(o.evaluations);
  }
}

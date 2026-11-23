import 'package:flutter/material.dart';
import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../local_courses_pages.dart';
import '../theme/courses_theme.dart';
import '../widgets/certificate_panel.dart';
import '../widgets/content_viewer.dart';
import 'evaluation_page.dart';
import '../widgets/course_widgets.dart';

/// Aula virtual: esquema por modulos, lector de lecciones con avance,
/// evaluaciones y certificado. Mantiene el nombre y constructor originales.
class CourseClassroomPage extends StatefulWidget {
  const CourseClassroomPage({super.key, required this.course});

  final LocalCourse course;

  @override
  State<CourseClassroomPage> createState() => _CourseClassroomPageState();
}

class _CourseClassroomPageState extends State<CourseClassroomPage> {
  CourseLesson? _selected;

  LocalCourse get _course => widget.course;

  List<CourseLesson> get _lessons => [
        for (final m in _course.modules)
          for (final l in m.lessons) l,
      ];

  void _toggle(CourseLesson lesson) {
    final store = LocalCourseStore.instance;
    store.toggleLesson(_course, lesson.id);
    if (store.isLessonDone(_course, lesson.id) &&
        store.percentFor(_course) == 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completaste todas las lecciones.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: coursesTheme(),
      child: AnimatedBuilder(
        animation: LocalCourseStore.instance,
        builder: (context, _) {
          final store = LocalCourseStore.instance;
          final selected = _lessons.contains(_selected) ? _selected : null;

          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  _course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    tooltip: 'Clases en vivo',
                    icon: const Icon(Icons.videocam_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveSessionsPage(course: _course),
                      ),
                    ),
                  ),
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Contenido'),
                    Tab(text: 'Evaluaciones'),
                    Tab(text: 'Certificado'),
                  ],
                ),
              ),
              body: Column(
                children: [
                  _progressStrip(store),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _contentTab(store, selected),
                        _evaluationsTab(),
                        _certificateTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------- progreso

  Widget _progressStrip(LocalCourseStore store) {
    final enrolled = store.isEnrolled(_course);
    final percent = store.percentFor(_course);
    return Container(
      width: double.infinity,
      color: CoursesColors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: enrolled
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CourseProgressBar(
                  value: percent / 100,
                  label:
                      '$percent% completado (${store.completedLessons(_course)} de ${_course.lessonCount} lecciones)',
                ),
                const SizedBox(height: 8),
                if (_course.certificate)
                  CertificateStatusChip(
                    state: store.certificateStateFor(_course),
                  ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: CoursesColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.canEnroll
                        ? 'No estas inscrito: tu avance no se registra.'
                        : 'Vista de consulta: el avance solo lo registran los alumnos.',
                    style: const TextStyle(color: CoursesColors.muted),
                  ),
                ),
                if (store.canEnroll)
                  TextButton(
                    onPressed: () => store.enroll(_course),
                    child: const Text('Inscribirme'),
                  ),
              ],
            ),
    );
  }

  // ------------------------------------------------------------ contenido

  Widget _contentTab(LocalCourseStore store, CourseLesson? selected) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return Row(
        children: [
          SizedBox(width: 360, child: _outline(store, selected)),
          const VerticalDivider(width: 1, color: CoursesColors.line),
          Expanded(
            child: selected == null
                ? _welcome()
                : _lessonView(store, selected, showBack: false),
          ),
        ],
      );
    }
    return selected == null
        ? _outline(store, null)
        : _lessonView(store, selected, showBack: true);
  }

  Widget _outline(LocalCourseStore store, CourseLesson? selected) {
    if (_course.modules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'El profesor aun no agrega modulos.',
            style: TextStyle(color: CoursesColors.muted),
          ),
        ),
      );
    }
    final enrolled = store.isEnrolled(_course);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ESQUEMA DEL CURSO',
          style: TextStyle(
            color: CoursesColors.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        for (final m in _course.modules)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CoursePanel(
              padding: EdgeInsets.zero,
              child: Theme(
                data: ThemeData(
                  dividerColor: Colors.transparent,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: CoursesColors.primary,
                  ),
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(
                    m.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: CoursesColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    enrolled
                        ? '${m.lessons.where((l) => store.isLessonDone(_course, l.id)).length} de ${m.lessons.length} lecciones'
                        : '${m.lessons.length} lecciones',
                  ),
                  children: [
                    for (final l in m.lessons)
                      ListTile(
                        dense: true,
                        selected: selected?.id == l.id,
                        selectedTileColor: CoursesColors.green50,
                        leading: Icon(
                          enrolled && store.isLessonDone(_course, l.id)
                              ? Icons.check_circle_rounded
                              : Icons.play_circle_outline,
                          color: enrolled && store.isLessonDone(_course, l.id)
                              ? CoursesColors.green600
                              : CoursesColors.gray400,
                        ),
                        title: Text(l.title),
                        subtitle: Text(l.duration),
                        onTap: () => setState(() => _selected = l),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _welcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined,
                size: 60, color: CoursesColors.green500),
            const SizedBox(height: 16),
            Text(
              _course.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: CoursesColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _course.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CoursesColors.muted),
            ),
            const SizedBox(height: 18),
            const Text(
              'Selecciona una leccion del esquema para comenzar.',
              style: TextStyle(
                color: CoursesColors.green700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lessonView(
    LocalCourseStore store,
    CourseLesson lesson, {
    required bool showBack,
  }) {
    final lessons = _lessons;
    final index = lessons.indexOf(lesson);
    final enrolled = store.isEnrolled(_course);
    final done = enrolled && store.isLessonDone(_course, lesson.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selected = null),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Esquema del curso'),
            ),
          ),
        Text(
          lesson.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: CoursesColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            CoursePill(
              text: lesson.duration,
              icon: Icons.schedule_outlined,
              background: CoursesColors.gray100,
              foreground: CoursesColors.gray700,
            ),
            if (done)
              const CoursePill(
                text: 'Completada',
                icon: Icons.check_circle_rounded,
              ),
          ],
        ),
        if (lesson.description.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            lesson.description,
            style: const TextStyle(color: CoursesColors.muted, height: 1.4),
          ),
        ],
        const SizedBox(height: 16),
        if (lesson.blocks.isEmpty)
          const Text(
            'Esta leccion aun no tiene contenido.',
            style: TextStyle(color: CoursesColors.muted),
          ),
        for (final b in lesson.blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ContentBlockView(block: b),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: done
              ? OutlinedButton.icon(
                  onPressed: () => _toggle(lesson),
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Marcar como pendiente'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: CoursesColors.green800,
                    side: const BorderSide(color: CoursesColors.green300),
                  ),
                )
              : FilledButton.icon(
                  onPressed: enrolled ? () => _toggle(lesson) : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Marcar como completada'),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: index > 0
                    ? () => setState(() => _selected = lessons[index - 1])
                    : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: index >= 0 && index < lessons.length - 1
                    ? () => setState(() => _selected = lessons[index + 1])
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Siguiente'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------- evaluaciones

  Widget _evaluationsTab() {
    if (_course.evaluations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Este curso no tiene evaluaciones.',
            style: TextStyle(color: CoursesColors.muted),
          ),
        ),
      );
    }
    final store = LocalCourseStore.instance;
    final enrolled = store.isEnrolled(_course);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final e in _course.evaluations)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CoursePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.quiz_outlined,
                          color: CoursesColors.green700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CoursesColors.ink,
                              ),
                            ),
                            if (e.description.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                e.description,
                                style: const TextStyle(
                                  color: CoursesColors.muted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${e.questionCount} preguntas - aprueba con ${e.passingScore}%',
                              style: const TextStyle(
                                color: CoursesColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (e.required) ...[
                        const SizedBox(width: 8),
                        const CoursePill(text: 'Requerida'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _evalStatus(store, e)),
                      FilledButton(
                        onPressed: enrolled && e.items.isNotEmpty
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EvaluationPage(
                                      course: _course,
                                      evaluation: e,
                                    ),
                                  ),
                                )
                            : null,
                        child: Text(
                          store.bestScore(_course, e) == null
                              ? 'Resolver'
                              : 'Repetir',
                        ),
                      ),
                    ],
                  ),
                  if (!enrolled)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Inscribete al curso para resolver las evaluaciones.',
                        style: TextStyle(
                          color: CoursesColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _evalStatus(LocalCourseStore store, CourseEvaluation e) {
    final best = store.bestScore(_course, e);
    if (store.isEvaluationPassed(_course, e)) {
      return Align(
        alignment: Alignment.centerLeft,
        child: CoursePill(
          text: 'Aprobada ($best%)',
          icon: Icons.check_circle_rounded,
          background: CoursesColors.green600,
          foreground: CoursesColors.white,
        ),
      );
    }
    if (best != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: CoursePill(
          text: 'Mejor resultado: $best%',
          background: CoursesColors.gray100,
          foreground: CoursesColors.gray700,
        ),
      );
    }
    return const Align(
      alignment: Alignment.centerLeft,
      child: CoursePill(
        text: 'Sin intentar',
        background: CoursesColors.gray100,
        foreground: CoursesColors.gray700,
      ),
    );
  }

  // ---------------------------------------------------------- certificado

  Widget _certificateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CertificatePanel(course: _course),
      ],
    );
  }
}

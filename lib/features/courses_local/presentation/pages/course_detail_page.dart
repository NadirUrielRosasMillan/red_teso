import 'package:flutter/material.dart';
import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../local_courses_pages.dart';
import '../theme/courses_theme.dart';
import '../widgets/certificate_panel.dart';
import '../widgets/course_widgets.dart';

/// Detalle del curso. Con studentMode muestra inscripcion, avance y estado
/// del certificado; sin studentMode es la vista previa del profesor.
/// Mantiene el nombre y el constructor de la clase original.
class CoursePreviewPage extends StatelessWidget {
  const CoursePreviewPage({
    super.key,
    required this.course,
    this.studentMode = false,
  });

  final LocalCourse course;
  final bool studentMode;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: coursesTheme(),
      child: AnimatedBuilder(
        animation: LocalCourseStore.instance,
        builder: (context, _) {
          final width = MediaQuery.sizeOf(context).width;
          final wide = width >= 900;
          final pad = width >= 640 ? 24.0 : 16.0;

          final side = <Widget>[
            _actionCard(context),
            const SizedBox(height: 16),
            CertificatePanel(course: course, studentMode: studentMode),
          ];
          final main = <Widget>[
            ..._about(),
            ..._modulesSection(),
            ..._evaluationsSection(),
            ..._sessionsSection(),
          ];

          return Scaffold(
            appBar: AppBar(
              title: Text(studentMode ? 'Detalle del curso' : 'Vista previa'),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 40),
                  children: [
                    _hero(),
                    const SizedBox(height: 16),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: main,
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 340,
                            child: Column(children: side),
                          ),
                        ],
                      )
                    else ...[
                      ...side,
                      ...main,
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- hero

  Widget _hero() {
    final live = course.isLive;
    return CoursePanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CourseCover(course: course),
                if (course.certificate)
                  const Positioned(
                    right: 12,
                    top: 12,
                    child: CertificateBadge(onDark: true),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CoursePill(text: course.category),
                    CoursePill(
                      text: course.level,
                      background: CoursesColors.gray100,
                      foreground: CoursesColors.gray700,
                    ),
                    if (!course.published)
                      const CoursePill(
                        text: 'Borrador',
                        background: CoursesColors.ink,
                        foreground: CoursesColors.white,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: CoursesColors.ink,
                    height: 1.2,
                  ),
                ),
                if (course.instructor.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Imparte: ${course.instructor}',
                    style: const TextStyle(
                      color: CoursesColors.green700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (course.summary.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    course.summary,
                    style: const TextStyle(
                      color: CoursesColors.muted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _meta(Icons.schedule_outlined, course.duration),
                    _meta(
                      live ? Icons.videocam_outlined : Icons.view_module_outlined,
                      live ? 'En linea con clases' : 'Por modulos',
                    ),
                    _meta(
                      Icons.menu_book_outlined,
                      '${course.lessonCount} lecciones',
                    ),
                    _meta(
                      Icons.group_outlined,
                      '${course.enrolled} inscritos',
                    ),
                    course.ratingCount > 0
                        ? _meta(
                            Icons.star_rounded,
                            '${course.rating.toStringAsFixed(1)} (${course.ratingCount})',
                          )
                        : _meta(Icons.star_outline_rounded, 'Sin resenas'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: CoursesColors.green700),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: CoursesColors.gray700, fontSize: 13),
        ),
      ],
    );
  }

  // --------------------------------------------------------- action card

  Widget _actionCard(BuildContext context) {
    final store = LocalCourseStore.instance;
    final enrolled = store.isEnrolled(course);
    final percent = store.percentFor(course);
    final price = course.isFree
        ? 'Gratis'
        : '${course.currency} ${course.price.toStringAsFixed(0)}';

    final children = <Widget>[
      Text(
        price,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: CoursesColors.green700,
        ),
      ),
      const SizedBox(height: 12),
    ];

    if (!studentMode) {
      children.addAll([
        const Text(
          'Vista previa del profesor',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CoursesColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          course.published
              ? 'Este curso esta publicado y visible para los alumnos.'
              : 'Este curso es un borrador y no aparece en el catalogo.',
          style: const TextStyle(color: CoursesColors.muted),
        ),
        const SizedBox(height: 14),
        _classroomButton(context, 'Entrar al aula virtual'),
      ]);
    } else if (enrolled) {
      children.addAll([
        CourseProgressBar(
          value: percent / 100,
          label:
              '$percent% completado (${store.completedLessons(course)} de ${course.lessonCount} lecciones)',
        ),
        const SizedBox(height: 14),
        _classroomButton(
          context,
          percent == 0 ? 'Comenzar curso' : 'Continuar curso',
        ),
        if (course.isLive) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveSessionsPage(course: course),
                ),
              ),
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Ver sesiones en vivo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: CoursesColors.green800,
                side: const BorderSide(color: CoursesColors.green300),
              ),
            ),
          ),
        ],
      ]);
    } else {
      children.addAll([
        Text(
          '${course.duration} - nivel ${course.level}',
          style: const TextStyle(color: CoursesColors.muted),
        ),
        const SizedBox(height: 14),
        if (store.canEnroll) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                store.enroll(course);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inscripcion registrada.')),
                );
              },
              child: Text(
                course.isFree ? 'Inscribirme' : 'Inscribirme (sin pago en linea)',
              ),
            ),
          ),
          if (!course.isFree) ...[
            const SizedBox(height: 10),
            const Text(
              'El pago en linea aun no esta integrado: esta inscripcion no genera ningun cargo.',
              style: TextStyle(color: CoursesColors.muted, fontSize: 12),
            ),
          ],
        ] else
          const Text(
            'Solo los alumnos pueden inscribirse a los cursos.',
            style: TextStyle(color: CoursesColors.muted),
          ),
      ]);
    }

    return CoursePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _classroomButton(BuildContext context, String label) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseClassroomPage(course: course),
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(label),
      ),
    );
  }

  // -------------------------------------------------------- main content

  List<Widget> _about() {
    return [
      const CourseSectionTitle('Sobre el curso'),
      Text(
        course.description,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: CoursesColors.gray700,
        ),
      ),
      if (course.objectives.isNotEmpty) ...[
        const CourseSectionTitle('Que vas a lograr'),
        for (final s in course.objectives)
          _bullet(Icons.check_circle_rounded, CoursesColors.green600, s),
      ],
      if (course.requirements.isNotEmpty) ...[
        const CourseSectionTitle('Requisitos'),
        for (final s in course.requirements)
          _bullet(Icons.arrow_right_rounded, CoursesColors.gray700, s),
      ],
      const CourseSectionTitle('Dirigido a'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final career in course.careerList)
            CoursePill(
              text: career,
              background: CoursesColors.gray100,
              foreground: CoursesColors.gray700,
            ),
        ],
      ),
    ];
  }

  Widget _bullet(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.4,
                color: CoursesColors.gray700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _modulesSection() {
    final store = LocalCourseStore.instance;
    final canMark = studentMode && store.isEnrolled(course);
    return [
      const CourseSectionTitle('Contenido del curso'),
      if (course.modules.isEmpty)
        const Text(
          'El profesor aun no agrega modulos.',
          style: TextStyle(color: CoursesColors.muted),
        ),
      for (final m in course.modules)
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
                  canMark
                      ? '${m.lessons.where((l) => store.isLessonDone(course, l.id)).length} de ${m.lessons.length} lecciones'
                      : '${m.lessons.length} lecciones',
                ),
                children: [
                  for (final l in m.lessons)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.play_circle_outline,
                        color: store.isLessonDone(course, l.id) && canMark
                            ? CoursesColors.green600
                            : CoursesColors.gray400,
                      ),
                      title: Text(l.title),
                      subtitle: Text(
                        '${l.duration} - ${l.blocks.length} elementos',
                      ),
                      trailing: canMark
                          ? IconButton(
                              tooltip: store.isLessonDone(course, l.id)
                                  ? 'Marcar como pendiente'
                                  : 'Marcar como completada',
                              icon: Icon(
                                store.isLessonDone(course, l.id)
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked,
                                color: store.isLessonDone(course, l.id)
                                    ? CoursesColors.green600
                                    : CoursesColors.gray400,
                              ),
                              onPressed: () =>
                                  store.toggleLesson(course, l.id),
                            )
                          : null,
                    ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _evaluationsSection() {
    if (course.evaluations.isEmpty) return const [];
    return [
      const CourseSectionTitle('Evaluaciones'),
      for (final e in course.evaluations)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CoursePanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.quiz_outlined,
                color: CoursesColors.green700,
              ),
              title: Text(e.title),
              subtitle: Text('${e.questionCount} preguntas'),
              trailing: e.required
                  ? const CoursePill(text: 'Requerida')
                  : null,
            ),
          ),
        ),
    ];
  }

  List<Widget> _sessionsSection() {
    if (!course.isLive || course.sessions.isEmpty) return const [];
    return [
      const CourseSectionTitle('Sesiones en vivo'),
      for (final s in course.sessions)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CoursePanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.videocam_outlined,
                color: CoursesColors.green700,
              ),
              title: Text(s.title),
              subtitle: Text('${s.date} - ${s.time} - ${s.mode}'),
            ),
          ),
        ),
    ];
  }
}

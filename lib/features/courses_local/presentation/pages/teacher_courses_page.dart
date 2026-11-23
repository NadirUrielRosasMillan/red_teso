import 'package:flutter/material.dart';
import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../local_courses_pages.dart';
import '../theme/courses_theme.dart';
import '../widgets/course_widgets.dart';

/// Panel del profesor: resumen, lista de cursos y acciones rapidas
/// (editar, vista previa, publicar o dejar en borrador, eliminar).
class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  Future<void> _confirmDelete(BuildContext context, LocalCourse c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar curso'),
        content: Text(
          'Se eliminara "${c.title}" con sus modulos y lecciones. Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: CoursesColors.ink,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) LocalCourseStore.instance.removeCourse(c);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: coursesTheme(),
      child: AnimatedBuilder(
        animation: LocalCourseStore.instance,
        builder: (context, _) {
          final courses = LocalCourseStore.instance.manageableCourses;
          final published = courses.where((c) => c.published).length;
          final lessons = courses.fold<int>(0, (s, c) => s + c.lessonCount);
          final enrolled = courses.fold<int>(0, (s, c) => s + c.enrolled);
          final width = MediaQuery.sizeOf(context).width;
          final pad = width >= 640 ? 24.0 : 16.0;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Panel del profesor'),
              actions: [
                IconButton(
                  tooltip: 'Vista alumno',
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentCoursesPage(),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: CoursesColors.green600,
              foregroundColor: CoursesColors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CourseEditorPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear curso'),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 96),
                  children: [
                    if (LocalCourseStore.instance.loading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(),
                      ),
                    if (LocalCourseStore.instance.error != null)
                      CourseErrorBanner(
                        message: LocalCourseStore.instance.error!,
                      ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _stat('${courses.length}', 'Cursos'),
                        _stat('$published', 'Publicados'),
                        _stat('${courses.length - published}', 'Borradores'),
                        _stat('$lessons', 'Lecciones'),
                        _stat('$enrolled', 'Inscritos'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (courses.isEmpty)
                      const _EmptyTeacher()
                    else
                      LayoutBuilder(builder: (context, box) {
                        const gap = 14.0;
                        final cols = box.maxWidth >= 900 ? 2 : 1;
                        final w = (box.maxWidth - gap * (cols - 1)) / cols;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final c in courses)
                              SizedBox(
                                width: w,
                                child: _courseCard(context, c),
                              ),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CoursesColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoursesColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: CoursesColors.green700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: CoursesColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _courseCard(BuildContext context, LocalCourse c) {
    final store = LocalCourseStore.instance;
    return CoursePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CourseCover(course: c),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CoursesColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.modules.length} modulos - ${c.lessonCount} lecciones - ${c.isLive ? 'En linea' : 'Por modulos'}${store.isAdmin && c.ownerName.isNotEmpty ? ' - ${c.ownerName}' : ''}',
                      style: const TextStyle(
                        color: CoursesColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        CoursePill(
                          text: c.published ? 'Publicado' : 'Borrador',
                          background: c.published
                              ? CoursesColors.green600
                              : CoursesColors.gray100,
                          foreground: c.published
                              ? CoursesColors.white
                              : CoursesColors.gray700,
                        ),
                        if (c.certificate) const CertificateBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseEditorPage(course: c),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  foregroundColor: CoursesColors.green800,
                  side: const BorderSide(color: CoursesColors.green300),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoursePreviewPage(course: c),
                  ),
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Vista previa'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  foregroundColor: CoursesColors.gray700,
                  side: const BorderSide(color: CoursesColors.line),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Switch(
                value: c.published,
                activeTrackColor: CoursesColors.green600,
                onChanged: (v) {
                  c.published = v;
                  store.changed();
                },
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Publicado en el catalogo',
                  style: TextStyle(color: CoursesColors.gray700),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar curso',
                icon: const Icon(
                  Icons.delete_outline,
                  color: CoursesColors.muted,
                ),
                onPressed: () => _confirmDelete(context, c),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTeacher extends StatelessWidget {
  const _EmptyTeacher();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.library_books_outlined,
              size: 48, color: CoursesColors.gray400),
          SizedBox(height: 10),
          Text(
            'Aun no tienes cursos. Crea el primero con el boton "Crear curso".',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoursesColors.muted),
          ),
        ],
      ),
    );
  }
}

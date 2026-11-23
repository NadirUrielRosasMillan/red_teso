import 'package:flutter/material.dart';
import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../theme/courses_theme.dart';
import '../widgets/content_viewer.dart';
import '../widgets/course_widgets.dart';

/// Agenda de sesiones en vivo de un curso.
/// Mantiene el nombre y el constructor de la clase original.
class LiveSessionsPage extends StatelessWidget {
  const LiveSessionsPage({super.key, required this.course});

  final LocalCourse course;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: coursesTheme(),
      child: AnimatedBuilder(
        animation: LocalCourseStore.instance,
        builder: (context, _) {
          final sessions = course.sessions;
          return Scaffold(
            appBar: AppBar(title: const Text('Sesiones en vivo')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: CoursesColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sessions.length == 1
                          ? '1 sesion programada'
                          : '${sessions.length} sesiones programadas',
                      style: const TextStyle(color: CoursesColors.muted),
                    ),
                    const SizedBox(height: 16),
                    if (sessions.isEmpty)
                      const _EmptySessions()
                    else
                      for (final s in sessions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SessionCard(session: s),
                        ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final online = session.mode != 'Presencial';
    return CoursePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: CoursesColors.green100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  online ? Icons.videocam : Icons.place_outlined,
                  color: CoursesColors.green700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CoursesColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _meta(Icons.calendar_today_outlined, session.date),
                        _meta(Icons.schedule_outlined, session.time),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CoursePill(
                text: session.mode,
                background: CoursesColors.gray100,
                foreground: CoursesColors.gray700,
              ),
            ],
          ),
          if (session.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              session.description,
              style: const TextStyle(color: CoursesColors.muted, height: 1.4),
            ),
          ],
          if (session.url.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            SelectableText(
              session.url,
              style: const TextStyle(
                color: CoursesColors.green700,
                fontSize: 13,
              ),
            ),
          ],
          if (online) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                if (session.url.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Esta sesion aun no tiene enlace.'),
                    ),
                  );
                } else {
                  openLink(context, session.url);
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Unirme a la sesion'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 44),
                foregroundColor: CoursesColors.green800,
                side: const BorderSide(color: CoursesColors.green300),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: CoursesColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: CoursesColors.gray700, fontSize: 13),
        ),
      ],
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined,
              size: 48, color: CoursesColors.gray400),
          SizedBox(height: 10),
          Text(
            'Aun no hay sesiones programadas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoursesColors.muted),
          ),
        ],
      ),
    );
  }
}

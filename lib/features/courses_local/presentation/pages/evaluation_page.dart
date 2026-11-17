import 'package:flutter/material.dart';

import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../theme/courses_theme.dart';
import '../widgets/course_widgets.dart';

/// Pantalla para resolver una evaluacion. Califica al enviar, muestra la
/// revision con las respuestas correctas y guarda el mejor resultado.
class EvaluationPage extends StatefulWidget {
  const EvaluationPage({
    super.key,
    required this.course,
    required this.evaluation,
  });

  final LocalCourse course;
  final CourseEvaluation evaluation;

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  final Map<String, int> _answers = {};
  EvaluationResult? _result;

  CourseEvaluation get _e => widget.evaluation;

  List<QuizQuestion> get _questions => _e.items;

  void _submit() {
    final r = LocalCourseStore.instance.submitEvaluation(
      widget.course,
      _e,
      _answers,
    );
    setState(() => _result = r);
  }

  void _retry() {
    setState(() {
      _answers.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalCourseStore.instance;
    final best = store.bestScore(widget.course, _e);
    final answered = _questions.where((q) => _answers.containsKey(q.id)).length;

    return Theme(
      data: coursesTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CoursePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _e.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: CoursesColors.ink,
                        ),
                      ),
                      if (_e.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _e.description,
                          style: const TextStyle(color: CoursesColors.muted),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          CoursePill(text: '${_questions.length} preguntas'),
                          CoursePill(
                            text: 'Aprueba con ${_e.passingScore}%',
                            background: CoursesColors.gray100,
                            foreground: CoursesColors.gray700,
                          ),
                          if (_e.required)
                            const CoursePill(
                              text: 'Requerida',
                              background: CoursesColors.green200,
                              foreground: CoursesColors.green900,
                            ),
                          if (best != null)
                            CoursePill(
                              text: 'Tu mejor resultado: $best%',
                              icon: Icons.emoji_events_outlined,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_questions.isEmpty)
                  const CoursePanel(
                    child: Text(
                      'El profesor aun no agrega preguntas a esta evaluacion.',
                      style: TextStyle(color: CoursesColors.muted),
                    ),
                  )
                else if (_result == null)
                  ..._questionsView()
                else
                  ..._reviewView(_result!),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _result == null && _questions.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton(
                    onPressed:
                        answered == _questions.length ? _submit : null,
                    child: Text(
                      answered == _questions.length
                          ? 'Enviar respuestas'
                          : 'Responde todas ($answered de ${_questions.length})',
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  List<Widget> _questionsView() {
    return [
      for (var i = 0; i < _questions.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CoursePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}. ${_questions[i].text}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CoursesColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                for (var o = 0; o < _questions[i].options.length; o++)
                  if (_questions[i].options[o].trim().isNotEmpty)
                    _option(
                      text: _questions[i].options[o],
                      selected: _answers[_questions[i].id] == o,
                      onTap: () =>
                          setState(() => _answers[_questions[i].id] = o),
                    ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _option({
    required String text,
    required bool selected,
    VoidCallback? onTap,
    Color? background,
    Color? border,
    IconData? icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background ??
                (selected ? CoursesColors.green100 : CoursesColors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: border ??
                  (selected ? CoursesColors.green600 : CoursesColors.line),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon ??
                    (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
                size: 20,
                color: iconColor ??
                    (selected
                        ? CoursesColors.green600
                        : CoursesColors.gray400),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: CoursesColors.gray700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _reviewView(EvaluationResult r) {
    return [
      CoursePanel(
        child: Column(
          children: [
            Text(
              '${r.score}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: r.passed ? CoursesColors.green600 : CoursesColors.gray700,
              ),
            ),
            const SizedBox(height: 4),
            CoursePill(
              text: r.passed ? 'Aprobada' : 'No aprobada',
              icon: r.passed ? Icons.check_circle_rounded : Icons.info_outline,
              background:
                  r.passed ? CoursesColors.green600 : CoursesColors.gray100,
              foreground:
                  r.passed ? CoursesColors.white : CoursesColors.gray700,
            ),
            const SizedBox(height: 8),
            Text(
              '${r.correct} de ${r.total} respuestas correctas',
              style: const TextStyle(color: CoursesColors.muted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver al aula'),
                ),
              ],
            ),
          ],
        ),
      ),
      const CourseSectionTitle('Revision'),
      for (var i = 0; i < _questions.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CoursePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}. ${_questions[i].text}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CoursesColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                for (var o = 0; o < _questions[i].options.length; o++)
                  if (_questions[i].options[o].trim().isNotEmpty)
                    _reviewOption(_questions[i], o),
                if (_questions[i].explanation.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _questions[i].explanation,
                    style: const TextStyle(
                      color: CoursesColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
    ];
  }

  Widget _reviewOption(QuizQuestion q, int o) {
    final isCorrect = q.correctIndex == o;
    final chosen = _answers[q.id] == o;
    if (isCorrect) {
      return _option(
        text: q.options[o],
        selected: true,
        background: CoursesColors.green100,
        border: CoursesColors.green600,
        icon: Icons.check_circle_rounded,
        iconColor: CoursesColors.green600,
      );
    }
    if (chosen) {
      return _option(
        text: q.options[o],
        selected: true,
        background: CoursesColors.gray100,
        border: CoursesColors.gray400,
        icon: Icons.cancel_outlined,
        iconColor: CoursesColors.gray700,
      );
    }
    return _option(text: q.options[o], selected: false);
  }
}

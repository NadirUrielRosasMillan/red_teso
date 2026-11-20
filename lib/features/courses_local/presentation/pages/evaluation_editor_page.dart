import 'package:flutter/material.dart';

import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../theme/courses_theme.dart';
import '../widgets/course_widgets.dart';

/// Editor de una evaluacion: preguntas de opcion multiple con una respuesta
/// correcta, calificacion minima y si es requerida para el certificado.
/// Cada cambio se guarda en Firebase junto con el curso.
class EvaluationEditorPage extends StatefulWidget {
  const EvaluationEditorPage({
    super.key,
    required this.course,
    required this.evaluation,
  });

  final LocalCourse course;
  final CourseEvaluation evaluation;

  @override
  State<EvaluationEditorPage> createState() => _EvaluationEditorPageState();
}

class _EvaluationEditorPageState extends State<EvaluationEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _description;

  CourseEvaluation get _e => widget.evaluation;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: _e.title);
    _description = TextEditingController(text: _e.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _changed() => LocalCourseStore.instance.changed();

  bool _valid(QuizQuestion q) {
    if (q.text.trim().isEmpty) return false;
    final filled = q.options.where((o) => o.trim().isNotEmpty).length;
    if (filled < 2) return false;
    if (q.correctIndex < 0 || q.correctIndex >= q.options.length) return false;
    return q.options[q.correctIndex].trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final invalid = _e.items.where((q) => !_valid(q)).length;
    return Theme(
      data: coursesTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar evaluacion')),
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
                      TextField(
                        controller: _title,
                        decoration:
                            const InputDecoration(labelText: 'Titulo'),
                        onChanged: (v) {
                          _e.title = v;
                          _changed();
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _description,
                        maxLines: 2,
                        decoration:
                            const InputDecoration(labelText: 'Instrucciones'),
                        onChanged: (v) {
                          _e.description = v;
                          _changed();
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Calificacion minima para aprobar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: CoursesColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in const [50, 60, 70, 80, 90, 100])
                            ChoiceChip(
                              label: Text('$s%'),
                              selected: _e.passingScore == s,
                              showCheckmark: false,
                              selectedColor: CoursesColors.green200,
                              onSelected: (_) {
                                setState(() => _e.passingScore = s);
                                _changed();
                              },
                            ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _e.required,
                        title: const Text('Requerida para el certificado'),
                        onChanged: (v) {
                          setState(() => _e.required = v);
                          _changed();
                        },
                      ),
                    ],
                  ),
                ),
                const CourseSectionTitle('Preguntas'),
                if (invalid > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CourseErrorBanner(
                      message:
                          '$invalid pregunta(s) incompleta(s). Cada una necesita el enunciado, al menos 2 opciones con texto y una respuesta correcta marcada. Los alumnos las veran asi hasta que las completes.',
                    ),
                  ),
                for (var i = 0; i < _e.items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuestionCard(
                      key: ValueKey(_e.items[i].id),
                      index: i,
                      question: _e.items[i],
                      onChanged: () {
                        _changed();
                        setState(() {});
                      },
                      onDelete: () {
                        setState(() => _e.items.removeAt(i));
                        _changed();
                      },
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _e.items.add(
                        QuizQuestion(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          options: ['', '', ''],
                        ),
                      );
                    });
                    _changed();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar pregunta'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final QuizQuestion question;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late final TextEditingController _text;
  late final TextEditingController _explanation;
  final List<TextEditingController> _options = [];

  QuizQuestion get _q => widget.question;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: _q.text);
    _explanation = TextEditingController(text: _q.explanation);
    for (final o in _q.options) {
      _options.add(TextEditingController(text: o));
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _explanation.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _q.options.add('');
      _options.add(TextEditingController());
    });
    widget.onChanged();
  }

  void _removeOption(int i) {
    setState(() {
      _q.options.removeAt(i);
      _options.removeAt(i).dispose();
      if (_q.correctIndex == i) {
        _q.correctIndex = 0;
      } else if (_q.correctIndex > i) {
        _q.correctIndex -= 1;
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return CoursePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pregunta ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CoursesColors.ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar pregunta',
                icon: const Icon(Icons.delete_outline),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          TextField(
            controller: _text,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(labelText: 'Enunciado'),
            onChanged: (v) {
              _q.text = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Opciones (toca el circulo de la correcta)',
            style: TextStyle(color: CoursesColors.muted, fontSize: 12),
          ),
          for (var i = 0; i < _options.length; i++)
            Row(
              children: [
                IconButton(
                  tooltip: 'Marcar como correcta',
                  icon: Icon(
                    _q.correctIndex == i
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: _q.correctIndex == i
                        ? CoursesColors.green600
                        : CoursesColors.gray400,
                  ),
                  onPressed: () {
                    setState(() => _q.correctIndex = i);
                    widget.onChanged();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _options[i],
                    decoration:
                        InputDecoration(labelText: 'Opcion ${i + 1}'),
                    onChanged: (v) {
                      _q.options[i] = v;
                      widget.onChanged();
                    },
                  ),
                ),
                if (_options.length > 2)
                  IconButton(
                    tooltip: 'Quitar opcion',
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeOption(i),
                  ),
              ],
            ),
          if (_options.length < 6)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar opcion'),
              ),
            ),
          const SizedBox(height: 4),
          TextField(
            controller: _explanation,
            maxLines: 2,
            minLines: 1,
            decoration: const InputDecoration(
              labelText: 'Explicacion de la respuesta (opcional)',
            ),
            onChanged: (v) {
              _q.explanation = v;
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'impulsa_models.dart';

class ImpulsaKanbanBoardView extends StatefulWidget {
  final ImpulsaProject project;
  final bool editable;
  final String currentMemberEmail;
  final Future<void> Function() onSaveProject;

  const ImpulsaKanbanBoardView({
    super.key,
    required this.project,
    required this.editable,
    required this.currentMemberEmail,
    required this.onSaveProject,
  });

  @override
  State<ImpulsaKanbanBoardView> createState() => _ImpulsaKanbanBoardViewState();
}

class _ImpulsaKanbanBoardViewState extends State<ImpulsaKanbanBoardView> {
  static const List<String> _columns = [
    'TRABAJO PENDIENTE',
    'POR HACER',
    'EN CURSO',
    'PRUEBAS',
    'TERMINADO',
  ];

  int? _highlightedColumn;

  Color _colorForMemberIndex(int idx) =>
      ImpulsaPalette.memberColors[idx % ImpulsaPalette.memberColors.length];

  Future<void> _addTaskDialog() async {
    final titleCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '2');
    TaskImportance selectedImportance = TaskImportance.medium;
    final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);

    final createdTask = await showDialog<ImpulsaTask>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: pal.card,
          title: Text(
            '+ Tarea nueva',
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: TextStyle(color: pal.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la tarea',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nivel de importancia en el proyecto',
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskImportance.values.map((imp) {
                    final selected = selectedImportance == imp;
                    return ChoiceChip(
                      label: Text(
                          '${imp.label} (Peso ${imp.defaultWeight.toInt()})'),
                      selected: selected,
                      selectedColor: imp.color.withValues(alpha: 0.22),
                      labelStyle: TextStyle(
                        color: selected ? imp.color : pal.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        setModalState(() {
                          selectedImportance = imp;
                          weightCtrl.text =
                              imp.defaultWeight.toInt().toString();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: pal.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Peso numérico (define el % del proyecto)',
                    hintText: 'Ej. 4 para 40% si el total suma 10',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ImpulsaPalette.buttonGreen,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final w = double.tryParse(weightCtrl.text.trim()) ??
                    selectedImportance.defaultWeight;
                Navigator.pop(
                  ctx,
                  ImpulsaTask(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    title: title,
                    stage: 0,
                    importanceKey: selectedImportance.name,
                    weight: w <= 0 ? 1.0 : w,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    weightCtrl.dispose();

    if (createdTask != null) {
      widget.project.tasks.add(createdTask);
      await widget.onSaveProject();
    }
  }

  Future<void> _moveTaskToStage(ImpulsaTask task, int newStage) async {
    if (!widget.editable || task.stage == newStage) return;
    setState(() {
      task.stage = newStage;
      if (task.assignedEmails.isEmpty &&
          widget.currentMemberEmail.isNotEmpty) {
        task.assignedEmails.add(widget.currentMemberEmail);
      }
    });
    await widget.onSaveProject();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);

    final progressPct = p.weightedProgressPercent;
    final daysRemaining = p.end.difference(DateTime.now()).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pal.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: pal.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _metricChip('Fecha de Inicio', fmtImpulsaDate(p.start), pal),
                  _metricChip('Fecha de Cierre', fmtImpulsaDate(p.end), pal),
                  _metricChip(
                      'Días', '${daysRemaining < 0 ? 0 : daysRemaining}', pal),
                  _metricChip('Avance ponderado', '$progressPct%', pal,
                      highlight: true),
                  _metricChip(
                      'Última actualización', fmtImpulsaDate(p.updatedAt), pal),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: p.weightedProgress,
                  minHeight: 8,
                  color: pal.primary,
                  backgroundColor: pal.badgeBg,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Miembros:',
                          style: TextStyle(
                            color: pal.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        ...p.members.asMap().entries.map((entry) {
                          final color = _colorForMemberIndex(entry.key);
                          final m = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_rounded,
                                    size: 15, color: color),
                                const SizedBox(width: 5),
                                Text(
                                  m.name,
                                  style: TextStyle(
                                    color: pal.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  if (widget.editable)
                    FilledButton.icon(
                      onPressed: _addTaskDialog,
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          size: 18, color: Colors.black),
                      label: const Text('+ Tarea nueva'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ImpulsaPalette.buttonGreen,
                        foregroundColor: Colors.black,
                      ),
                    ),
                ],
              ),
              if (widget.editable) ...[
                const SizedBox(height: 8),
                Text(
                  'Arrastra y suelta las tarjetas entre columnas para actualizar su estado.',
                  style: TextStyle(color: pal.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _columns.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, stageIdx) {
              final columnTasks =
              p.tasks.where((t) => t.stage == stageIdx).toList();
              final isTargetHighlight = _highlightedColumn == stageIdx;

              return DragTarget<ImpulsaTask>(
                onWillAcceptWithDetails: (details) {
                  if (!widget.editable) return false;
                  setState(() => _highlightedColumn = stageIdx);
                  return true;
                },
                onLeave: (_) {
                  if (_highlightedColumn == stageIdx) {
                    setState(() => _highlightedColumn = null);
                  }
                },
                onAcceptWithDetails: (details) async {
                  setState(() => _highlightedColumn = null);
                  await _moveTaskToStage(details.data, stageIdx);
                },
                builder: (context, candidateData, rejectedData) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 255,
                    decoration: BoxDecoration(
                      color: isTargetHighlight ? pal.badgeBg : pal.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isTargetHighlight ? pal.primary : pal.border,
                        width: isTargetHighlight ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: stageIdx == 4 ? pal.badgeBg : pal.subCard,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(13)),
                            border:
                            Border(bottom: BorderSide(color: pal.border)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _columns[stageIdx],
                                style: TextStyle(
                                  color: stageIdx == 4
                                      ? pal.primary
                                      : pal.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: pal.badgeBg,
                                child: Text(
                                  '${columnTasks.length}',
                                  style: TextStyle(
                                    color: pal.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: columnTasks.isEmpty
                              ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                widget.editable
                                    ? 'Suelta una tarea aquí'
                                    : 'Sin tareas',
                                style: TextStyle(
                                  color: pal.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                              : ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: columnTasks.length,
                            itemBuilder: (_, tIdx) {
                              final task = columnTasks[tIdx];
                              return _buildDraggableTaskCard(
                                  task, p, pal);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _metricChip(String label, String value, ImpulsaPalette pal,
      {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: pal.textSecondary, fontSize: 11.5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlight ? pal.primary : pal.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableTaskCard(
      ImpulsaTask task,
      ImpulsaProject p,
      ImpulsaPalette pal,
      ) {
    final cardWidget = _taskCardContent(task, p, pal);
    if (!widget.editable) return cardWidget;

    return Draggable<ImpulsaTask>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 235,
          child: Opacity(opacity: 0.9, child: cardWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: cardWidget),
      child: cardWidget,
    );
  }

  Widget _taskCardContent(
      ImpulsaTask task,
      ImpulsaProject p,
      ImpulsaPalette pal,
      ) {
    final imp = task.importance;
    final pct = task.sharePercentage(p.tasks).round();
    final alreadyTaken =
    task.assignedEmails.contains(widget.currentMemberEmail);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pal.subCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: imp.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: imp.color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${imp.label} · $pct%',
                  style: TextStyle(
                    color: imp.color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.editable)
                Icon(Icons.drag_indicator_rounded,
                    size: 16, color: pal.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: task.assignedEmails.map((email) {
                    final memberIdx = p.members.indexWhere(
                          (m) => m.normalizedEmail == email.toLowerCase(),
                    );
                    final color = _colorForMemberIndex(
                        memberIdx >= 0 ? memberIdx : 0);
                    final initials = memberIdx >= 0
                        ? p.members[memberIdx].initials
                        : 'AL';
                    return Tooltip(
                      message: memberIdx >= 0
                          ? p.members[memberIdx].name
                          : email,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (widget.editable)
                InkWell(
                  onTap: () async {
                    if (alreadyTaken) {
                      task.assignedEmails.remove(widget.currentMemberEmail);
                    } else {
                      task.assignedEmails.add(widget.currentMemberEmail);
                    }
                    await widget.onSaveProject();
                  },
                  child: Text(
                    alreadyTaken ? 'Soltar' : '+ Asignarme',
                    style: TextStyle(
                      color: pal.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
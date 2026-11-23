import 'package:flutter/material.dart';
import '../../models/local_course.dart';
import '../theme/courses_theme.dart';

const String _kOnline = 'En l\u00EDnea';
const String _kInPerson = 'Presencial';

/// Dialogo para programar o editar una sesion. Modifica la sesion recibida
/// y devuelve true si el usuario guardo los cambios.
Future<bool> showSessionForm(
  BuildContext context,
  LiveSession session, {
  bool isNew = false,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _SessionForm(session: session, isNew: isNew),
  );
  return saved ?? false;
}

class _SessionForm extends StatefulWidget {
  const _SessionForm({required this.session, required this.isNew});

  final LiveSession session;
  final bool isNew;

  @override
  State<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<_SessionForm> {
  late final TextEditingController _title;
  late final TextEditingController _date;
  late final TextEditingController _time;
  late final TextEditingController _url;
  late final TextEditingController _description;
  late String _mode;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _title = TextEditingController(text: s.title);
    _date = TextEditingController(text: s.date);
    _time = TextEditingController(text: s.time);
    _url = TextEditingController(text: s.url);
    _description = TextEditingController(text: s.description);
    _mode = s.mode;
  }

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _time.dispose();
    _url.dispose();
    _description.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  DateTime _parseDate() {
    final parts = _date.text.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
    return DateTime.now();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _parseDate();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      setState(() {
        _date.text =
            '${_two(picked.day)}/${_two(picked.month)}/${picked.year}';
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _time.text = '${_two(picked.hour)}:${_two(picked.minute)}';
      });
    }
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el titulo de la sesion.')),
      );
      return;
    }
    final s = widget.session;
    s.title = _title.text.trim();
    s.date = _date.text.trim().isEmpty ? 'Por definir' : _date.text.trim();
    s.time = _time.text.trim().isEmpty ? 'Por definir' : _time.text.trim();
    s.mode = _mode;
    s.url = _url.text.trim();
    s.description = _description.text.trim();
    Navigator.pop(context, true);
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: CoursesColors.gray100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _chip(String value) {
    final selected = _mode == value;
    return ChoiceChip(
      label: Text(value),
      selected: selected,
      showCheckmark: false,
      selectedColor: CoursesColors.green200,
      onSelected: (_) => setState(() => _mode = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: coursesTheme(),
      child: AlertDialog(
        backgroundColor: CoursesColors.white,
        title: Text(widget.isNew ? 'Programar sesion' : 'Editar sesion'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _title,
                  autofocus: widget.isNew,
                  decoration: _decoration('Titulo de la sesion'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _date,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: _decoration(
                    'Fecha',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _time,
                  readOnly: true,
                  onTap: _pickTime,
                  decoration: _decoration(
                    'Hora',
                    icon: Icons.schedule_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [_chip(_kOnline), _chip(_kInPerson)],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _url,
                  decoration: _decoration('Enlace o lugar'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  maxLines: 3,
                  decoration: _decoration('Descripcion'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
    );
  }
}

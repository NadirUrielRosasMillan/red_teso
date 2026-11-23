import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/widgets/theme_toggle_button.dart';
import 'impulsa_models.dart';

class ImpulsaCreateProjectPage extends StatefulWidget {
  final String ownerUid;
  final String ownerEmail;
  final String ownerName;

  const ImpulsaCreateProjectPage({
    super.key,
    required this.ownerUid,
    required this.ownerEmail,
    required this.ownerName,
  });

  @override
  State<ImpulsaCreateProjectPage> createState() =>
      _ImpulsaCreateProjectPageState();
}

class _ImpulsaCreateProjectPageState extends State<ImpulsaCreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _professorCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  final _degreeCtrl =
  TextEditingController(text: 'Ingeniería en Sistemas Computacionales');
  final _teamCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _techCtrl = TextEditingController();

  final _memberNameCtrl = TextEditingController();
  final _memberEmailCtrl = TextEditingController();

  final List<ImpulsaMember> _members = [];
  final List<ImpulsaFile> _files = [];
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _members.add(
      ImpulsaMember(
        name: widget.ownerName,
        email: widget.ownerEmail,
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _professorCtrl.dispose();
    _semesterCtrl.dispose();
    _degreeCtrl.dispose();
    _teamCtrl.dispose();
    _descCtrl.dispose();
    _techCtrl.dispose();
    _memberNameCtrl.dispose();
    _memberEmailCtrl.dispose();
    super.dispose();
  }

  void _addMemberByEmail() {
    final name = _memberNameCtrl.text.trim();
    final email = _memberEmailCtrl.text.trim().toLowerCase();

    if (name.isEmpty || email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Ingresa un nombre completo y un correo electrónico válido'),
        ),
      );
      return;
    }

    if (_members.any((m) => m.normalizedEmail == email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese correo ya está agregado al equipo')),
      );
      return;
    }

    setState(() {
      _members.add(ImpulsaMember(name: name, email: email));
      _memberNameCtrl.clear();
      _memberEmailCtrl.clear();
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _pickCodeFiles() async {
    final selectedFiles = await FilePicker.pickFiles();
    if (!mounted || selectedFiles.isEmpty) return;

    final loaded = <ImpulsaFile>[];
    for (final file in selectedFiles) {
      final bytes = await file.readAsBytes();
      final isZipOrBin = file.name.toLowerCase().endsWith('.zip') ||
          file.name.toLowerCase().endsWith('.rar') ||
          file.name.toLowerCase().endsWith('.exe');
      loaded.add(
        ImpulsaFile(
          path: file.name,
          content: isZipOrBin
              ? '// Paquete comprimido adjunto: ${file.name} (${bytes.length} bytes)'
              : utf8.decode(bytes, allowMalformed: true),
          isBinary: isZipOrBin,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _files.addAll(loaded));
  }

  void _saveProject() {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null || _end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona fechas válidas de inicio y cierre'),
        ),
      );
      return;
    }

    final techs = _techCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final project = ImpulsaProject(
      id: '',
      name: _nameCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      professor: _professorCtrl.text.trim(),
      semester: _semesterCtrl.text.trim(),
      degree: _degreeCtrl.text.trim(),
      team: _teamCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      ownerUid: widget.ownerUid,
      ownerEmail: widget.ownerEmail,
      ownerName: widget.ownerName,
      start: _start!,
      end: _end!,
      technologies: techs,
      members: List<ImpulsaMember>.of(_members),
      files: List<ImpulsaFile>.of(_files),
    );

    Navigator.pop(context, project);
  }

  @override
  Widget build(BuildContext context) {
    final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);
    final wide = MediaQuery.sizeOf(context).width >= 820;

    return Scaffold(
      backgroundColor: pal.bg,
      appBar: AppBar(
        backgroundColor: pal.card,
        surfaceTintColor: pal.card,
        title: Text(
          'Comenzar Proyecto Nuevo',
          style: TextStyle(color: pal.textPrimary, fontWeight: FontWeight.w800),
        ),
        actions: [
          ThemeToggleButton(color: pal.textPrimary),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _academicDataCard(pal)),
                      const SizedBox(width: 18),
                      Expanded(child: _authorsCard(pal)),
                    ],
                  )
                else ...[
                  _academicDataCard(pal),
                  const SizedBox(height: 18),
                  _authorsCard(pal),
                ],
                const SizedBox(height: 18),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _descriptionCard(pal)),
                      const SizedBox(width: 18),
                      Expanded(child: _uploadCodeCard(pal)),
                    ],
                  )
                else ...[
                  _descriptionCard(pal),
                  const SizedBox(height: 18),
                  _uploadCodeCard(pal),
                ],
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saveProject,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Guardar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ImpulsaPalette.flagGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionBox(ImpulsaPalette pal, String title, Widget child) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: pal.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: pal.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _field(
      TextEditingController ctrl,
      String label,
      ImpulsaPalette pal, {
        int lines = 1,
        String? hint,
      }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: lines,
          style: TextStyle(color: pal.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            filled: true,
            fillColor: pal.subCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: pal.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: pal.border),
            ),
          ),
          validator: (v) =>
          v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
        ),
      );

  Widget _academicDataCard(ImpulsaPalette pal) => _sectionBox(
    pal,
    'Datos del Proyecto',
    Column(
      children: [
        _field(_nameCtrl, 'Nombre del proyecto', pal),
        _field(_subjectCtrl, 'Asignatura', pal),
        _field(_professorCtrl, 'Profesor o asesor', pal),
        Row(
          children: [
            Expanded(child: _field(_semesterCtrl, 'Semestre', pal)),
            const SizedBox(width: 10),
            Expanded(child: _field(_degreeCtrl, 'Carrera', pal)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: Icon(Icons.calendar_today_rounded,
                    size: 16, color: pal.primary),
                label: Text(
                  _start == null
                      ? 'Fecha de inicio'
                      : fmtImpulsaDate(_start!),
                  style: TextStyle(color: pal.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: pal.border),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: Icon(Icons.event_available_rounded,
                    size: 16, color: pal.primary),
                label: Text(
                  _end == null
                      ? 'Fecha de cierre'
                      : fmtImpulsaDate(_end!),
                  style: TextStyle(color: pal.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: pal.border),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(_teamCtrl, 'Nombre del equipo', pal),
      ],
    ),
  );

  Widget _authorsCard(ImpulsaPalette pal) => _sectionBox(
    pal,
    'Autores / Integrantes (por Correo)',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etiqueta el proyecto en otros perfiles ingresando su nombre y correo electrónico.',
          style: TextStyle(color: pal.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _memberNameCtrl,
          style: TextStyle(color: pal.textPrimary),
          decoration: InputDecoration(
            labelText: 'Nombre completo del integrante',
            filled: true,
            fillColor: pal.subCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: pal.border),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _memberEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: pal.textPrimary),
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'ejemplo@tesoem.edu.mx',
            filled: true,
            fillColor: pal.subCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: pal.border),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addMemberByEmail,
          icon: Icon(Icons.person_add_alt_1_rounded, color: pal.primary),
          label: Text(
            '+ Agregar al equipo',
            style:
            TextStyle(color: pal.primary, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: pal.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._members.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final isOwner = m.normalizedEmail == widget.ownerEmail;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: pal.subCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: pal.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: pal.badgeBg,
                  child: Text(
                    m.initials,
                    style: TextStyle(
                      color: pal.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: TextStyle(
                          color: pal.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        m.normalizedEmail,
                        style: TextStyle(
                          color: pal.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isOwner)
                  IconButton(
                    tooltip: 'Eliminar integrante',
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Colors.redAccent),
                    onPressed: () => setState(() => _members.removeAt(i)),
                  ),
              ],
            ),
          );
        }),
      ],
    ),
  );

  Widget _descriptionCard(ImpulsaPalette pal) => _sectionBox(
    pal,
    'Descripción general del proyecto',
    Column(
      children: [
        _field(_descCtrl, 'Descripción general', pal, lines: 4),
        _field(
          _techCtrl,
          'Lenguajes o tecnologías (separados por coma)',
          pal,
          hint: 'Ej. Flutter, Dart, Firebase, Python',
        ),
      ],
    ),
  );

  Widget _uploadCodeCard(ImpulsaPalette pal) => _sectionBox(
    pal,
    'Subir código',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _pickCodeFiles,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
            const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: pal.badgeBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: pal.primary.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open_rounded,
                    size: 46, color: pal.primary),
                const SizedBox(height: 8),
                Text(
                  'Seleccionar archivos o carpeta (.zip) de código',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admite archivos fuente (.dart, .java, .py, .c, .js) o proyecto comprimido',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pal.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._files.asMap().entries.map(
                (e) => ListTile(
              dense: true,
              leading: Icon(Icons.insert_drive_file_outlined,
                  color: pal.primary),
              title: Text(e.value.path,
                  style: TextStyle(color: pal.textPrimary)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _files.removeAt(e.key)),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

const _green = Color(0xFF137B4B);
const _dark = Color(0xFF12392D);
const _canvas = Color(0xFFF5F8F6);

class ImpulsaMember {
  final String name;
  final String email;
  final String matricula;
  ImpulsaMember(this.name, this.email, this.matricula);
}

class ImpulsaTask {
  String title;
  int stage;
  String? assignedEmail;
  ImpulsaTask(this.title, {this.stage = 0, this.assignedEmail});
}

class ImpulsaFile {
  String name;
  String content;
  ImpulsaFile(this.name, this.content);
}

class ImpulsaRequest {
  final String email;
  final String message;
  ImpulsaRequest(this.email, this.message);
}

class ImpulsaProject {
  String name, subject, professor, semester, degree, team, description;
  String ownerEmail;
  DateTime start, end;
  List<String> technologies;
  List<ImpulsaMember> members;
  List<ImpulsaFile> files;
  List<ImpulsaTask> tasks;
  List<ImpulsaRequest> requests;
  bool published;
  bool donated;
  ImpulsaProject({
    required this.name, required this.subject, required this.professor,
    required this.semester, required this.degree, required this.team,
    required this.description, required this.ownerEmail,
    required this.start, required this.end, required this.technologies,
    required this.members, List<ImpulsaFile>? files, List<ImpulsaTask>? tasks,
    List<ImpulsaRequest>? requests, this.published = false, this.donated = false,
  }) : files = files ?? [], tasks = tasks ?? [], requests = requests ?? [];

  ImpulsaProject donatedCopy(List<ImpulsaMember> recipients, String newTeam) => ImpulsaProject(
    name: name, subject: subject, professor: professor, semester: semester,
    degree: degree, team: newTeam, description: description,
    ownerEmail: recipients.first.email, start: start, end: end,
    technologies: List.of(technologies), members: List.of(recipients),
    files: files.map((f) => ImpulsaFile(f.name, f.content)).toList(),
    tasks: tasks.map((t) => ImpulsaTask(t.title, stage: t.stage)).toList(),
    donated: true,
  );
}

class AgoraImpulsaPage extends StatefulWidget {
  const AgoraImpulsaPage({super.key});
  @override
  State<AgoraImpulsaPage> createState() => _AgoraImpulsaPageState();
}

class _AgoraImpulsaPageState extends State<AgoraImpulsaPage> {
  final List<ImpulsaProject> projects = [];
  int tab = 0;
  String query = '';
  String get email => FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? 'invitado@agora.local';

  void notify(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  bool isMember(ImpulsaProject p) => p.ownerEmail == email || p.members.any((m) => m.email == email);

  Future<void> create() async {
    final p = await Navigator.push<ImpulsaProject>(context, MaterialPageRoute(builder: (_) => _CreateProjectPage(email: email)));
    if (!mounted || p == null) return;
    setState(() { projects.add(p); tab = 0; });
    notify('Proyecto creado para $email');
  }

  void openProject(ImpulsaProject p) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _ProjectPage(
      project: p, email: email, editable: isMember(p),
      onUpdate: () => setState(() {}),
      onDonate: (copy) => setState(() => projects.add(copy)),
    )));
    if (mounted) setState(() {});
  }

  void showNotifications() {
    final requests = projects.where((p) => p.ownerEmail == email).expand((p) => p.requests.map((r) => (p, r))).toList();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Notificaciones'),
      content: SizedBox(width: 450, child: requests.isEmpty
          ? const Text('No tienes solicitudes nuevas.')
          : ListView(shrinkWrap: true, children: requests.map((entry) => ListTile(
        leading: const Icon(Icons.mark_email_unread_outlined, color: _green),
        title: Text('${entry.$2.email} solicita ${entry.$1.name}'),
        subtitle: Text(entry.$2.message),
      )).toList())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = projects.where((p) {
      final visible = tab == 0 ? isMember(p) : p.published;
      final search = '${p.name} ${p.subject} ${p.description} ${p.technologies.join(' ')}'.toLowerCase();
      return visible && search.contains(query.toLowerCase());
    }).toList();
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white,
          title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.rocket_launch_rounded, color: _green), SizedBox(width: 10), Text('ÁGORA  /  IMPULSA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5))]),
          actions: [IconButton(tooltip: 'Notificaciones', onPressed: showNotifications, icon: const Icon(Icons.notifications_none_rounded)), const SizedBox(width: 12)]),
      body: Row(children: [
        if (wide) Container(width: 230, color: _dark, padding: const EdgeInsets.fromLTRB(14, 28, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.all(12), child: Text('TU ESPACIO', style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold))),
          _sideButton(0, 'Mis Proyectos', Icons.folder_copy_outlined),
          _sideButton(1, 'Red de Proyectos', Icons.public_outlined),
          const Spacer(), Padding(padding: const EdgeInsets.all(12), child: Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ])),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: Padding(
          padding: EdgeInsets.all(wide ? 28 : 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!wide) Padding(padding: const EdgeInsets.only(bottom: 14), child: SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('Mis proyectos')), ButtonSegment(value: 1, label: Text('Red de proyectos'))], selected: {tab}, onSelectionChanged: (s) => setState(() => tab = s.first))),
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 14, runSpacing: 14, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tab == 0 ? 'Mis Proyectos' : 'Red de Proyectos', style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900, color: _dark)), const SizedBox(height: 5), Text(tab == 0 ? 'Tus ideas, tu equipo y tu progreso.' : 'Explora lo que construye la comunidad.', style: const TextStyle(color: Colors.black54))]),
            FilledButton.icon(onPressed: create, icon: const Icon(Icons.add_rounded), label: const Text('Comenzar Proyecto Nuevo'), style: FilledButton.styleFrom(backgroundColor: _green, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18))),
          ]),
          const SizedBox(height: 24),
          TextField(onChanged: (s) => setState(() => query = s), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Buscar por nombre, materia o tecnología', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
          const SizedBox(height: 22),
          Expanded(child: filtered.isEmpty ? _emptyState() : LayoutBuilder(builder: (ctx, c) {
            final columns = c.maxWidth >= 850 ? 3 : c.maxWidth >= 550 ? 2 : 1;
            return GridView.builder(itemCount: filtered.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 245), itemBuilder: (ctx, i) => _projectCard(filtered[i]));
          })),
        ]),
        )))),
      ]),
    );
  }

  Widget _sideButton(int index, String label, IconData icon) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    tileColor: tab == index ? _green : Colors.transparent,
    leading: Icon(icon, color: Colors.white), title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    onTap: () => setState(() => tab = index),
  ));

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.auto_awesome_outlined, size: 68, color: _green), const SizedBox(height: 14),
    Text(tab == 0 ? 'Aquí comienza tu próximo proyecto' : 'Aún no hay proyectos publicados', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _dark)),
    const SizedBox(height: 7), Text(tab == 0 ? 'Crea un proyecto y organiza a tu equipo.' : 'Los proyectos públicos aparecerán aquí.', textAlign: TextAlign.center),
  ]));

  Widget _projectCard(ImpulsaProject p) => Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE4EBE6))), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => openProject(p), child: Padding(padding: const EdgeInsets.all(19), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.folder_special_outlined, color: _green), const Spacer(), if (p.donated) const Chip(label: Text('Donado')), if (p.published) const Icon(Icons.public, color: _green, size: 19)]),
    const SizedBox(height: 13), Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
    const SizedBox(height: 7), Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
    const Spacer(), Wrap(spacing: 5, runSpacing: 3, children: p.technologies.take(3).map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact)).toList()),
    const SizedBox(height: 7), Text('${p.semester}° semestre · ${p.professor}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
  ]))));
}

class _CreateProjectPage extends StatefulWidget {
  final String email;
  const _CreateProjectPage({required this.email});
  @override
  State<_CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<_CreateProjectPage> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(9, (_) => TextEditingController());
  final memberName = TextEditingController();
  final memberEmail = TextEditingController();
  final memberId = TextEditingController();
  final members = <ImpulsaMember>[];
  final files = <ImpulsaFile>[];
  DateTime? start, end;

  @override
  void dispose() { for (final c in fields) { c.dispose(); } memberName.dispose(); memberEmail.dispose(); memberId.dispose(); super.dispose(); }
  Widget input(int i, String label, {int lines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(controller: fields[i], maxLines: lines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null));

  void addMember() {
    if (memberName.text.trim().isEmpty || memberEmail.text.trim().isEmpty || !memberEmail.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe nombre y correo válido del integrante'))); return;
    }
    setState(() => members.add(ImpulsaMember(memberName.text.trim(), memberEmail.text.trim().toLowerCase(), memberId.text.trim())));
    memberName.clear(); memberEmail.clear(); memberId.clear();
  }

  Future<void> pickFiles() async {
    final selectedFiles = await FilePicker.pickFiles();

    if (!mounted || selectedFiles.isEmpty) return;

    final newFiles = <ImpulsaFile>[];

    for (final file in selectedFiles) {
      final bytes = await file.readAsBytes();

      newFiles.add(
        ImpulsaFile(
          file.name,
          utf8.decode(bytes, allowMalformed: true),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      files.addAll(newFiles);
    });
  }

  Future<void> pickDate(bool beginning) async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2040));
    if (date != null) setState(() { if (beginning) { start = date; } else { end = date; } });
  }

  void save() {
    if (!form.currentState!.validate()) return;
    if (start == null || end == null || end!.isBefore(start!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona fechas válidas de inicio y cierre'))); return;
    }
    Navigator.pop(context, ImpulsaProject(
      name: fields[0].text.trim(), subject: fields[1].text.trim(), professor: fields[2].text.trim(),
      semester: fields[3].text.trim(), degree: fields[4].text.trim(), team: fields[5].text.trim(),
      description: fields[6].text.trim(), technologies: fields[7].text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      ownerEmail: widget.email, start: start!, end: end!, members: List.of(members), files: List.of(files),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: _canvas, appBar: AppBar(title: const Text('Comenzar Proyecto Nuevo')), body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850), child: Form(key: form, child: ListView(padding: const EdgeInsets.all(24), children: [
    const Text('Dale forma a tu idea', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _dark)), const SizedBox(height: 8), const Text('Completa los datos académicos y organiza a tu equipo.'), const SizedBox(height: 25),
    input(0, 'Nombre del proyecto'), input(1, 'Asignatura'), input(2, 'Profesor o asesor'), input(3, 'Semestre'), input(4, 'Carrera'), input(5, 'Nombre del equipo'),
    Wrap(spacing: 12, children: [OutlinedButton.icon(onPressed: () => pickDate(true), icon: const Icon(Icons.event), label: Text(start == null ? 'Fecha de inicio' : '${start!.day}/${start!.month}/${start!.year}')), OutlinedButton.icon(onPressed: () => pickDate(false), icon: const Icon(Icons.event_available), label: Text(end == null ? 'Fecha de cierre' : '${end!.day}/${end!.month}/${end!.year}'))]),
    const SizedBox(height: 20), const Text('Integrantes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
    TextField(controller: memberName, decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder())), const SizedBox(height: 10),
    TextField(controller: memberEmail, decoration: const InputDecoration(labelText: 'Correo de inicio de sesión', border: OutlineInputBorder())), const SizedBox(height: 10),
    TextField(controller: memberId, decoration: const InputDecoration(labelText: 'Matrícula (opcional en pruebas)', border: OutlineInputBorder())), const SizedBox(height: 10),
    Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: addMember, icon: const Icon(Icons.person_add_alt_1), label: const Text('Agregar al equipo'))),
    ...members.asMap().entries.map((e) => ListTile(title: Text(e.value.name), subtitle: Text('${e.value.email} · ${e.value.matricula}'), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => members.removeAt(e.key))))),
    const SizedBox(height: 16), input(6, 'Descripción general', lines: 4), input(7, 'Tecnologías (separadas por comas)'),
    const Text('Código fuente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
    OutlinedButton.icon(onPressed: pickFiles, icon: const Icon(Icons.upload_file), label: const Text('Seleccionar archivos de código')),
    const Text('Para una carpeta completa, comprímela como ZIP y selecciónala. Esta demo permite previsualizar archivos de texto.'),
    ...files.map((f) => ListTile(leading: const Icon(Icons.description_outlined), title: Text(f.name))),
    const SizedBox(height: 25), FilledButton.icon(onPressed: save, style: FilledButton.styleFrom(backgroundColor: _green, padding: const EdgeInsets.all(18)), icon: const Icon(Icons.save_outlined), label: const Text('Guardar proyecto')),
  ])))));
}

class _ProjectPage extends StatefulWidget {
  final ImpulsaProject project;
  final String email;
  final bool editable;
  final VoidCallback onUpdate;
  final ValueChanged<ImpulsaProject> onDonate;
  const _ProjectPage({required this.project, required this.email, required this.editable, required this.onUpdate, required this.onDonate});
  @override
  State<_ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<_ProjectPage> {
  int page = 0;
  final stages = const ['TRABAJO PENDIENTE', 'POR HACER', 'EN CURSO', 'PRUEBAS', 'TERMINADO'];
  ImpulsaProject get p => widget.project;
  void message(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<String?> prompt(String title, {String initial = ''}) async {
    final c = TextEditingController(text: initial);
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: TextField(controller: c, autofocus: true, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Guardar'))]));
    c.dispose(); return value;
  }

  Future<void> upload() async {
    final selectedFiles = await FilePicker.pickFiles();

    if (!mounted || selectedFiles.isEmpty) return;

    final newFiles = <ImpulsaFile>[];

    for (final file in selectedFiles) {
      final bytes = await file.readAsBytes();

      newFiles.add(
        ImpulsaFile(
          file.name,
          utf8.decode(bytes, allowMalformed: true),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      for (final file in newFiles) {
        p.files.removeWhere((existing) => existing.name == file.name);
        p.files.add(file);
      }
    });

    widget.onUpdate();
    message('Archivos agregados a esta sesión');
  }

  Future<void> editFile(ImpulsaFile f) async {
    if (!widget.editable) { message('Vista de solo lectura'); return; }
    final updated = await prompt('Editar ${f.name}', initial: f.content);
    if (updated != null) { setState(() => f.content = updated); widget.onUpdate(); }
  }

  Future<void> request() async {
    final reason = await prompt('¿Por qué te interesa este proyecto?');
    if (reason == null || reason.isEmpty) return;
    setState(() => p.requests.add(ImpulsaRequest(widget.email, reason)));
    widget.onUpdate(); message('Solicitud enviada (demo local)');
  }

  Future<void> donate() async {
    final email = await prompt('Correo del estudiante receptor');
    if (email == null || !email.contains('@')) return;
    final team = await prompt('Nombre del equipo receptor');
    if (team == null || team.isEmpty) return;
    final copy = p.donatedCopy([ImpulsaMember(email.split('@').first, email.toLowerCase(), '')], team);
    widget.onDonate(copy); message('Copia independiente creada (demo local)');
  }

  Future<void> newTask() async {
    final title = await prompt('Nueva tarea');
    if (title == null || title.isEmpty) return;
    setState(() => p.tasks.add(ImpulsaTask(title)));
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final own = p.ownerEmail == widget.email;
    return Scaffold(backgroundColor: _canvas, appBar: AppBar(title: Text(p.name), actions: [if (widget.editable) IconButton(tooltip: 'Subir código', onPressed: upload, icon: const Icon(Icons.upload_file_outlined))]),
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 9, runSpacing: 9, children: [
            ChoiceChip(label: const Text('Detalles y archivos'), selected: page == 0, onSelected: (_) => setState(() => page = 0)),
            ChoiceChip(label: const Text('Tablero Kanban'), selected: page == 1, onSelected: (_) => setState(() => page = 1)),
            if (own) ChoiceChip(label: Text('Solicitudes (${p.requests.length})'), selected: page == 2, onSelected: (_) => setState(() => page = 2)),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (own) OutlinedButton.icon(onPressed: () { setState(() => p.published = !p.published); widget.onUpdate(); }, icon: Icon(p.published ? Icons.public_off : Icons.public), label: Text(p.published ? 'Retirar publicación' : 'Publicar')),
            if (own) OutlinedButton.icon(onPressed: donate, icon: const Icon(Icons.volunteer_activism_outlined), label: const Text('Donar')),
            if (!widget.editable) FilledButton.icon(onPressed: request, icon: const Icon(Icons.send_outlined), label: const Text('Solicitar')),
            if (widget.editable) OutlinedButton.icon(onPressed: upload, icon: const Icon(Icons.upload_file), label: const Text('Subir / actualizar código')),
          ]),
          const SizedBox(height: 18),
          Expanded(child: page == 1 ? _kanban() : page == 2 ? _requests() : _details()),
        ])))));
  }

  Widget _details() => ListView(children: [
    Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(p.name, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _dark)), const SizedBox(height: 8), Text(p.description), const SizedBox(height: 16),
      Text('Asignatura: ${p.subject}  ·  Asesor: ${p.professor}'), Text('Carrera: ${p.degree}  ·  Semestre: ${p.semester}'),
      Text('Equipo: ${p.team}  ·  Integrantes: ${p.members.map((m) => m.name).join(', ')}'),
      Text('Inicio: ${p.start.day}/${p.start.month}/${p.start.year}  ·  Cierre: ${p.end.day}/${p.end.month}/${p.end.year}'),
      Wrap(spacing: 7, children: p.technologies.map((t) => Chip(label: Text(t))).toList()),
    ]))),
    const SizedBox(height: 12), const Padding(padding: EdgeInsets.all(8), child: Text('Explorador de código', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
    if (p.files.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Todavía no hay archivos. Puedes subir código desde el botón superior.')),
    ...p.files.map((f) => Card(color: Colors.white, child: ListTile(leading: const Icon(Icons.code, color: _green), title: Text(f.name), subtitle: Text(f.content, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right), onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(f.name), content: SizedBox(width: 650, height: 350, child: SingleChildScrollView(child: SelectableText(f.content))), actions: [if (widget.editable) TextButton(onPressed: () { Navigator.pop(ctx); editFile(f); }, child: const Text('Editar')), TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))]))))),
  ]);

  Widget _kanban() {
    final total = p.tasks.length;
    final done = p.tasks.where((t) => t.stage == 4).length;
    final progress = total == 0 ? 0.0 : done / total;
    final days = p.end.difference(DateTime.now()).inDays;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 20, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('Progreso: ${(progress * 100).round()}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Días restantes: ${days < 0 ? 0 : days}'),
        if (widget.editable) FilledButton.icon(onPressed: newTask, icon: const Icon(Icons.add), label: const Text('Tarea nueva'), style: FilledButton.styleFrom(backgroundColor: _green)),
      ]),
      const SizedBox(height: 10), LinearProgressIndicator(value: progress, minHeight: 9, color: _green, backgroundColor: const Color(0xFFDDE9E0), borderRadius: BorderRadius.circular(8)),
      const SizedBox(height: 20),
      Expanded(child: ListView(scrollDirection: Axis.horizontal, children: List.generate(5, (stage) => Container(width: 255, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEAF1EC), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stages[stage], style: const TextStyle(fontWeight: FontWeight.w900, color: _dark)), const SizedBox(height: 14),
        Expanded(child: ListView(children: p.tasks.where((t) => t.stage == stage).map((t) => Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)), if (t.assignedEmail != null) Text(t.assignedEmail!, style: const TextStyle(fontSize: 11, color: _green)),
          if (widget.editable) Wrap(spacing: 4, children: [TextButton(onPressed: () { setState(() => t.assignedEmail = widget.email); widget.onUpdate(); }, child: const Text('Tomar')), PopupMenuButton<int>(tooltip: 'Mover tarea', icon: const Icon(Icons.more_horiz), onSelected: (value) { setState(() => t.stage = value); widget.onUpdate(); }, itemBuilder: (_) => List.generate(5, (i) => PopupMenuItem(value: i, child: Text(stages[i]))))]),
        ])))).toList())),
      ]))))),
    ]);
  }

  Widget _requests() => ListView(children: [
    if (p.requests.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Aún no hay solicitudes para este proyecto.')),
    ...p.requests.map((r) => Card(color: Colors.white, child: ListTile(leading: const Icon(Icons.mark_email_unread_outlined, color: _green), title: Text(r.email), subtitle: Text(r.message)))),
  ]);
}

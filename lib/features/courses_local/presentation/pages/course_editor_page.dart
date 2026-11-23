import 'package:flutter/material.dart';

import '../../data/learning_storage.dart';
import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../theme/courses_theme.dart';
import '../widgets/course_widgets.dart';
import '../widgets/session_form_dialog.dart';
import 'course_detail_page.dart';
import 'evaluation_editor_page.dart';

const List<String> kCourseCategories = [
  'Programacion y Desarrollo de Software',
  'Ciberseguridad',
  'Redes y Telecomunicaciones',
  'Ciencia de Datos e Inteligencia Artificial',
  'Negocios y Emprendimiento',
  'Habilidades Blandas',
  'Idiomas',
  'Ingenieria y Energias Renovables',
];

const List<String> kCourseCareers = [
  'Ingenieria Ambiental',
  'Ingenieria Industrial',
  'Ingenieria en Sistemas Computacionales',
  'Ingenieria en Tecnologias de la Informacion y Comunicaciones',
  'Ingenieria en Administracion',
  'Ingenieria en Sistemas Automotrices',
  'Ingenieria en Energias Renovables',
  'Contador Publico',
  'Licenciatura en Gastronomia',
];

/// Editor de cursos del profesor: informacion general, contenido (modulos,
/// lecciones y bloques), evaluaciones, sesiones y ajustes.
/// Mantiene el nombre y constructor de la clase original.
class CourseEditorPage extends StatefulWidget {
  const CourseEditorPage({super.key, this.course});

  final LocalCourse? course;

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage>
    with SingleTickerProviderStateMixin {
  late final LocalCourse _course;
  late bool _isNew;
  late final TabController _tabs;

  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _description;
  late final TextEditingController _objectives;
  late final TextEditingController _requirements;
  late final TextEditingController _instructor;
  late final TextEditingController _video;
  late final TextEditingController _duration;
  late final TextEditingController _price;

  late String _category;
  late Set<String> _careers;
  late String _level;
  late String _modality;
  late String _currency;
  late bool _published;
  late bool _certificate;
  late int _minProgress;
  late bool _requireEvals;

  String? _lessonId;
  bool _saving = false;
  bool _uploadingCover = false;

  LocalCourseStore get _store => LocalCourseStore.instance;

  @override
  void initState() {
    super.initState();
    final existing = widget.course;
    _isNew = existing == null;
    _course = existing ??
        LocalCourse(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: '',
          category: kCourseCategories.first,
          description: '',
          published: false,
          instructor: _store.userName,
        );
    final c = _course;

    _title = TextEditingController(text: c.title);
    _summary = TextEditingController(text: c.summary);
    _description = TextEditingController(text: c.description);
    _objectives = TextEditingController(text: c.objectives.join('\n'));
    _requirements = TextEditingController(text: c.requirements.join('\n'));
    _instructor = TextEditingController(text: c.instructor);
    _video = TextEditingController(text: c.videoUrl);
    _duration = TextEditingController(text: c.duration);
    _price = TextEditingController(
      text: c.price == 0 ? '0' : c.price.toString(),
    );

    _category = c.category;
    _careers = c.career == 'Todas las carreras'
        ? <String>{}
        : c.careerList.toSet();
    _level = c.level;
    _modality = c.modality;
    _currency = c.currency;
    _published = c.published;
    _certificate = c.certificate;
    _minProgress = c.certificateMinProgress;
    _requireEvals = c.certificateRequiresEvaluations;

    _tabs = TabController(length: 5, vsync: this);
    _title.addListener(_refresh);
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _title,
      _summary,
      _description,
      _objectives,
      _requirements,
      _instructor,
      _video,
      _duration,
      _price,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _say(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Contenido modificado (modulos, lecciones, bloques): se guarda solo.
  void _changed() {
    _store.changed();
    if (mounted) setState(() {});
  }

  // ----------------------------------------------------------- guardado

  void _apply() {
    final c = _course;
    List<String> lines(TextEditingController t) => t.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    c.title = _title.text.trim();
    c.summary = _summary.text.trim();
    c.description = _description.text.trim();
    c.instructor = _instructor.text.trim();
    c.videoUrl = _video.text.trim();
    c.duration =
        _duration.text.trim().isEmpty ? '10 horas' : _duration.text.trim();
    c.price = double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;
    c.category = _category;
    c.career = _careers.isEmpty ? 'Todas las carreras' : _careers.join('|');
    c.level = _level;
    c.modality = _modality;
    c.currency = _currency;
    c.published = _published;
    c.certificate = _certificate;
    c.certificateMinProgress = _minProgress;
    c.certificateRequiresEvaluations = _requireEvals;
    c.objectives
      ..clear()
      ..addAll(lines(_objectives));
    c.requirements
      ..clear()
      ..addAll(lines(_requirements));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      _say('Escribe el titulo del curso.');
      _tabs.animateTo(0);
      return;
    }
    setState(() => _saving = true);
    _apply();
    if (_isNew) {
      _store.addCourse(_course);
      _isNew = false;
    }
    final err = await _store.saveCourse(_course);
    if (!mounted) return;
    setState(() => _saving = false);
    _say(err ?? 'Curso guardado en Firebase.');
  }

  Future<void> _pickCover() async {
    setState(() => _uploadingCover = true);
    try {
      final up = await LearningStorage.pickAndUpload(
        courseId: _course.id,
        extensions: LearningStorage.imageExtensions,
        maxMb: 4,
      );
      if (up != null) {
        _course.coverUrl = up.url;
        _changed();
        if (mounted) {
          _say(_isNew
              ? 'Portada lista. Pulsa Guardar cambios para crear el curso.'
              : 'Portada actualizada.');
        }
      }
    } catch (e) {
      if (mounted) _say(e.toString());
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  // ------------------------------------------------------------- piezas

  InputDecoration _deco(String? hint) {
    OutlineInputBorder border(Color color, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: w),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: CoursesColors.white,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(CoursesColors.line),
      enabledBorder: border(CoursesColors.line),
      focusedBorder: border(CoursesColors.green600, 1.6),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: CoursesColors.ink,
          ),
        ),
      );

  Widget _helper(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style: const TextStyle(color: CoursesColors.muted, fontSize: 12),
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    int? minLines,
    int? maxLength,
    String? hint,
    String? helper,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            keyboardType: keyboard,
            decoration: _deco(hint),
          ),
          if (helper != null) _helper(helper),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) {
    final items = Map<String, String>.of(options);
    if (!items.containsKey(value)) items[value] = value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          DropdownButtonFormField<String>(
            key: ValueKey('$label|$value'),
            initialValue: value,
            isExpanded: true,
            decoration: _deco(null),
            items: [
              for (final e in items.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CoursePanel(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: CoursesColors.ink,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<String?> _ask(String title, {String initial = ''}) async {
    final ctl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: _deco('Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctl.dispose();
    return result;
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CoursesColors.ink),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    return Theme(
      data: coursesTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Crear curso' : 'Editar curso'),
          actions: [
            if (wide)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: OutlinedButton(
                  onPressed: () {
                    _apply();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CoursePreviewPage(course: _course),
                      ),
                    );
                  },
                  child: const Text('Ver curso'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CoursePrimaryButton(
                label: _saving ? 'Guardando...' : 'Guardar cambios',
                icon: Icons.save_outlined,
                small: true,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 12, wide ? 24 : 12, 0),
                  child: _header(wide),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 12, wide ? 24 : 12, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CoursesColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CoursesColors.line),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: CoursesColors.green700,
                      unselectedLabelColor: CoursesColors.muted,
                      indicatorColor: CoursesColors.green600,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                      tabs: const [
                        Tab(text: 'Informacion general'),
                        Tab(text: 'Contenido'),
                        Tab(text: 'Evaluaciones'),
                        Tab(text: 'Sesiones'),
                        Tab(text: 'Ajustes'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _infoTab(wide),
                      _contentTab(width),
                      _evaluationsTab(),
                      _sessionsTab(),
                      _settingsTab(wide),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool wide) {
    final title = _title.text.trim();
    return CoursePanel(
      padding: EdgeInsets.all(wide ? 16 : 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: wide ? 160 : 92,
              height: wide ? 104 : 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CourseCover(course: _course),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _uploadingCover ? null : _pickCover,
                      child: Container(
                        color: CoursesColors.ink.withValues(alpha: 0.65),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _uploadingCover
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: CoursesColors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 14,
                                    color: CoursesColors.white,
                                  ),
                            if (wide) ...[
                              const SizedBox(width: 6),
                              const Text(
                                'Cambiar portada',
                                style: TextStyle(
                                  color: CoursesColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isNew ? 'Nuevo curso' : 'Editar curso',
                  style: const TextStyle(
                    color: CoursesColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title.isEmpty ? 'Curso sin titulo' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: wide ? 26 : 18,
                    fontWeight: FontWeight.w800,
                    color: CoursesColors.ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                CoursePill(
                  text: _published ? 'Publicado' : 'Borrador',
                  background:
                      _published ? CoursesColors.green100 : CoursesColors.gray100,
                  foreground:
                      _published ? CoursesColors.green800 : CoursesColors.gray700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------- informacion general

  Widget _infoTab(bool wide) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card('Informacion del curso', [
          _field('Titulo del curso', _title),
          _field(
            'Resumen',
            _summary,
            maxLength: 140,
            maxLines: 2,
            helper: 'Aparece en la tarjeta del catalogo. Maximo 140 caracteres.',
          ),
          _field('Descripcion', _description, maxLines: 8, minLines: 6),
        ]),
        _card('Objetivos y requisitos', [
          _field(
            'Que van a lograr (uno por linea)',
            _objectives,
            maxLines: 5,
            minLines: 3,
          ),
          _field(
            'Requisitos (uno por linea)',
            _requirements,
            maxLines: 4,
            minLines: 2,
          ),
        ]),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card('Video de presentacion', [
          _field(
            'Enlace (opcional)',
            _video,
            hint: 'https://www.youtube.com/watch?v=...',
            keyboard: TextInputType.url,
            helper:
                'YouTube o Vimeo. La portada se cambia desde la imagen de arriba (JPG, PNG o WEBP, maximo 4 MB).',
          ),
        ]),
        _card('Docente', [
          _field('Nombre del instructor', _instructor),
        ]),
        _card('Carreras relacionadas', [
          Wrap(
            spacing: 12,
            runSpacing: 0,
            children: [
              for (final career in kCourseCareers)
                SizedBox(
                  width: wide ? 250 : double.infinity,
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: CoursesColors.green600,
                    value: _careers.contains(career),
                    title: Text(career, style: const TextStyle(fontSize: 14)),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _careers.add(career);
                      } else {
                        _careers.remove(career);
                      }
                    }),
                  ),
                ),
            ],
          ),
          _helper(
            'Marca las carreras a las que va dirigido el curso. Sin marcar, aplica a todas.',
          ),
        ]),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 16, wide ? 24 : 12, 40),
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: left),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: right),
            ],
          )
        else ...[
          left,
          right,
        ],
      ],
    );
  }

  // --------------------------------------------------------------- contenido

  CourseLesson? get _lesson {
    for (final m in _course.modules) {
      for (final l in m.lessons) {
        if (l.id == _lessonId) return l;
      }
    }
    return null;
  }

  CourseModule? get _lessonModule {
    for (final m in _course.modules) {
      for (final l in m.lessons) {
        if (l.id == _lessonId) return m;
      }
    }
    return null;
  }

  Widget _contentTab(double width) {
    final lesson = _lesson;
    final module = _lessonModule;
    final pad = width >= 900 ? 24.0 : 12.0;

    if (width >= 1000) {
      return ListView(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 40),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 300, child: _modulesPane()),
              const SizedBox(width: 16),
              Expanded(
                child: lesson == null
                    ? _noLesson()
                    : _lessonEditor(lesson),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 280,
                child: lesson == null || module == null
                    ? const SizedBox.shrink()
                    : _lessonOptions(lesson, module),
              ),
            ],
          ),
        ],
      );
    }

    // Pantallas estrechas: primero el esquema, luego la leccion elegida.
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 40),
      children: [
        if (lesson == null || module == null)
          _modulesPane()
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _lessonId = null),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Modulos del curso'),
            ),
          ),
          _lessonEditor(lesson),
          const SizedBox(height: 16),
          _lessonOptions(lesson, module),
        ],
      ],
    );
  }

  Widget _noLesson() {
    return const CoursePanel(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.edit_note_rounded, size: 44, color: CoursesColors.gray400),
          SizedBox(height: 10),
          Text(
            'Selecciona una leccion o agrega una nueva para editarla.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoursesColors.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _addModule() async {
    final name = await _ask('Nuevo modulo');
    if (name == null || name.isEmpty) return;
    _store.addModule(_course, name);
    setState(() {});
  }

  Future<void> _addLesson(CourseModule m) async {
    final name = await _ask('Nueva leccion');
    if (name == null || name.isEmpty) return;
    _store.addLesson(m, name);
    setState(() => _lessonId = m.lessons.last.id);
  }

  Future<void> _moduleAction(String action, int index) async {
    final modules = _course.modules;
    final m = modules[index];
    switch (action) {
      case 'rename':
        final name = await _ask('Renombrar modulo', initial: m.title);
        if (name != null && name.isNotEmpty) {
          m.title = name;
          _changed();
        }
        break;
      case 'up':
        if (index > 0) {
          modules.removeAt(index);
          modules.insert(index - 1, m);
          _changed();
        }
        break;
      case 'down':
        if (index < modules.length - 1) {
          modules.removeAt(index);
          modules.insert(index + 1, m);
          _changed();
        }
        break;
      case 'delete':
        if (await _confirm(
          'Eliminar modulo',
          'Se eliminara "${m.title}" con todas sus lecciones.',
        )) {
          if (m.lessons.any((l) => l.id == _lessonId)) _lessonId = null;
          modules.removeAt(index);
          _changed();
        }
        break;
    }
  }

  Widget _modulesPane() {
    final modules = _course.modules;
    return CoursePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Modulos del curso',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CoursesColors.ink,
                  ),
                ),
              ),
              CoursePrimaryButton(
                label: '+ Agregar modulo',
                small: true,
                onPressed: _addModule,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (modules.isEmpty)
            const Text(
              'Aun no hay modulos. Agrega el primero para crear lecciones.',
              style: TextStyle(color: CoursesColors.muted),
            ),
          for (var i = 0; i < modules.length; i++) _moduleCard(i, modules[i]),
        ],
      ),
    );
  }

  Widget _moduleCard(int index, CourseModule m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoursesColors.line),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(seedColor: CoursesColors.primary),
        ),
        child: ExpansionTile(
          key: PageStorageKey('module_${m.id}'),
          initiallyExpanded: true,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.only(left: 14, right: 4),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          title: Text(
            m.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            '${m.lessons.length} lecciones',
            style: const TextStyle(color: CoursesColors.muted, fontSize: 12),
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'Opciones del modulo',
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (a) => _moduleAction(a, index),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Renombrar')),
              PopupMenuItem(value: 'up', child: Text('Subir')),
              PopupMenuItem(value: 'down', child: Text('Bajar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
          children: [
            for (final l in m.lessons) _lessonTile(l),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _addLesson(m),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CoursesColors.green700,
                  side: const BorderSide(color: CoursesColors.green300),
                  minimumSize: const Size(48, 42),
                ),
                child: const Text('+ Agregar leccion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lessonTile(CourseLesson l) {
    final selected = l.id == _lessonId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _lessonId = l.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? CoursesColors.green100 : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                l.blocks.any((b) => b.kind == ContentKind.image)
                    ? Icons.image_outlined
                    : Icons.play_circle_outline,
                size: 18,
                color: selected
                    ? CoursesColors.green700
                    : CoursesColors.gray400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? CoursesColors.green900
                        : CoursesColors.gray700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addBlock(CourseLesson lesson, ContentKind kind) {
    lesson.blocks.add(
      ContentBlock(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        kind: kind,
      ),
    );
    _changed();
  }

  Widget _lessonEditor(CourseLesson lesson) {
    return CoursePanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar leccion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: CoursesColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          _label('Titulo de la leccion'),
          TextFormField(
            key: ValueKey('lesson_title_${lesson.id}'),
            initialValue: lesson.title,
            decoration: _deco(null),
            onChanged: (v) {
              lesson.title = v;
              _changed();
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              Text(
                'Tipo de contenido ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: CoursesColors.ink,
                ),
              ),
              Text(
                '(cada boton agrega un elemento a la leccion)',
                style: TextStyle(color: CoursesColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in ContentKind.values)
                OutlinedButton.icon(
                  onPressed: () => _addBlock(lesson, k),
                  icon: Icon(contentKindIcon(k), size: 18),
                  label: Text(contentKindLabel(k)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CoursesColors.gray700,
                    side: const BorderSide(color: CoursesColors.line),
                    minimumSize: const Size(48, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (lesson.blocks.isEmpty)
            const Text(
              'Esta leccion aun no tiene contenido. Usa los botones de arriba para agregar texto, imagenes, videos o archivos.',
              style: TextStyle(color: CoursesColors.muted),
            ),
          for (var i = 0; i < lesson.blocks.length; i++)
            _BlockEditorCard(
              key: ValueKey(lesson.blocks[i].id),
              block: lesson.blocks[i],
              index: i,
              total: lesson.blocks.length,
              courseId: _course.id,
              onChanged: _changed,
              onMove: (delta) {
                final j = i + delta;
                if (j < 0 || j >= lesson.blocks.length) return;
                final b = lesson.blocks.removeAt(i);
                lesson.blocks.insert(j, b);
                _changed();
              },
              onDelete: () {
                lesson.blocks.removeAt(i);
                _changed();
              },
            ),
        ],
      ),
    );
  }

  Widget _lessonOptions(CourseLesson lesson, CourseModule module) {
    final index = module.lessons.indexOf(lesson);
    return CoursePanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opciones de la leccion',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: CoursesColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Orden en el modulo (${index + 1} de ${module.lessons.length})',
            style: const TextStyle(color: CoursesColors.green700, fontSize: 13),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Subir',
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                onPressed: index > 0
                    ? () {
                        module.lessons.removeAt(index);
                        module.lessons.insert(index - 1, lesson);
                        _changed();
                      }
                    : null,
              ),
              IconButton(
                tooltip: 'Bajar',
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                onPressed: index < module.lessons.length - 1
                    ? () {
                        module.lessons.removeAt(index);
                        module.lessons.insert(index + 1, lesson);
                        _changed();
                      }
                    : null,
              ),
              IconButton(
                tooltip: 'Eliminar leccion',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await _confirm(
                    'Eliminar leccion',
                    'Se eliminara "${lesson.title}".',
                  )) {
                    module.lessons.remove(lesson);
                    _lessonId = null;
                    _changed();
                  }
                },
              ),
            ],
          ),
          const Divider(height: 24),
          _dropdown(
            'Pertenece al modulo',
            module.id,
            {for (final m in _course.modules) m.id: m.title},
            (id) {
              if (id == module.id) return;
              final target = _course.modules.firstWhere((m) => m.id == id);
              module.lessons.remove(lesson);
              target.lessons.add(lesson);
              _changed();
            },
          ),
          _label('Duracion'),
          TextFormField(
            key: ValueKey('lesson_duration_${lesson.id}'),
            initialValue: lesson.duration,
            decoration: _deco('15 min'),
            onChanged: (v) {
              lesson.duration = v.trim().isEmpty ? '15 min' : v.trim();
              _store.changed();
            },
          ),
          const SizedBox(height: 14),
          _label('Descripcion breve'),
          TextFormField(
            key: ValueKey('lesson_desc_${lesson.id}'),
            initialValue: lesson.description,
            maxLines: 3,
            decoration: _deco(null),
            onChanged: (v) {
              lesson.description = v;
              _store.changed();
            },
          ),
          const SizedBox(height: 16),
          CoursePrimaryButton(
            label: _saving ? 'Guardando...' : 'Guardar cambios',
            expand: true,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ evaluaciones

  Widget _evaluationsTab() {
    final width = MediaQuery.sizeOf(context).width;
    final pad = width >= 900 ? 24.0 : 12.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 40),
      children: [
        _card(
          'Evaluaciones del curso',
          [
            const Text(
              'Crea cuestionarios de opcion multiple. Los alumnos los resuelven en el aula y se califican al enviar. Las marcadas como requeridas condicionan el certificado.',
              style: TextStyle(color: CoursesColors.muted),
            ),
            const SizedBox(height: 12),
            if (_course.evaluations.isEmpty)
              const Text(
                'Aun no hay evaluaciones.',
                style: TextStyle(color: CoursesColors.gray700),
              ),
            for (final e in _course.evaluations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.quiz_outlined,
                    color: CoursesColors.green700),
                title: Text(e.title),
                subtitle: Text(
                  '${e.questionCount} preguntas - aprueba con ${e.passingScore}%${e.required ? ' - Requerida' : ''}',
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EvaluationEditorPage(
                        course: _course,
                        evaluation: e,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
                trailing: IconButton(
                  tooltip: 'Eliminar evaluacion',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await _confirm(
                      'Eliminar evaluacion',
                      'Se eliminara "${e.title}".',
                    )) {
                      _course.evaluations.remove(e);
                      _changed();
                    }
                  },
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: CoursePrimaryButton(
                label: '+ Agregar evaluacion',
                small: true,
                onPressed: () async {
                  final n = await _ask('Nueva evaluacion');
                  if (n == null || n.isEmpty) return;
                  final e = CourseEvaluation(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    title: n,
                  );
                  _course.evaluations.add(e);
                  _changed();
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EvaluationEditorPage(
                        course: _course,
                        evaluation: e,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- sesiones

  Widget _sessionsTab() {
    final width = MediaQuery.sizeOf(context).width;
    final pad = width >= 900 ? 24.0 : 12.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 40),
      children: [
        _card(
          'Sesiones en vivo',
          [
            const Text(
              'Programa clases virtuales o presenciales. El alumno ve la agenda desde el aula y entra con el enlace.',
              style: TextStyle(color: CoursesColors.muted),
            ),
            const SizedBox(height: 12),
            if (_course.sessions.isEmpty)
              const Text(
                'Aun no hay sesiones programadas.',
                style: TextStyle(color: CoursesColors.gray700),
              ),
            for (final s in _course.sessions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.videocam,
                    color: CoursesColors.green700),
                title: Text(s.title),
                subtitle: Text('${s.date} - ${s.time} - ${s.mode}'),
                onTap: () async {
                  if (await showSessionForm(context, s)) _changed();
                },
                trailing: IconButton(
                  tooltip: 'Eliminar sesion',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    _course.sessions.remove(s);
                    _changed();
                  },
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: CoursePrimaryButton(
                label: '+ Programar sesion',
                small: true,
                onPressed: () async {
                  final s = LiveSession(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    title: '',
                  );
                  if (await showSessionForm(context, s, isNew: true)) {
                    _course.sessions.add(s);
                    _changed();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- ajustes

  Widget _settingsTab(bool wide) {
    final categories = {for (final c in kCourseCategories) c: c};

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card('Clasificacion', [
          _dropdown(
            'Tipo de curso',
            _modality,
            const {
              'modulos': 'Por modulos (a tu ritmo)',
              'en_linea': 'En linea con clases en vivo',
            },
            (v) => setState(() => _modality = v),
          ),
          _dropdown(
            'Categoria',
            _category,
            categories,
            (v) => setState(() => _category = v),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dropdown(
                  'Nivel de dificultad',
                  _level,
                  const {
                    kLevelBasic: kLevelBasic,
                    'Intermedio': 'Intermedio',
                    'Avanzado': 'Avanzado',
                  },
                  (v) => setState(() => _level = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _field('Duracion', _duration, hint: '72 horas')),
            ],
          ),
        ]),
        _card('Precio', [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  'Precio por persona (0 = gratis)',
                  _price,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown(
                  'Moneda',
                  _currency,
                  const {'MXN': 'MXN - Peso mexicano', 'USD': 'USD - Dolar'},
                  (v) => setState(() => _currency = v),
                ),
              ),
            ],
          ),
        ]),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card('Publicacion', [
          _dropdown(
            'Visibilidad',
            _published ? 'publicado' : 'borrador',
            const {
              'publicado': 'Publicado - visible en el catalogo',
              'borrador': 'Borrador - solo tu lo ves',
            },
            (v) => setState(() => _published = v == 'publicado'),
          ),
        ]),
        _card('Certificado de finalizacion', [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: CoursesColors.green600,
            value: _certificate,
            title: const Text('Este curso emite certificado'),
            onChanged: (v) => setState(() => _certificate = v ?? false),
          ),
          const Text(
            'El alumno recibe su certificado al completar el avance minimo y aprobar las evaluaciones que marques como requeridas (pestana Evaluaciones).',
            style: TextStyle(color: CoursesColors.gray700, height: 1.4),
          ),
          if (_certificate) ...[
            const SizedBox(height: 14),
            _dropdown(
              'Avance minimo para certificar',
              const ['50', '60', '70', '80', '90', '100']
                      .contains(_minProgress.toString())
                  ? _minProgress.toString()
                  : '100',
              const {
                '50': '50%',
                '60': '60%',
                '70': '70%',
                '80': '80%',
                '90': '90%',
                '100': '100%',
              },
              (v) => setState(() => _minProgress = int.parse(v)),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: CoursesColors.green600,
              value: _requireEvals,
              title: const Text('Exigir las evaluaciones requeridas'),
              onChanged: (v) => setState(() => _requireEvals = v ?? true),
            ),
          ],
        ]),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CoursesColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CoursesColors.gray400),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zona de riesgo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CoursesColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Retira el curso del catalogo. Los alumnos ya inscritos conservan su avance.',
                  style: TextStyle(color: CoursesColors.gray700, height: 1.4),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _published
                      ? () async {
                          setState(() => _published = false);
                          await _save();
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CoursesColors.ink,
                    side: const BorderSide(color: CoursesColors.gray400),
                  ),
                  child: Text(
                    _published ? 'Retirar del catalogo' : 'Ya esta retirado',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 16, wide ? 24 : 12, 40),
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          )
        else ...[
          left,
          right,
        ],
      ],
    );
  }
}

/// Editor de un bloque de contenido dentro de una leccion.
class _BlockEditorCard extends StatefulWidget {
  const _BlockEditorCard({
    super.key,
    required this.block,
    required this.index,
    required this.total,
    required this.courseId,
    required this.onChanged,
    required this.onMove,
    required this.onDelete,
  });

  final ContentBlock block;
  final int index;
  final int total;
  final String courseId;
  final VoidCallback onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onDelete;

  @override
  State<_BlockEditorCard> createState() => _BlockEditorCardState();
}

class _BlockEditorCardState extends State<_BlockEditorCard> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _url;
  late final TextEditingController _caption;
  bool _open = true;
  bool _uploading = false;

  ContentBlock get _b => widget.block;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: _b.title);
    _content = TextEditingController(text: _b.content);
    _url = TextEditingController(text: _b.url);
    _caption = TextEditingController(text: _b.caption);
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _url.dispose();
    _caption.dispose();
    super.dispose();
  }

  List<String>? get _extensions {
    switch (_b.kind) {
      case ContentKind.image:
        return LearningStorage.imageExtensions;
      case ContentKind.video:
        return LearningStorage.videoExtensions;
      case ContentKind.document:
        return LearningStorage.documentExtensions;
      case ContentKind.program:
        return LearningStorage.programExtensions;
      case ContentKind.text:
      case ContentKind.youtube:
        return null;
    }
  }

  int get _maxMb {
    switch (_b.kind) {
      case ContentKind.image:
        return 10;
      case ContentKind.video:
        return 200;
      case ContentKind.document:
        return 50;
      case ContentKind.program:
        return 100;
      case ContentKind.text:
      case ContentKind.youtube:
        return 10;
    }
  }

  Future<void> _upload() async {
    final ext = _extensions;
    if (ext == null) return;
    setState(() => _uploading = true);
    try {
      final up = await LearningStorage.pickAndUpload(
        courseId: widget.courseId,
        extensions: ext,
        maxMb: _maxMb,
      );
      if (up != null && mounted) {
        setState(() {
          _url.text = up.url;
          _b.url = up.url;
          if (_title.text.trim().isEmpty) {
            _title.text = up.name;
            _b.title = up.name;
          }
        });
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  InputDecoration _deco(String? hint) {
    OutlineInputBorder border(Color color, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: w),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: CoursesColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border(CoursesColors.line),
      enabledBorder: border(CoursesColors.line),
      focusedBorder: border(CoursesColors.green600, 1.6),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: CoursesColors.ink,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final kind = _b.kind;
    final isText = kind == ContentKind.text;
    final isImage = kind == ContentKind.image;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CoursesColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoursesColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              child: Row(
                children: [
                  Icon(contentKindIcon(kind),
                      size: 18, color: CoursesColors.green700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _title.text.trim().isEmpty
                          ? contentKindLabel(kind)
                          : '${contentKindLabel(kind)} - ${_title.text.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CoursesColors.green800,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Subir',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    onPressed:
                        widget.index > 0 ? () => widget.onMove(-1) : null,
                  ),
                  IconButton(
                    tooltip: 'Bajar',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    onPressed: widget.index < widget.total - 1
                        ? () => widget.onMove(1)
                        : null,
                  ),
                  IconButton(
                    tooltip: 'Eliminar elemento',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const Divider(height: 1, color: CoursesColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Titulo (opcional)'),
                  TextField(
                    controller: _title,
                    decoration: _deco(null),
                    onChanged: (v) {
                      _b.title = v;
                      widget.onChanged();
                    },
                  ),
                  if (!isText) ...[
                    _label(
                      kind == ContentKind.youtube
                          ? 'Enlace de YouTube'
                          : 'Archivo o enlace',
                    ),
                    TextField(
                      controller: _url,
                      keyboardType: TextInputType.url,
                      decoration: _deco('https://...'),
                      onChanged: (v) {
                        _b.url = v.trim();
                        widget.onChanged();
                      },
                    ),
                    if (_extensions != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _uploading ? null : _upload,
                          icon: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file, size: 18),
                          label: Text(
                            _uploading
                                ? 'Subiendo...'
                                : (isImage
                                    ? 'Subir imagen'
                                    : 'Subir archivo'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CoursesColors.green800,
                            side: const BorderSide(
                              color: CoursesColors.green300,
                            ),
                            minimumSize: const Size(48, 44),
                          ),
                        ),
                      ),
                    ],
                    if (isImage && _b.url.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CoursesColors.green50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _b.url.trim(),
                            height: 220,
                            fit: BoxFit.contain,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.fallback,
                            errorBuilder: (context, error, stack) =>
                                const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No se pudo mostrar la vista previa.',
                                style: TextStyle(color: CoursesColors.muted),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  _label(isText ? 'Texto' : 'Descripcion (opcional)'),
                  TextField(
                    controller: _content,
                    minLines: isText ? 5 : 2,
                    maxLines: isText ? 12 : 4,
                    decoration: _deco(null),
                    onChanged: (v) {
                      _b.content = v;
                      widget.onChanged();
                    },
                  ),
                  if (!isText) ...[
                    _label('Pie de nota (opcional)'),
                    TextField(
                      controller: _caption,
                      decoration: _deco(null),
                      onChanged: (v) {
                        _b.caption = v;
                        widget.onChanged();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

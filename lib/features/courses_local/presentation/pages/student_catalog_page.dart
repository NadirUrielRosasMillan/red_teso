import 'package:flutter/material.dart';
import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../local_courses_pages.dart';
import '../theme/courses_theme.dart';
import '../widgets/course_widgets.dart';
import 'certificate_verify_page.dart';

const List<String> _kLevels = [kLevelBasic, 'Intermedio', 'Avanzado'];

const Map<String, String> _kModalityLabels = {
  'modulos': 'Por modulos',
  'en_linea': 'En linea con clases',
};

const Map<String, String> _kPriceLabels = {
  'gratis': 'Solo gratis',
  'pago': 'Solo de pago',
};

const Map<String, String> _kOrderLabels = {
  'recientes': 'Mas recientes',
  'valorados': 'Mejor valorados',
  'precio_asc': 'Precio: menor a mayor',
  'precio_desc': 'Precio: mayor a menor',
};

/// Catalogo de cursos del estudiante (mobile first).
class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({super.key});

  @override
  State<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends State<StudentCoursesPage> {
  final TextEditingController _query = TextEditingController();
  String _category = '';
  String _career = '';
  String _modality = '';
  String _level = '';
  String _price = '';
  String _order = 'recientes';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  int get _activeFilters => [_career, _modality, _level, _price]
      .where((v) => v.isNotEmpty)
      .length;

  List<LocalCourse> _filtered(List<LocalCourse> all) {
    final q = _query.text.trim().toLowerCase();
    final result = all.where((c) {
      if (!c.published) return false;
      if (q.isNotEmpty) {
        final text =
            '${c.title} ${c.description} ${c.summary} ${c.instructor}'
                .toLowerCase();
        if (!text.contains(q)) return false;
      }
      if (_category.isNotEmpty && c.category != _category) return false;
      if (_career.isNotEmpty && !c.targetsCareer(_career)) return false;
      if (_modality.isNotEmpty && c.modality != _modality) return false;
      if (_level.isNotEmpty && c.level != _level) return false;
      if (_price == 'gratis' && c.price != 0) return false;
      if (_price == 'pago' && c.price <= 0) return false;
      return true;
    }).toList();

    if (_order == 'precio_asc') {
      result.sort((a, b) => a.price.compareTo(b.price));
    } else if (_order == 'precio_desc') {
      result.sort((a, b) => b.price.compareTo(a.price));
    } else if (_order == 'valorados') {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return result;
  }

  void _clearFilters() {
    setState(() {
      _category = '';
      _career = '';
      _modality = '';
      _level = '';
      _price = '';
      _order = 'recientes';
    });
  }

  void _openFilters(List<LocalCourse> all) {
    final published = all.where((c) => c.published).toList();
    final careers = published
        .expand((c) => c.careerList)
        .where((n) => n != 'Todas las carreras')
        .toSet()
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CoursesColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setSheet) {
          void pick(VoidCallback change) {
            setState(change);
            setSheet(() {});
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scroll) => ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CoursesColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: CoursesColors.ink,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearFilters();
                        setSheet(() {});
                      },
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
                _group(
                  'Carrera',
                  {for (final c in careers) c: c},
                  _career,
                  (v) => pick(() => _career = v),
                ),
                _group(
                  'Tipo de curso',
                  _kModalityLabels,
                  _modality,
                  (v) => pick(() => _modality = v),
                ),
                _group(
                  'Nivel',
                  {for (final l in _kLevels) l: l},
                  _level,
                  (v) => pick(() => _level = v),
                ),
                _group(
                  'Precio',
                  _kPriceLabels,
                  _price,
                  (v) => pick(() => _price = v),
                ),
                _group(
                  'Ordenar por',
                  _kOrderLabels,
                  _order,
                  (v) => pick(() => _order = v.isEmpty ? 'recientes' : v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Ver resultados'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  /// Grupo de chips de seleccion unica. Tocar el chip activo lo desmarca.
  Widget _group(
    String title,
    Map<String, String> options,
    String selected,
    ValueChanged<String> onPick,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: CoursesColors.gray700,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in options.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: selected == entry.key,
                showCheckmark: false,
                selectedColor: CoursesColors.green200,
                backgroundColor: CoursesColors.white,
                side: const BorderSide(color: CoursesColors.line),
                labelStyle: TextStyle(
                  color: selected == entry.key
                      ? CoursesColors.green900
                      : CoursesColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) =>
                    onPick(selected == entry.key ? '' : entry.key),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: coursesTheme(),
      child: AnimatedBuilder(
        animation: LocalCourseStore.instance,
        builder: (context, _) {
          final all = LocalCourseStore.instance.courses;
          final courses = _filtered(all);
          final categories = all
              .where((c) => c.published)
              .map((c) => c.category)
              .toSet()
              .toList();
          final wide = MediaQuery.sizeOf(context).width >= 640;
          final pad = wide ? 24.0 : 16.0;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Cursos TESOEM'),
              actions: [
                IconButton(
                  tooltip: 'Verificar certificado',
                  icon: const Icon(Icons.verified_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CertificateVerifyPage(),
                    ),
                  ),
                ),
                if (LocalCourseStore.instance.isTeacher)
                  IconButton(
                    tooltip: 'Panel del profesor',
                    icon: const Icon(Icons.school_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherCoursesPage(),
                      ),
                    ),
                  ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 40),
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
                    _hero(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _categoryChip('Todos', ''),
                                for (final c in categories)
                                  _categoryChip(c, c),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _filterButton(all),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${courses.length} ${courses.length == 1 ? 'curso' : 'cursos'}',
                      style: const TextStyle(
                        color: CoursesColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (courses.isEmpty)
                      const _EmptyCatalog()
                    else
                      _grid(courses),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            CoursesColors.green900,
            CoursesColors.green700,
            CoursesColors.green600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aprende con NEXUS',
            style: TextStyle(
              color: CoursesColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Busca por nombre o elige una categoria.',
            style: TextStyle(color: CoursesColors.green100),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por titulo, descripcion o docente',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _query.clear();
                        setState(() {});
                      },
                    ),
              filled: true,
              fillColor: CoursesColors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String value) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: CoursesColors.green600,
        backgroundColor: CoursesColors.white,
        side: const BorderSide(color: CoursesColors.line),
        labelStyle: TextStyle(
          color: selected ? CoursesColors.white : CoursesColors.gray700,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _category = value),
      ),
    );
  }

  Widget _filterButton(List<LocalCourse> all) {
    final n = _activeFilters;
    return OutlinedButton.icon(
      onPressed: () => _openFilters(all),
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: Text(n == 0 ? 'Filtros' : 'Filtros ($n)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: CoursesColors.green800,
        side: const BorderSide(color: CoursesColors.green300),
        minimumSize: const Size(48, 44),
      ),
    );
  }

  Widget _grid(List<LocalCourse> courses) {
    return LayoutBuilder(builder: (context, box) {
      const gap = 16.0;
      final cols = box.maxWidth >= 1000
          ? 3
          : box.maxWidth >= 640
              ? 2
              : 1;
      final cardWidth = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final c in courses)
            SizedBox(width: cardWidth, child: CourseCatalogCard(course: c)),
        ],
      );
    });
  }
}

/// Tarjeta de curso: portada, insignia de certificado, instructor, datos
/// clave, valoracion, progreso (si esta inscrito) y precio.
class CourseCatalogCard extends StatelessWidget {
  const CourseCatalogCard({super.key, required this.course});

  final LocalCourse course;

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoursePreviewPage(course: course, studentMode: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalCourseStore.instance;
    final enrolled = store.isEnrolled(course);
    final percent = store.percentFor(course);

    return Material(
      color: CoursesColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: CoursesColors.line),
      ),
      child: InkWell(
        onTap: () => _open(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CourseCover(course: course),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: CoursePill(
                      text: course.level,
                      background: CoursesColors.white,
                      foreground: CoursesColors.green900,
                    ),
                  ),
                  if (course.certificate)
                    const Positioned(
                      right: 12,
                      top: 12,
                      child: CertificateBadge(onDark: true),
                    ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: CoursePill(
                      text: course.isLive
                          ? 'En linea con clases'
                          : 'Por modulos',
                      background: CoursesColors.ink,
                      foreground: CoursesColors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoursePill(text: course.category),
                  const SizedBox(height: 10),
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: CoursesColors.ink,
                    ),
                  ),
                  if (course.instructor.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      course.instructor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CoursesColors.green700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    course.summary.isEmpty
                        ? course.description
                        : course.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: CoursesColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _meta(Icons.schedule_outlined, course.duration),
                      _meta(
                        Icons.menu_book_outlined,
                        '${course.lessonCount} lecciones',
                      ),
                      _rating(),
                    ],
                  ),
                  if (enrolled) ...[
                    const SizedBox(height: 14),
                    CourseProgressBar(
                      value: percent / 100,
                      label: '$percent% completado',
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.isFree
                              ? 'Gratis'
                              : '${course.currency} ${course.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: CoursesColors.green700,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => _open(context),
                        child: Text(enrolled ? 'Continuar' : 'Ver curso'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
          style: const TextStyle(color: CoursesColors.muted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _rating() {
    if (course.ratingCount <= 0) {
      return _meta(Icons.star_outline_rounded, 'Sin resenas');
    }
    return _meta(
      Icons.star_rounded,
      '${course.rating.toStringAsFixed(1)} (${course.ratingCount})',
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: CoursesColors.gray400),
          SizedBox(height: 10),
          Text(
            'No encontramos cursos con esos filtros.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoursesColors.muted),
          ),
        ],
      ),
    );
  }
}

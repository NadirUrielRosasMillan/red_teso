import 'package:flutter/material.dart';

import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../theme/courses_theme.dart';
import '../widgets/course_widgets.dart';

/// Verifica la autenticidad de un certificado a partir de su folio.
class CertificateVerifyPage extends StatefulWidget {
  const CertificateVerifyPage({super.key});

  @override
  State<CertificateVerifyPage> createState() => _CertificateVerifyPageState();
}

class _CertificateVerifyPageState extends State<CertificateVerifyPage> {
  final TextEditingController _folio = TextEditingController();
  CertificateData? _found;
  bool _searched = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _folio.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final text = _folio.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _found = null;
      _searched = false;
    });
    try {
      final data = await LocalCourseStore.instance.verifyCertificate(text);
      if (!mounted) return;
      setState(() {
        _found = data;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo consultar el folio. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: coursesTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Verificar certificado')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CoursePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Escribe el folio impreso en el certificado.',
                        style: TextStyle(color: CoursesColors.muted),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _folio,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _verify(),
                        decoration: const InputDecoration(
                          labelText: 'Folio (AGORA-2026-XXXXXXXX)',
                          prefixIcon: Icon(Icons.verified_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _verify,
                          child: Text(_loading ? 'Consultando...' : 'Verificar'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_error != null) CourseErrorBanner(message: _error!),
                if (_searched && _found == null)
                  const CoursePanel(
                    child: Row(
                      children: [
                        Icon(Icons.search_off, color: CoursesColors.gray400),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No existe un certificado con ese folio.',
                            style: TextStyle(color: CoursesColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_found != null) _result(_found!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _result(CertificateData d) {
    return CoursePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoursePill(
            text: 'Certificado valido',
            icon: Icons.verified_rounded,
            background: CoursesColors.green600,
            foreground: CoursesColors.white,
          ),
          const SizedBox(height: 14),
          _row('Folio', d.folio),
          _row('Alumno', d.studentName),
          _row('Curso', d.courseTitle),
          _row('Instructor', d.instructor.isEmpty ? '-' : d.instructor),
          _row('Duracion', d.duration),
          _row('Avance', '${d.percent}%'),
          _row('Emitido el', _date(d.issuedAt)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: CoursesColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: CoursesColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

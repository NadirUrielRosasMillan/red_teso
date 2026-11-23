import 'package:flutter/material.dart';

import '../../data/certificate_pdf.dart';
import '../../data/local_course_store.dart';
import '../../models/local_course.dart';
import '../theme/courses_theme.dart';
import 'course_widgets.dart';

/// Tarjeta de certificacion de un curso. Distingue "el curso ofrece
/// certificado" de "el estudiante ya lo obtuvo": cuando cumple los requisitos
/// puede emitirlo y despues descargarlo en PDF.
class CertificatePanel extends StatefulWidget {
  const CertificatePanel({
    super.key,
    required this.course,
    this.studentMode = true,
  });

  final LocalCourse course;
  final bool studentMode;

  @override
  State<CertificatePanel> createState() => _CertificatePanelState();
}

class _CertificatePanelState extends State<CertificatePanel> {
  bool _busy = false;

  LocalCourse get _course => widget.course;

  void _say(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _issue() async {
    setState(() => _busy = true);
    final folio = await LocalCourseStore.instance.issueCertificate(_course);
    if (!mounted) return;
    setState(() => _busy = false);
    _say(
      folio == null
          ? 'No se pudo emitir el certificado. Intenta de nuevo.'
          : 'Certificado emitido. Folio: $folio',
    );
  }

  Future<void> _download() async {
    final data = LocalCourseStore.instance.certificateDataFor(_course);
    if (data == null) return;
    setState(() => _busy = true);
    try {
      await CertificatePdf.share(data);
    } catch (_) {
      if (mounted) _say('No se pudo generar el PDF.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_course.certificate) {
      return const CoursePanel(
        child: Row(
          children: [
            Icon(Icons.workspace_premium_outlined,
                color: CoursesColors.gray400),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Este curso no emite certificado.',
                style: TextStyle(color: CoursesColors.muted),
              ),
            ),
          ],
        ),
      );
    }

    final store = LocalCourseStore.instance;
    final enrolled = widget.studentMode && store.isEnrolled(_course);
    final state = store.certificateStateFor(_course);
    final percent = store.percentFor(_course);
    final min = _course.certificateMinProgress;
    final evals = _course.requiredEvaluations;
    final needsEvals =
        _course.certificateRequiresEvaluations && evals.isNotEmpty;
    final met = state == CertificateState.eligible ||
        state == CertificateState.issued;
    final data = store.certificateDataFor(_course);

    final children = <Widget>[
      const Row(
        children: [
          Icon(Icons.workspace_premium_rounded,
              color: CoursesColors.green700),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Certificacion',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: CoursesColors.ink,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (enrolled)
        CertificateStatusChip(state: state)
      else
        const CertificateBadge(),
      const SizedBox(height: 12),
      const Text(
        'Para obtener el certificado necesitas:',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: CoursesColors.gray700,
        ),
      ),
      const SizedBox(height: 8),
      _requirement(
        enrolled && percent >= min,
        enrolled
            ? 'Completar el $min% del curso (llevas $percent%)'
            : 'Completar el $min% del curso',
      ),
      if (needsEvals)
        _requirement(
          met,
          evals.length == 1
              ? 'Aprobar la evaluacion requerida'
              : 'Aprobar las ${evals.length} evaluaciones requeridas',
        ),
    ];

    if (enrolled && state == CertificateState.locked) {
      children.addAll([
        const SizedBox(height: 10),
        const Text(
          'Aun no cumples todos los requisitos.',
          style: TextStyle(color: CoursesColors.muted),
        ),
      ]);
    }
    if (enrolled && needsEvals && !met) {
      children.addAll([
        const SizedBox(height: 6),
        const Text(
          'Resuelve las evaluaciones desde la pestana Evaluaciones del aula virtual.',
          style: TextStyle(color: CoursesColors.muted, fontSize: 12),
        ),
      ]);
    }
    if (enrolled && state == CertificateState.eligible) {
      children.addAll([
        const SizedBox(height: 10),
        const Text(
          'Cumples los requisitos para obtener tu certificado.',
          style: TextStyle(
            color: CoursesColors.green800,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _issue,
            icon: const Icon(Icons.workspace_premium_rounded),
            label: Text(_busy ? 'Emitiendo...' : 'Obtener certificado'),
          ),
        ),
      ]);
    }
    if (enrolled && state == CertificateState.issued && data != null) {
      children.addAll([
        const SizedBox(height: 10),
        const Text(
          'Tu certificado ya fue obtenido.',
          style: TextStyle(
            color: CoursesColors.green800,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          'Folio: ${data.folio}',
          style: const TextStyle(color: CoursesColors.gray700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _download,
            icon: const Icon(Icons.download_rounded),
            label: Text(_busy ? 'Generando PDF...' : 'Descargar certificado'),
          ),
        ),
      ]);
    }

    return CoursePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _requirement(bool done, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color: done ? CoursesColors.green600 : CoursesColors.gray400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: CoursesColors.gray700),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/local_course.dart';
import '../theme/courses_theme.dart';

/// Etiqueta redondeada pequena.
class CoursePill extends StatelessWidget {
  const CoursePill({
    super.key,
    required this.text,
    this.background = CoursesColors.green100,
    this.foreground = CoursesColors.green800,
    this.icon,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de progreso con etiqueta opcional. value va de 0.0 a 1.0.
class CourseProgressBar extends StatelessWidget {
  const CourseProgressBar({super.key, required this.value, this.label});

  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: CoursesColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 8,
            backgroundColor: CoursesColors.green100,
            valueColor:
                const AlwaysStoppedAnimation<Color>(CoursesColors.green600),
          ),
        ),
      ],
    );
  }
}

/// Insignia "Con certificado": indica que el curso ofrece certificacion.
/// No significa que el estudiante ya lo haya obtenido.
class CertificateBadge extends StatelessWidget {
  const CertificateBadge({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return CoursePill(
      text: 'Con certificado',
      icon: Icons.workspace_premium_rounded,
      background: onDark ? CoursesColors.white : CoursesColors.green100,
      foreground: CoursesColors.green800,
    );
  }
}

/// Estado del certificado del estudiante (pendiente, disponible, obtenido).
class CertificateStatusChip extends StatelessWidget {
  const CertificateStatusChip({super.key, required this.state});

  final CertificateState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case CertificateState.notOffered:
        return const CoursePill(
          text: 'Sin certificado',
          icon: Icons.block_rounded,
          background: CoursesColors.gray100,
          foreground: CoursesColors.muted,
        );
      case CertificateState.locked:
        return const CoursePill(
          text: 'Certificado pendiente',
          icon: Icons.lock_outline_rounded,
          background: CoursesColors.gray100,
          foreground: CoursesColors.gray700,
        );
      case CertificateState.eligible:
        return const CoursePill(
          text: 'Certificado disponible',
          icon: Icons.verified_outlined,
          background: CoursesColors.green200,
          foreground: CoursesColors.green900,
        );
      case CertificateState.issued:
        return const CoursePill(
          text: 'Certificado obtenido',
          icon: Icons.verified_rounded,
          background: CoursesColors.green600,
          foreground: CoursesColors.white,
        );
    }
  }
}

/// Portada del curso. Con coverUrl muestra la imagen; si esta vacia o falla,
/// genera un degradado verde o gris segun la categoria.
class CourseCover extends StatelessWidget {
  const CourseCover({super.key, required this.course, this.height});

  final LocalCourse course;
  final double? height;

  static const List<List<Color>> _gradients = [
    [CoursesColors.green900, CoursesColors.green600],
    [CoursesColors.green800, CoursesColors.green500],
    [Color(0xFF1F2933), CoursesColors.green700],
    [CoursesColors.gray700, CoursesColors.green600],
  ];

  List<Color> get _colors {
    var sum = 0;
    for (final u in course.category.codeUnits) {
      sum += u;
    }
    return _gradients[sum % _gradients.length];
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school_rounded,
          size: 64,
          color: CoursesColors.green200,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = course.coverUrl.trim().isEmpty
        ? _fallback()
        : Image.network(
            course.coverUrl.trim(),
            fit: BoxFit.cover,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (context, error, stack) => _fallback(),
          );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: content,
    );
  }
}

/// Titulo de seccion consistente.
class CourseSectionTitle extends StatelessWidget {
  const CourseSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: CoursesColors.ink,
        ),
      ),
    );
  }
}

/// Contenedor blanco con borde gris y esquinas redondeadas.
class CoursePanel extends StatelessWidget {
  const CoursePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: CoursesColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoursesColors.line),
      ),
      child: child,
    );
  }
}

/// Icono y nombre de cada tipo de bloque de contenido.
IconData contentKindIcon(ContentKind k) {
  switch (k) {
    case ContentKind.text:
      return Icons.text_fields;
    case ContentKind.image:
      return Icons.image_outlined;
    case ContentKind.video:
      return Icons.video_file_outlined;
    case ContentKind.youtube:
      return Icons.smart_display_outlined;
    case ContentKind.document:
      return Icons.description_outlined;
    case ContentKind.program:
      return Icons.archive_outlined;
  }
}

String contentKindLabel(ContentKind k) {
  switch (k) {
    case ContentKind.text:
      return 'Texto';
    case ContentKind.image:
      return 'Imagen';
    case ContentKind.video:
      return 'Video';
    case ContentKind.youtube:
      return 'YouTube';
    case ContentKind.document:
      return 'Documento';
    case ContentKind.program:
      return 'Programa';
  }
}

/// Aviso de error con boton para cerrarlo (lectura o escritura en Firebase).
class CourseErrorBanner extends StatelessWidget {
  const CourseErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CoursesColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CoursesColors.gray400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: CoursesColors.gray700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: CoursesColors.gray700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boton principal con degradado verde y sombra suave.
class CoursePrimaryButton extends StatelessWidget {
  const CoursePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CoursesColors.green700, CoursesColors.green500],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CoursesColors.green600.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: small ? 12 : 18,
                vertical: small ? 8 : 12,
              ),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: CoursesColors.white),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CoursesColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: small ? 13 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

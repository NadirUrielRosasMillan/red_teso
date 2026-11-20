import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../models/local_course.dart';
import '../theme/courses_theme.dart';
import 'course_widgets.dart';

/// Abre un enlace http o https en el navegador o la app externa.
Future<void> openLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
    messenger.showSnackBar(
      const SnackBar(content: Text('El enlace no es valido.')),
    );
    return;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el enlace.')),
    );
  }
}

/// Id de video de YouTube a partir de un enlace, o null si no lo reconoce.
String? youtubeId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  if (host.contains('youtu.be')) {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if (host.contains('youtube.com')) {
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    final segs = uri.pathSegments;
    if (segs.length >= 2 && (segs[0] == 'embed' || segs[0] == 'shorts')) {
      return segs[1];
    }
  }
  return null;
}

String _fileName(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.pathSegments.isEmpty) return url;
  final last = Uri.decodeComponent(uri.pathSegments.last);
  final cut = last.indexOf('/');
  final name = cut >= 0 ? last.substring(cut + 1) : last;
  return name.replaceFirst(RegExp(r'^\d{10,}_'), '');
}

/// Muestra un bloque de contenido de una leccion segun su tipo.
class ContentBlockView extends StatelessWidget {
  const ContentBlockView({super.key, required this.block});

  final ContentBlock block;

  @override
  Widget build(BuildContext context) {
    final b = block;
    final hasUrl = b.url.trim().isNotEmpty;
    final hasText = b.content.trim().isNotEmpty;

    final Widget media;
    switch (b.kind) {
      case ContentKind.text:
        media = const SizedBox.shrink();
        break;
      case ContentKind.image:
        media = hasUrl
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  b.url.trim(),
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  width: double.infinity,
                  errorBuilder: (context, error, stack) =>
                      _pending('No se pudo cargar la imagen.'),
                ),
              )
            : _pending('Imagen pendiente de agregar.');
        break;
      case ContentKind.video:
        media = hasUrl
            ? NetworkVideoPlayer(url: b.url.trim())
            : _pending('Video pendiente de agregar.');
        break;
      case ContentKind.youtube:
        media = hasUrl
            ? _YoutubeCard(url: b.url.trim())
            : _pending('Enlace de YouTube pendiente de agregar.');
        break;
      case ContentKind.document:
      case ContentKind.program:
        media = hasUrl
            ? _FileCard(
                url: b.url.trim(),
                icon: contentKindIcon(b.kind),
                action: b.kind == ContentKind.program ? 'Descargar' : 'Abrir',
              )
            : _pending('Archivo pendiente de agregar.');
        break;
    }

    return CoursePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(contentKindIcon(b.kind), color: CoursesColors.green700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b.title.isEmpty ? contentKindLabel(b.kind) : b.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CoursesColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (b.kind != ContentKind.text) ...[
            const SizedBox(height: 12),
            media,
          ],
          if (hasText) ...[
            const SizedBox(height: 12),
            SelectableText(
              b.content,
              style: const TextStyle(
                color: CoursesColors.gray700,
                height: 1.6,
              ),
            ),
          ],
          if (b.caption.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              b.caption,
              style: const TextStyle(color: CoursesColors.muted, fontSize: 12),
            ),
          ],
          if (b.kind == ContentKind.text && !hasText)
            const Text(
              'Contenido pendiente de agregar.',
              style: TextStyle(color: CoursesColors.muted),
            ),
        ],
      ),
    );
  }

  Widget _pending(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoursesColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: CoursesColors.muted)),
    );
  }
}

class _YoutubeCard extends StatelessWidget {
  const _YoutubeCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final id = youtubeId(url);
    return InkWell(
      onTap: () => openLink(context, url),
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (id != null)
                Image.network(
                  'https://img.youtube.com/vi/$id/hqdefault.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      Container(color: CoursesColors.ink),
                )
              else
                Container(color: CoursesColors.ink),
              Container(color: CoursesColors.ink.withValues(alpha: 0.35)),
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 64,
                  color: CoursesColors.white,
                ),
              ),
              const Positioned(
                left: 12,
                bottom: 10,
                child: CoursePill(
                  text: 'Ver en YouTube',
                  icon: Icons.open_in_new,
                  background: CoursesColors.white,
                  foreground: CoursesColors.green900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.url,
    required this.icon,
    required this.action,
  });

  final String url;
  final IconData icon;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CoursesColors.green50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CoursesColors.green200),
      ),
      child: Row(
        children: [
          Icon(icon, color: CoursesColors.green700, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _fileName(url),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CoursesColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => openLink(context, url),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

/// Reproductor de video para archivos accesibles por URL (mp4, webm...).
class NetworkVideoPlayer extends StatefulWidget {
  const NetworkVideoPlayer({super.key, required this.url});

  final String url;

  @override
  State<NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<NetworkVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = c;
    try {
      await c.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (_failed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CoursesColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'No se pudo reproducir el video.',
                style: TextStyle(color: CoursesColors.muted),
              ),
            ),
            TextButton(
              onPressed: () => openLink(context, widget.url),
              child: const Text('Abrir enlace'),
            ),
          ],
        ),
      );
    }
    if (c == null || !c.value.isInitialized) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: CoursesColors.ink,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(c),
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: c,
                    builder: (context, value, _) => IconButton(
                      iconSize: 56,
                      color: CoursesColors.white,
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                      ),
                      onPressed: () =>
                          value.isPlaying ? c.pause() : c.play(),
                    ),
                  ),
                ],
              ),
            ),
            VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: CoursesColors.green500,
                bufferedColor: CoursesColors.gray400,
                backgroundColor: CoursesColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

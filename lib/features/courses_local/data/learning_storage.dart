import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Resultado de subir un archivo a Firebase Storage.
class UploadedFile {
  const UploadedFile({required this.url, required this.name});

  final String url;
  final String name;
}

/// Sube archivos de cursos a Firebase Storage (carpeta learning/).
/// Funciona en Android, iOS, escritorio y web: en web lee los bytes del
/// archivo y en las demas plataformas sube el archivo directamente.
class LearningStorage {
  LearningStorage._();

  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> videoExtensions = ['mp4', 'mov', 'webm', 'mkv'];
  static const List<String> documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'txt',
  ];
  static const List<String> programExtensions = ['zip', 'rar', '7z'];

  static bool get isSupported => true;

  static String _mime(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Abre el selector de archivos y sube el elegido. Devuelve null si el
  /// usuario cancela. Lanza un String con el motivo si algo falla.
  /// [maxMb] limita el tamano del archivo.
  static Future<UploadedFile?> pickAndUpload({
    required String courseId,
    required List<String> extensions,
    int maxMb = 50,
  }) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (files.isEmpty) return null;

    final picked = files.first;
    final length = await picked.length();
    if (length != null && length > maxMb * 1024 * 1024) {
      final mb = (length / (1024 * 1024)).toStringAsFixed(1);
      throw 'El archivo pesa $mb MB y el maximo es $maxMb MB.';
    }

    final ext = picked.name.contains('.')
        ? picked.name.split('.').last
        : 'bin';
    final safeName = picked.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref()
        .child('learning/$courseId/${stamp}_$safeName');
    final meta = SettableMetadata(contentType: _mime(ext));

    try {
      final path = kIsWeb ? null : picked.path;
      if (path != null && File(path).existsSync()) {
        await ref.putFile(File(path), meta);
      } else {
        final bytes = await picked.readAsBytes();
        await ref.putData(bytes, meta);
      }
      final url = await ref.getDownloadURL();
      return UploadedFile(url: url, name: picked.name);
    } on FirebaseException catch (e) {
      throw 'No se pudo subir el archivo (${e.code}). Revisa las reglas de Storage.';
    } catch (e) {
      throw 'No se pudo subir el archivo: $e';
    }
  }
}

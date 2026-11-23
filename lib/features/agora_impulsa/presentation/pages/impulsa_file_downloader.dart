import 'dart:typed_data';
import 'impulsa_file_downloader_stub.dart'
if (dart.library.html) 'impulsa_file_downloader_web.dart' as impl;

Future<bool> downloadImpulsaFile({
  required String fileName,
  String textContent = '',
  Uint8List? rawBytes,
}) {
  return impl.downloadImpulsaFileImpl(
    fileName: fileName,
    textContent: textContent,
    rawBytes: rawBytes,
  );
}
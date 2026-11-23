import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/local_course.dart';

/// Genera el certificado en PDF y permite descargarlo o compartirlo.
/// Todo ocurre en el dispositivo: no requiere servidor.
class CertificatePdf {
  CertificatePdf._();

  static const PdfColor _green = PdfColor.fromInt(0xFF1B6B45);
  static const PdfColor _greenDark = PdfColor.fromInt(0xFF0F3D2A);
  static const PdfColor _greenSoft = PdfColor.fromInt(0xFFE3F4EA);
  static const PdfColor _gray = PdfColor.fromInt(0xFF616E7C);

  static Future<pw.Font> _font(
    Future<pw.Font> Function() remote,
    pw.Font fallback,
  ) async {
    try {
      return await remote();
    } catch (_) {
      return fallback;
    }
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static Future<Uint8List> build(CertificateData d) async {
    final regular =
        await _font(PdfGoogleFonts.openSansRegular, pw.Font.helvetica());
    final bold =
        await _font(PdfGoogleFonts.openSansBold, pw.Font.helveticaBold());

    final doc = pw.Document(
      title: 'Certificado ${d.folio}',
      author: 'AGORA Aprende TESOEM',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(22),
            color: PdfColors.white,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _green, width: 5),
              ),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _greenSoft, width: 2),
                ),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 44,
                  vertical: 26,
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'AGORA APRENDE',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 13,
                            letterSpacing: 4,
                            color: _green,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Tecnol\u00F3gico de Estudios Superiores del Oriente del Estado de M\u00E9xico',
                          style: const pw.TextStyle(fontSize: 10, color: _gray),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Certificado de acreditaci\u00F3n',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 34,
                            color: _greenDark,
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        pw.Text(
                          'Se otorga a',
                          style: const pw.TextStyle(fontSize: 13, color: _gray),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          d.studentName,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 30,
                            color: _green,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'por haber concluido satisfactoriamente el curso',
                          style: const pw.TextStyle(fontSize: 13, color: _gray),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          d.courseTitle,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 22,
                            color: _greenDark,
                          ),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        _item('Duraci\u00F3n', d.duration, bold),
                        _item(
                          'Instructor',
                          d.instructor.isEmpty ? '-' : d.instructor,
                          bold,
                        ),
                        _item('Avance', '${d.percent}%', bold),
                        _item('Fecha de emisi\u00F3n', _date(d.issuedAt), bold),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Folio: ${d.folio}',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 12,
                            color: _green,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Verifica la autenticidad de este certificado con su folio en AGORA Aprende.',
                          style: const pw.TextStyle(fontSize: 9, color: _gray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _item(String label, String value, pw.Font bold) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: _gray),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(font: bold, fontSize: 13, color: _greenDark),
        ),
      ],
    );
  }

  /// Genera el PDF y abre el dialogo para guardarlo, imprimirlo o compartirlo.
  static Future<void> share(CertificateData d) async {
    final bytes = await build(d);
    await Printing.sharePdf(bytes: bytes, filename: 'certificado-${d.folio}.pdf');
  }
}

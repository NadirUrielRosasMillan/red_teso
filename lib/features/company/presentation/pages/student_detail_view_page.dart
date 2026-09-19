import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class StudentDetailViewPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentDetailViewPage({super.key, required this.student});

  @override
  State<StudentDetailViewPage> createState() => _StudentDetailViewPageState();
}

class _StudentDetailViewPageState extends State<StudentDetailViewPage> {
  bool _isStarred = false;
  bool _interestSent = false;

  void _toggleStar() {
    setState(() {
      _isStarred = !_isStarred;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isStarred ? '¡Alumno agregado a destacados!' : 'Removido de destacados.'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _sendInterest() {
    setState(() {
      _interestSent = true;
    });
    // Simulación del Correo Automático de Contacto (Requisito del documento)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📧 Correo automático de contacto enviado al alumno con éxito.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Perfil del Candidato'),
        foregroundColor: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isStarred ? Icons.star : Icons.star_border, color: Colors.amber, size: 28),
            onPressed: _toggleStar,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado principal del candidato
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Text(
                      s['nombre'].toString()[0],
                      style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s['nombre'] as String,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ingeniería en Sistemas Computacionales',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    s['correo'] as String,
                    style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tarjeta de Información Académica
            const Text('Información del Historial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAcademicMetric('Promedio', s['gpa'].toString(), Icons.star, Colors.amber),
                  _buildAcademicMetric('Estatus', s['mod'] as String, Icons.school, AppTheme.primaryGreen),
                  _buildAcademicMetric('Inglés', (s['ingles'] as bool) ? 'Fluido' : 'Básico', Icons.g_translate, Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Habilidades Técnicas
            const Text('Habilidades del Alumno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (s['habilidades'] as List<String>).map((h) {
                return Chip(
                  label: Text(h),
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.05),
                  labelStyle: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                  side: const BorderSide(color: AppTheme.primaryGreen, width: 0.5),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Documentación
            const Text('Documentos Verificados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDocumentRow('Kárdex Oficial TESOEM', true),
            _buildDocumentRow('Carta de Presentación', true),
            _buildDocumentRow('Currículum Vitae', true),

            const SizedBox(height: 48),

            // Botón para manifestar interés y enviar Correo Automático (Requisito Correo Automático)
            _interestSent
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '¡Contacto Iniciado por Correo!',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _sendInterest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on, color: Colors.white),
                        SizedBox(width: 8),
                        Text('MANIFESTAR INTERÉS (RECLUTAR)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildDocumentRow(String label, bool verified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 16),
          const SizedBox(width: 4),
          const Text('Verificado', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
        ],
      ),
    );
  }
}

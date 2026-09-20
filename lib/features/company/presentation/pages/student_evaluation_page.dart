import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class StudentEvaluationPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentEvaluationPage({super.key, required this.student});

  @override
  State<StudentEvaluationPage> createState() => _StudentEvaluationPageState();
}

class _StudentEvaluationPageState extends State<StudentEvaluationPage> {
  // Estados para las calificaciones (1 a 5)
  int _punctualityRating = 0;
  int _knowledgeRating = 0;
  int _attitudeRating = 0;
  final _commentsController = TextEditingController();

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  void _submitEvaluation() {
    if (_punctualityRating == 0 || _knowledgeRating == 0 || _attitudeRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, califica todos los rubros antes de enviar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Simulación de envío
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Evaluación enviada con éxito para ${widget.student['nombre']}.'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Evaluación de Desempeño'),
        foregroundColor: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del Alumno a evaluar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      widget.student['nombre'][0],
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student['nombre'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.student['mod']} finalizado',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Criterios de Evaluación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Califica el desempeño del alumno durante su estancia en la empresa.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Rubros de calificación
            _buildRatingRow('Puntualidad y Asistencia', _punctualityRating, (val) {
              setState(() => _punctualityRating = val);
            }),
            const SizedBox(height: 20),
            _buildRatingRow('Conocimientos Técnicos', _knowledgeRating, (val) {
              setState(() => _knowledgeRating = val);
            }),
            const SizedBox(height: 20),
            _buildRatingRow('Actitud y Proactividad', _attitudeRating, (val) {
              setState(() => _attitudeRating = val);
            }),

            const SizedBox(height: 32),

            const Text(
              'Comentarios Adicionales',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe brevemente las fortalezas y áreas de oportunidad del alumno...',
                fillColor: Colors.grey[50],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _submitEvaluation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'ENVIAR EVALUACIÓN INSTITUCIONAL',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Esta evaluación será visible en el perfil del alumno.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, int currentRating, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < currentRating ? Icons.star : Icons.star_border,
                color: index < currentRating ? Colors.amber : Colors.grey[400],
                size: 32,
              ),
              onPressed: () => onRatingChanged(index + 1),
            );
          }),
        ),
      ],
    );
  }
}

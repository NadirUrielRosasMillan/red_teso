import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class StudentEvaluationPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentEvaluationPage({super.key, required this.student});

  @override
  State<StudentEvaluationPage> createState() => _StudentEvaluationPageState();
}

class _StudentEvaluationPageState extends State<StudentEvaluationPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _punctualityRating = 0;
  int _knowledgeRating = 0;
  int _attitudeRating = 0;
  final _commentsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitEvaluation() async {
    if (_punctualityRating == 0 || _knowledgeRating == 0 || _attitudeRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, califica todos los rubros'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final double finalRating = (_punctualityRating + _knowledgeRating + _attitudeRating) / 3;
      
      await _db.collection('evaluations').add({
        'studentId': widget.student['uid'] ?? widget.student['id'],
        'studentName': widget.student['nombre'] ?? widget.student['name'],
        'rating': finalRating,
        'punctuality': _punctualityRating,
        'knowledge': _knowledgeRating,
        'attitude': _attitudeRating,
        'comment': _commentsController.text.trim(),
        'companyName': 'Empresa Registrada', // Idealmente obtener del perfil de la empresa actual
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Evaluación guardada exitosamente!'), backgroundColor: AppTheme.primaryGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Evaluar Desempeño')),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calificando a: ${widget.student['nombre'] ?? widget.student['name']}', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _buildRatingRow('Puntualidad', _punctualityRating, (v) => setState(() => _punctualityRating = v)),
                _buildRatingRow('Conocimientos', _knowledgeRating, (v) => setState(() => _knowledgeRating = v)),
                _buildRatingRow('Actitud', _attitudeRating, (v) => setState(() => _attitudeRating = v)),
                const SizedBox(height: 32),
                TextField(
                  controller: _commentsController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Comentarios adicionales', alignLabelWithHint: true),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _submitEvaluation,
                  child: const Text('ENVIAR EVALUACIÓN'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildRatingRow(String label, int rating, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: List.generate(5, (index) => IconButton(
              icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber),
              onPressed: () => onChanged(index + 1),
            )),
          )
        ],
      ),
    );
  }
}

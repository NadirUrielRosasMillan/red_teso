import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class RateStudentModal extends StatefulWidget {
  final Map<String, dynamic> student;

  const RateStudentModal({super.key, required this.student});

  static Future<void> show(BuildContext context, {required Map<String, dynamic> student}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RateStudentModal(student: student),
    );
  }

  @override
  State<RateStudentModal> createState() => _RateStudentModalState();
}

class _RateStudentModalState extends State<RateStudentModal> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();

  double _rating = 5.0;
  String _modality = 'Residencias Profesional';
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitEvaluation() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para evaluar al candidato')),
      );
      return;
    }

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una recomendación o reseña para el alumno'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final studentId = widget.student['uid'] ?? widget.student['id'] ?? widget.student['studentId'];
      final studentName = widget.student['name'] ?? 'Alumno TESOEM';

      String companyName = 'Empresa Colaboradora';
      final companyDoc = await _db.collection('users').doc(user.uid).get();
      if (companyDoc.exists) {
        final data = companyDoc.data();
        companyName = data?['name'] ?? data?['companyName'] ?? user.displayName ?? 'Empresa Colaboradora';
      }

      await _db.collection('evaluations').add({
        'studentId': studentId,
        'studentName': studentName,
        'companyId': user.uid,
        'companyName': companyName,
        'rating': _rating,
        'modality': _modality,
        'comment': commentText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Evaluación enviada exitosamente para $studentName!',
                  style: GoogleFonts.inter(),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando evaluación: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final studentName = widget.student['name'] ?? 'Candidato';

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_rounded, color: Colors.amber, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evaluar y Recomendar Alumno ⭐',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          'Reseña oficial de desempeño para $studentName',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Divider(height: 28),

              // Selección de Estrellas (1 a 5)
              Text(
                'Calificación de Desempeño:',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 38,
                    ),
                    onPressed: () {
                      setState(() => _rating = starIndex.toDouble());
                    },
                  );
                }),
              ),
              Center(
                child: Text(
                  '${_rating.toStringAsFixed(1)} / 5.0 Estrellas',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                ),
              ),

              const SizedBox(height: 20),

              // Selección de Modalidad
              Text(
                'Tipo de Experiencia:',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _modality,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: ['Residencias Profesional', 'Servicio Social', 'Proyecto Colaborativo', 'Prácticas Profesionales']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.inter(fontSize: 13.5))))
                    .toList(),
                onChanged: (val) => setState(() => _modality = val!),
              ),

              const SizedBox(height: 20),

              // Campo de Reseña / Comentario de Recomendación
              Text(
                'Comentario / Recomendación:',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _commentController,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Describe las fortalezas, actitud, puntualidad y conocimientos técnicos del alumno durante su estadía...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 28),

              // Botón Guardar Evaluación
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _isSaving
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : ElevatedButton.icon(
                        onPressed: _submitEvaluation,
                        icon: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                        label: Text(
                          'PUBLICAR EVALUACIÓN OFICIAL ⭐',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDetailViewPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentDetailViewPage({super.key, required this.student});

  @override
  State<StudentDetailViewPage> createState() => _StudentDetailViewPageState();
}

class _StudentDetailViewPageState extends State<StudentDetailViewPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _interestSent = false;

  // FUNCIÓN PARA ENVIAR CORREO AUTOMÁTICO (Requisito del Proyecto)
  Future<void> _sendAutomaticEmail() async {
    final s = widget.student;
    final String email = s['email'] ?? '';
    final String studentName = s['name'] ?? 'Alumno';

    // Cuerpo del mensaje pre-escrito profesional
    final String subject = 'Interés en tu perfil profesional - RedTESO';
    final String body = 'Hola $studentName,\n\n'
        'Hemos visto tu perfil en la plataforma RedTESO y estamos muy interesados en tu trayectoria académica '
        'en la carrera de Ingeniería en Sistemas Computacionales (Promedio: ${s['gpa']}).\n\n'
        'Nos gustaría agendar una entrevista contigo para platicar sobre nuestras vacantes disponibles.\n\n'
        'Saludos cordiales.';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);

        // Registrar la notificación en la nube
        await _db.collection('notifications').add({
          'toUserId': s['uid'],
          'title': '¡Empresa interesada!',
          'message': 'Una empresa ha revisado tu perfil y te ha enviado un correo de contacto.',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });

        setState(() => _interestSent = true);
      } else {
        throw 'No se pudo abrir la app de correo';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el correo: $e'), backgroundColor: Colors.red),
      );
    }
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Text(s['name']?[0] ?? 'A', style: const TextStyle(fontSize: 32, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(s['name'] ?? 'Sin nombre', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Ingeniería en Sistemas Computacionales', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // Info académica
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfo('Promedio', s['gpa']?.toString() ?? 'N/A'),
                _buildInfo('Modalidad', s['modality'] ?? 'N/A'),
                _buildInfo('Inglés', s['speaksEnglish'] == true ? 'Sí' : 'No'),
              ],
            ),

            const SizedBox(height: 48),

            _interestSent
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                  child: const Text('📧 Contacto iniciado por correo', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                )
              : ElevatedButton.icon(
                  onPressed: _sendAutomaticEmail,
                  icon: const Icon(Icons.mail_outline, color: Colors.white),
                  label: const Text('MANIFESTAR INTERÉS (ENVIAR CORREO)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    minimumSize: const Size(double.infinity, 54),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

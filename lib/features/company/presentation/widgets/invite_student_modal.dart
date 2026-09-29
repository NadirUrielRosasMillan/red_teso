import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/pages/create_vacancy_page.dart';

class InviteStudentModal extends StatefulWidget {
  final Map<String, dynamic> student;

  const InviteStudentModal({super.key, required this.student});

  static Future<void> show(BuildContext context, {required Map<String, dynamic> student}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteStudentModal(student: student),
    );
  }

  @override
  State<InviteStudentModal> createState() => _InviteStudentModalState();
}

class _InviteStudentModalState extends State<InviteStudentModal> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _noteController = TextEditingController();

  Stream<QuerySnapshot>? _vacanciesStream;
  String? _selectedVacancyId;
  Map<String, dynamic>? _selectedVacancyData;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _vacanciesStream = _db
          .collection('vacancies')
          .where('companyId', isEqualTo: user.uid)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para enviar invitaciones')),
      );
      return;
    }

    if (_selectedVacancyId == null || _selectedVacancyData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una vacante para invitar al alumno'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final studentId = widget.student['uid'] ?? widget.student['id'] ?? widget.student['studentId'];
      final studentName = widget.student['name'] ?? 'Alumno TESOEM';

      // Obtener el nombre registrado de la empresa desde Firestore
      String companyName = 'Empresa Colaboradora';
      final companyDoc = await _db.collection('users').doc(user.uid).get();
      if (companyDoc.exists) {
        final data = companyDoc.data();
        companyName = data?['name'] ?? data?['companyName'] ?? user.displayName ?? 'Empresa Colaboradora';
      }

      final vacancyTitle = _selectedVacancyData!['puesto'] ?? 'Vacante';
      final noteText = _noteController.text.trim();

      final customMessage = noteText.isNotEmpty
          ? '$companyName te invita a postularte a "$vacancyTitle". Nota: "$noteText"'
          : '$companyName te invita a postularte a su vacante de "$vacancyTitle". ¡Revisa los detalles y postúlate!';

      // Guardar notificación en Firestore para el alumno
      await _db.collection('notifications').add({
        'toUserId': studentId,
        'title': '¡Invitación de $companyName! 💼✨',
        'message': customMessage,
        'vacancyId': _selectedVacancyId,
        'vacancyTitle': vacancyTitle,
        'companyId': user.uid,
        'companyName': companyName,
        'type': 'invitation',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Invitación a "$vacancyTitle" enviada exitosamente a $studentName!',
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
        SnackBar(content: Text('Error enviando invitación: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final studentName = widget.student['name'] ?? 'Candidato';

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),

            // Encabezado
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invitar a Vacante Directa 📩',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          'Envía una notificación formal a $studentName',
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
            ),

            const Divider(height: 1),

            // Contenido: Lista de vacantes publicadas + Campo de Mensaje Personalizado
            Expanded(
              child: _vacanciesStream == null
                  ? const Center(child: Text('Inicia sesión'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _vacanciesStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(child: Text('Error al cargar vacantes'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.post_add_rounded, size: 56, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aún no has publicado vacantes',
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Para invitar a $studentName, primero debes publicar al menos una vacante u oportunidad.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const CreateVacancyPage()),
                                      );
                                    },
                                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                                    label: Text('PUBLICAR VACANTE AHORA', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selecciona la vacante a la que deseas invitarlo:',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 12),

                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final v = docs[index].data() as Map<String, dynamic>;
                                  final id = docs[index].id;
                                  final puesto = v['puesto'] ?? 'Vacante';
                                  final tipo = v['tipo'] ?? 'Residencias';
                                  final apoyo = v['apoyo'] ?? 0;
                                  final isSelected = _selectedVacancyId == id;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedVacancyId = id;
                                        _selectedVacancyData = v;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.08) : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                                          width: isSelected ? 2.0 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<String>(
                                            value: id,
                                            groupValue: _selectedVacancyId,
                                            activeColor: AppTheme.primaryColor,
                                            onChanged: (val) {
                                              setState(() {
                                                _selectedVacancyId = id;
                                                _selectedVacancyData = v;
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  puesto,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '$tipo • \$$apoyo MXN/mes',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: AppTheme.primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              Text(
                                'Mensaje personalizado (opcional):',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                controller: _noteController,
                                maxLines: 3,
                                style: GoogleFonts.inter(fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: 'Ej. Hola $studentName, nos gustó mucho tu perfil y quisiéramos invitarte a postularte...',
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Botón de Enviar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: _isSending
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : ElevatedButton.icon(
                        onPressed: _sendInvitation,
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        label: Text(
                          'ENVIAR INVITACIÓN DIRECTA 🚀',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal interactivo para contactar alumnos y agendar entrevistas directamente
class ContactStudentModal extends StatefulWidget {
  final Map<String, dynamic> student;

  const ContactStudentModal({
    super.key,
    required this.student,
  });

  static Future<void> show(BuildContext context, {required Map<String, dynamic> student}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactStudentModal(student: student),
    );
  }

  @override
  State<ContactStudentModal> createState() => _ContactStudentModalState();
}

class _ContactStudentModalState extends State<ContactStudentModal> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late TextEditingController _companyNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _messageController;

  String _contactReason = 'Invitación a Entrevista Laboral';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _messageController = TextEditingController();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          _companyNameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _phoneController.text = data['phone'] ?? '';
        } else if (mounted) {
          _emailController.text = user.email ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error cargando empresa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  Future<void> _sendContactRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final user = _auth.currentUser;
        final student = widget.student;
        final studentUid = student['uid'] ?? student['id'] ?? '';
        final studentName = student['name'] ?? 'Alumno';
        final studentEmail = student['email'] ?? '';

        final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
        final formattedTime = _selectedTime.format(context);

        final interviewData = {
          'studentId': studentUid,
          'studentName': studentName,
          'studentEmail': studentEmail,
          'companyId': user?.uid ?? 'anonimo',
          'companyName': _companyNameController.text.trim(),
          'contactEmail': _emailController.text.trim(),
          'contactPhone': _phoneController.text.trim(),
          'reason': _contactReason,
          'proposedDate': formattedDate,
          'proposedTime': formattedTime,
          'message': _messageController.text.trim(),
          'status': 'Pendiente',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // 1. Guardar solicitud en la colección 'interviews' de Firestore
        await _db.collection('interviews').add(interviewData);

        // 2. Enviar notificación automática en tiempo real al alumno
        if (studentUid.isNotEmpty) {
          await _db.collection('notifications').add({
            'toUserId': studentUid,
            'title': '📩 ¡Nueva invitación de entrevista!',
            'message': '${_companyNameController.text.trim()} te ha enviado una invitación de contacto para la fecha $formattedDate a las $formattedTime.',
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
        }

        // 3. Opción de abrir cliente de correo nativo si tiene email registrado
        if (studentEmail.isNotEmpty) {
          final String subject = 'RedTESO - Invitación de ${_companyNameController.text.trim()}';
          final String body = 'Hola $studentName,\n\n'
              'Nos ponemos en contacto contigo a través de la plataforma RedTESO.\n\n'
              'Motivo: $_contactReason\n'
              'Propuesta de fecha: $formattedDate a las $formattedTime\n\n'
              'Mensaje:\n${_messageController.text.trim()}\n\n'
              'Saludos,\n${_companyNameController.text.trim()}';

          final Uri emailUri = Uri(
            scheme: 'mailto',
            path: studentEmail,
            query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
          );

          if (await canLaunchUrl(emailUri)) {
            await launchUrl(emailUri);
          }
        }

        if (!mounted) return;

        Navigator.pop(context); // Cierra el formulario modal

        // Diálogo de confirmación
        _showSuccessDialog(studentName, formattedDate, formattedTime);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar invitación: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(String studentName, String date, String time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.primaryColor, size: 48),
            ),
            const SizedBox(height: 12),
            Text(
              '¡Invitación Enviada!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          'Se ha enviado la propuesta de entrevista a $studentName para el $date a las $time. El alumno recibirá la notificación en tiempo real.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF475569)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('ENTENDIDO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final studentName = widget.student['name'] ?? 'Alumno';

    if (_isLoading) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador superior
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),

                // Encabezado
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                      child: Text(
                        studentName[0],
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contactar a $studentName', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text('Agendar entrevista laboral o proyecto', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Motivo del contacto
                DropdownButtonFormField<String>(
                  initialValue: _contactReason,
                  decoration: InputDecoration(
                    labelText: 'Motivo del Contacto',
                    prefixIcon: const Icon(Icons.category_rounded, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: [
                    'Invitación a Entrevista Laboral',
                    'Oferta de Residencias / Servicio Social',
                    'Consulta sobre Proyecto / Curso TESOEM',
                    'Propuesta de Empleo Fijo',
                  ].map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.inter(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => _contactReason = val!),
                ),

                const SizedBox(height: 16),

                // Nombre Empresa y Teléfono
                TextFormField(
                  controller: _companyNameController,
                  style: GoogleFonts.inter(fontSize: 14.5),
                  decoration: InputDecoration(
                    labelText: 'Nombre de la Empresa',
                    prefixIcon: const Icon(Icons.business_rounded, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre de la empresa' : null,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: 'Correo Respuesta',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa correo' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.inter(fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: 'Teléfono Contacto',
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa teléfono' : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Selección de Fecha y Hora de Entrevista
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha Propuesta', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                              const SizedBox(height: 2),
                              Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hora Propuesta', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                              const SizedBox(height: 2),
                              Text(_selectedTime.format(context), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Mensaje
                TextFormField(
                  controller: _messageController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: 'Detalles del Puesto o Proyecto',
                    hintText: 'Describe brevemente la propuesta para el alumno...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa los detalles' : null,
                ),

                const SizedBox(height: 24),

                // Botón Enviar Invitación
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                      : ElevatedButton.icon(
                          onPressed: _sendContactRequest,
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          label: Text(
                            'ENVIAR INVITACIÓN DE ENTREVISTA ✉️',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, letterSpacing: 0.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

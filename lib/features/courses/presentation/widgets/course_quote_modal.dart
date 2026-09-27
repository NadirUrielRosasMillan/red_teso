import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';

/// Modal interactivo para que las empresas soliciten cotizaciones
/// de capacitación corporativa para sus empleados.
class CourseQuoteModal extends StatefulWidget {
  final CourseModel course;

  const CourseQuoteModal({
    super.key,
    required this.course,
  });

  static Future<void> show(BuildContext context, {required CourseModel course}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourseQuoteModal(course: course),
    );
  }

  @override
  State<CourseQuoteModal> createState() => _CourseQuoteModalState();
}

class _CourseQuoteModalState extends State<CourseQuoteModal> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late TextEditingController _companyNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  int _employeeCount = 10;
  String _modality = 'Híbrido (TESOEM & Empresa)';
  DateTime _startDate = DateTime.now().add(const Duration(days: 14));
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _notesController = TextEditingController();
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
      debugPrint('Error al cargar datos de empresa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submitQuoteRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final user = _auth.currentUser;
        final requestData = {
          'courseId': widget.course.id,
          'courseTitle': widget.course.title,
          'companyId': user?.uid ?? 'anonimo',
          'companyName': _companyNameController.text.trim(),
          'contactEmail': _emailController.text.trim(),
          'contactPhone': _phoneController.text.trim(),
          'employeeCount': _employeeCount,
          'modality': _modality,
          'estimatedStartDate': DateFormat('dd/MM/yyyy').format(_startDate),
          'notes': _notesController.text.trim(),
          'status': 'Pendiente',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Guardar solicitud en la colección de Firestore 'course_requests'
        await _db.collection('course_requests').add(requestData);

        if (!mounted) return;

        Navigator.pop(context); // Cierra el modal de formulario

        // Muestra diálogo de éxito confirmando la cotización
        _showSuccessDialog();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar solicitud: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
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
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 48),
            ),
            const SizedBox(height: 12),
            Text(
              '¡Solicitud Enviada!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          'Hemos recibido tu solicitud de cotización para "${widget.course.title}". Un representante académico de TESOEM se pondrá en contacto contigo muy pronto.',
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
                // Barra indicadora superior
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Encabezado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.request_quote_rounded, color: AppTheme.primaryColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cotización Corporativa',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          Text(
                            widget.course.title,
                            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Campo Nombre Empresa
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

                // Correo y Teléfono en Fila
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Correo de Contacto',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el correo' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Teléfono / WhatsApp',
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa un teléfono' : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Contador de Empleados
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Empleados a Capacitar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Estimado de colaboradores', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton.filled(
                            onPressed: _employeeCount > 1 ? () => setState(() => _employeeCount--) : null,
                            icon: const Icon(Icons.remove_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            child: Text(
                              '$_employeeCount',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton.filled(
                            onPressed: () => setState(() => _employeeCount++),
                            icon: const Icon(Icons.add_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Modalidad Deseada
                DropdownButtonFormField<String>(
                  initialValue: _modality,
                  decoration: InputDecoration(
                    labelText: 'Modalidad de Capacitación',
                    prefixIcon: const Icon(Icons.cast_for_education_rounded, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: [
                    'Híbrido (TESOEM & Empresa)',
                    'Presencial en Instalaciones TESOEM',
                    'Presencial en Instalaciones de la Empresa',
                    '100% En Línea Sincrónico',
                  ].map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.inter(fontSize: 13.5)))).toList(),
                  onChanged: (val) => setState(() => _modality = val!),
                ),

                const SizedBox(height: 16),

                // Fecha Tentativa de Inicio
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fecha Tentativa de Inicio', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_startDate),
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notas / Comentarios
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Comentarios Adicionales / Requisitos Específicos',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(height: 28),

                // Botón Enviar Cotización
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                      : ElevatedButton.icon(
                          onPressed: _submitQuoteRequest,
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          label: Text(
                            'SOLICITAR COTIZACIÓN CORPORATIVA',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class CreateVacancyPage extends StatefulWidget {
  final Map<String, dynamic>? vacancyToEdit;

  const CreateVacancyPage({super.key, this.vacancyToEdit});

  @override
  State<CreateVacancyPage> createState() => _CreateVacancyPageState();
}

class _CreateVacancyPageState extends State<CreateVacancyPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _supportController;

  String _opportunityType = 'Residencias';
  double _requiredGpa = 8.0;
  bool _requiresEnglish = false;
  bool _isPublishing = false;

  final List<String> _requirementsList = ['Proactivo', 'Trabajo en equipo'];
  final TextEditingController _newRequirementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final isEditing = widget.vacancyToEdit != null;

    _titleController = TextEditingController(text: isEditing ? widget.vacancyToEdit!['puesto'] : '');
    _descriptionController = TextEditingController(text: isEditing ? widget.vacancyToEdit!['descripcion'] : '');
    _locationController = TextEditingController(text: isEditing ? widget.vacancyToEdit!['ubicacion'] ?? 'Remoto' : 'Híbrido');
    _supportController = TextEditingController(text: isEditing ? widget.vacancyToEdit!['apoyo']?.toString() : '5000');

    if (isEditing) {
      _opportunityType = widget.vacancyToEdit!['tipo'] ?? 'Residencias';
      _requiredGpa = (widget.vacancyToEdit!['gpa'] ?? 8.0).toDouble();
      _requiresEnglish = widget.vacancyToEdit!['ingles'] ?? false;
      if (widget.vacancyToEdit!['requisitos'] != null) {
        _requirementsList.clear();
        _requirementsList.addAll(List<String>.from(widget.vacancyToEdit!['requisitos']));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _supportController.dispose();
    _newRequirementController.dispose();
    super.dispose();
  }

  void _submitVacancy() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isPublishing = true);
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) throw Exception('Sesión no iniciada');

        // Obtener el nombre real registrado de la empresa desde Firestore
        String companyName = 'Empresa Colaboradora';
        final companyDoc = await _db.collection('users').doc(userId).get();
        if (companyDoc.exists) {
          companyName = companyDoc.data()?['name'] ?? 'Empresa Colaboradora';
        }

        final vacancyData = {
          'puesto': _titleController.text.trim(),
          'tipo': _opportunityType,
          'ubicacion': _locationController.text.trim(),
          'apoyo': int.tryParse(_supportController.text.trim()) ?? 0,
          'descripcion': _descriptionController.text.trim(),
          'gpa': _requiredGpa,
          'ingles': _requiresEnglish,
          'requisitos': _requirementsList,
          'companyId': userId,
          'empresa': companyName,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (widget.vacancyToEdit != null) {
          await _db.collection('vacancies').doc(widget.vacancyToEdit!['id']).update(vacancyData);
        } else {
          await _db.collection('vacancies').add(vacancyData);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  widget.vacancyToEdit != null ? '¡Vacante actualizada!' : '¡Vacante publicada en RedTESO!',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.vacancyToEdit != null) {
          Navigator.pop(context);
        } else {
          _titleController.clear();
          _descriptionController.clear();
          _supportController.clear();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isPublishing = false);
      }
    }
  }

  void _addRequirement() {
    final text = _newRequirementController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _requirementsList.add(text);
        _newRequirementController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vacancyToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Vacante' : 'Publicar Oportunidad', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _isPublishing
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detalles de la Vacante', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.inter(fontSize: 14.5),
                        decoration: InputDecoration(
                          labelText: 'Título de la Vacante / Puesto',
                          prefixIcon: const Icon(Icons.work_outline_rounded, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el puesto' : null,
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _opportunityType,
                        decoration: InputDecoration(
                          labelText: 'Modalidad de la Oportunidad',
                          prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: ['Residencias', 'Servicio Social', 'Recién Egresado', 'Empleo Fijo']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter())))
                            .toList(),
                        onChanged: (val) => setState(() => _opportunityType = val!),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              style: GoogleFonts.inter(fontSize: 14.5),
                              decoration: InputDecoration(
                                labelText: 'Ubicación / Modalidad',
                                prefixIcon: const Icon(Icons.place_outlined, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa la ubicación' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _supportController,
                              style: GoogleFonts.inter(fontSize: 14.5),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: r'Apoyo Mensual ($)',
                                prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Descripción del Puesto y Actividades',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa una descripción' : null,
                      ),

                      const SizedBox(height: 24),

                      Text('Requisitos Mínimos para Alumnos', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Promedio Mínimo Requerido: ${_requiredGpa.toStringAsFixed(1)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ],
                      ),
                      Slider(
                        value: _requiredGpa,
                        min: 7.0,
                        max: 10.0,
                        divisions: 30,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => setState(() => _requiredGpa = val),
                      ),

                      SwitchListTile(
                        title: Text('Inglés Obligatorio', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('Requisito indispensable para postularse', style: GoogleFonts.inter(fontSize: 12)),
                        value: _requiresEnglish,
                        onChanged: (val) => setState(() => _requiresEnglish = val),
                        activeThumbColor: AppTheme.primaryColor,
                      ),

                      const SizedBox(height: 16),

                      // Requisitos específicos (chips)
                      Text('Habilidades requeridas:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        children: _requirementsList.map((req) {
                          return Chip(
                            label: Text(req, style: GoogleFonts.inter(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _requirementsList.remove(req);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newRequirementController,
                              style: GoogleFonts.inter(fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: 'Añadir habilidad (ej. Python, Git...)',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addRequirement,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitVacancy,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            isEditing ? 'GUARDAR CAMBIOS' : 'PUBLICAR VACANTE EN REDTESO',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

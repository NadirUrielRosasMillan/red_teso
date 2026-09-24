import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';

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
  final _newRequirementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final isEditing = widget.vacancyToEdit != null;
    
    _titleController = TextEditingController(text: isEditing ? widget.vacancyToEdit!['puesto'] : '');
    _descriptionController = TextEditingController(text: isEditing ? widget.vacancyToEdit!['descripcion'] : '');
    _locationController = TextEditingController(text: isEditing ? widget.vacancyToEdit!['ubicacion'] ?? 'Remoto' : '');
    _supportController = TextEditingController(text: isEditing ? widget.vacancyToEdit!['apoyo'].toString() : '');

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

  void _submitVacancy() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isPublishing = true);
      try {
        final userId = _auth.currentUser?.uid;
        final vacancyData = {
          'puesto': _titleController.text.trim(),
          'tipo': _opportunityType,
          'ubicacion': _locationController.text.trim(),
          'apoyo': int.tryParse(_supportController.text) ?? 0,
          'descripcion': _descriptionController.text.trim(),
          'gpa': _requiredGpa,
          'ingles': _requiresEnglish,
          'requisitos': _requirementsList,
          'companyId': userId,
          'empresa': 'Empresa Registrada', 
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (widget.vacancyToEdit != null) {
          await _db.collection('vacancies').doc(widget.vacancyToEdit!['id']).update(vacancyData);
        } else {
          await _db.collection('vacancies').add(vacancyData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Vacante publicada en la nube!'), backgroundColor: AppTheme.primaryGreen),
          );
          _titleController.clear();
          _descriptionController.clear();
          _supportController.clear();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isPublishing
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Publicar Oportunidad', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Puesto', prefixIcon: Icon(Icons.badge)),
                    validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _supportController,
                    decoration: const InputDecoration(
                      labelText: r'Apoyo Económico ($)', // FIXED: Raw string escaping $
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 24),
                  const Text('Promedio Mínimo'),
                  Slider(
                    value: _requiredGpa,
                    min: 7.0, max: 10.0, divisions: 30,
                    onChanged: (val) => setState(() => _requiredGpa = val),
                  ),
                  SwitchListTile(
                    title: const Text('Inglés Obligatorio'),
                    value: _requiresEnglish,
                    onChanged: (val) => setState(() => _requiresEnglish = val),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitVacancy,
                    child: Text(widget.vacancyToEdit != null ? 'ACTUALIZAR' : 'PUBLICAR EN REDTESO'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

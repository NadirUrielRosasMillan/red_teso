import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class CreateVacancyPage extends StatefulWidget {
  final Map<String, dynamic>? vacancyToEdit;

  const CreateVacancyPage({super.key, this.vacancyToEdit});

  @override
  State<CreateVacancyPage> createState() => _CreateVacancyPageState();
}

class _CreateVacancyPageState extends State<CreateVacancyPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _supportController;
  
  String _opportunityType = 'Residencias';
  double _requiredGpa = 8.0;
  bool _requiresEnglish = false;
  
  final List<String> _requirementsList = ['Proactivo', 'Trabajo en equipo'];
  final _newRequirementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final isEditing = widget.vacancyToEdit != null;
    
    _titleController = TextEditingController(
      text: isEditing ? widget.vacancyToEdit!['puesto'] : '',
    );
    _descriptionController = TextEditingController(
      text: isEditing ? widget.vacancyToEdit!['descripcion'] : '',
    );
    _locationController = TextEditingController(
      text: isEditing ? widget.vacancyToEdit!['ubicacion'] ?? 'Remoto / Edo de México' : '',
    );
    _supportController = TextEditingController(
      text: isEditing ? widget.vacancyToEdit!['apoyo'] ?? '\$4,000 Mensual' : '',
    );

    if (isEditing) {
      _opportunityType = widget.vacancyToEdit!['tipo'] ?? 'Residencias';
      _requiredGpa = widget.vacancyToEdit!['gpa'] ?? 8.0;
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

  void _addRequirement() {
    final text = _newRequirementController.text.trim();
    if (text.isNotEmpty && !_requirementsList.contains(text)) {
      setState(() {
        _requirementsList.add(text);
        _newRequirementController.clear();
      });
    }
  }

  void _submitVacancy() {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.vacancyToEdit != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing 
            ? '¡Vacante modificada con éxito visualmente!' 
            : '¡Nueva vacante publicada con éxito en RedTESO!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      if (isEditing) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vacancyToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isEditing 
          ? AppBar(
              title: const Text('Modificar Vacante'),
              foregroundColor: AppTheme.primaryGreen,
              backgroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEditing) ...[
                const Text(
                  'Publicar Vacante',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Text(
                  'Atrae el mejor talento de ingeniería rellenando el formulario:',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
              ],
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del Puesto (ej: Desarrollador Backend)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Por favor ingresa el título' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _opportunityType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Oportunidad',
                  prefixIcon: Icon(Icons.layers_outlined),
                ),
                items: ['Servicio Social', 'Residencias', 'Empleo Egresados']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _opportunityType = val!),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _supportController,
                      decoration: const InputDecoration(
                        labelText: 'Apoyo / Salario',
                        prefixIcon: Icon(Icons.monetization_on),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción de las actividades y responsabilidades',
                  alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Por favor ingresa la descripción' : null,
              ),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 12),
              const Text('Criterios de Filtro Solicitados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Promedio mínimo exigido:', style: TextStyle(color: Colors.grey[700])),
                  Text(
                    _requiredGpa.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 16),
                  ),
                ],
              ),
              Slider(
                value: _requiredGpa,
                min: 7.0,
                max: 10.0,
                divisions: 30,
                activeColor: AppTheme.primaryGreen,
                onChanged: (val) => setState(() => _requiredGpa = val),
              ),

              SwitchListTile(
                title: const Text('¿Es obligatorio el idioma Inglés?'),
                subtitle: const Text('Filtrará perfiles con inglés básico'),
                value: _requiresEnglish,
                activeColor: AppTheme.primaryGreen,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _requiresEnglish = val),
              ),
              const SizedBox(height: 16),

              const Text('Habilidades deseadas (Tags):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newRequirementController,
                      decoration: const InputDecoration(
                        hintText: 'ej: React, Linux, Scrum',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addRequirement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(54, 50),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _requirementsList.map((req) {
                  return Chip(
                    label: Text(req),
                    onDeleted: () {
                      setState(() {
                        _requirementsList.remove(req);
                      });
                    },
                    deleteIconColor: Colors.red,
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _submitVacancy,
                child: Text(isEditing ? 'GUARDAR MODIFICACIONES' : 'PUBLICAR OFERTA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

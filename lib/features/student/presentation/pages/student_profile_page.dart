import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  // Datos simulados modificables en UI
  final _nameController = TextEditingController(text: 'Juan Pérez López');
  final _phoneController = TextEditingController(text: '5512345678');
  String _selectedModality = 'Residencias';
  double _gpa = 9.2;
  
  final List<String> _skills = ['Flutter', 'Dart', 'Firebase', 'SQL', 'Git', 'Scrum'];
  final _skillController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Perfil académico actualizado visualmente!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con Fotografía (Módulo de Perfil)
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 70, color: AppTheme.primaryGreen),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ingeniería en Sistemas Computacionales',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                  Text(
                    'Matrícula: 2020210340',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sección 1: Datos Personales y Académicos
            const Text(
              'Datos Generales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono de Contacto',
                prefixIcon: Icon(Icons.phone_android_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedModality,
              decoration: const InputDecoration(
                labelText: 'Modalidad / Estatus Actual',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: ['Servicio Social', 'Residencias', 'Recién Egresado']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedModality = val!),
            ),
            const SizedBox(height: 24),

            // Sección 2: Rendimiento (Promedio)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Promedio Académico: ${_gpa.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.star, color: Colors.amber),
              ],
            ),
            Slider(
              value: _gpa,
              min: 7.0,
              max: 10.0,
              divisions: 30,
              activeColor: AppTheme.primaryGreen,
              label: _gpa.toStringAsFixed(1),
              onChanged: (val) => setState(() => _gpa = val),
            ),
            const SizedBox(height: 24),

            // Sección 3: Habilidades Técnicas (Chips dinámicos)
            const Text(
              'Habilidades Técnicas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: const InputDecoration(
                      hintText: 'Agregar habilidad (ej: Java, Python)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addSkill,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(60, 50),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: Colors.white,
                  labelStyle: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onDeleted: () {
                    setState(() {
                      _skills.remove(skill);
                    });
                  },
                  deleteIconColor: Colors.red,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Sección 4: Documentos Comprobatorios
            const Text(
              'Documentos Comprobatorios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildDocumentTile('Constancia de Créditos / Kárdex', true),
            _buildDocumentTile('Carta de Presentación', false),
            _buildDocumentTile('Currículum Vitae (PDF)', true),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('GUARDAR CAMBIOS'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(String docName, bool uploaded) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          uploaded ? Icons.picture_as_pdf : Icons.picture_as_pdf_outlined,
          color: uploaded ? Colors.red : Colors.grey,
        ),
        title: Text(docName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          uploaded ? 'Cargado correctamente' : 'Pendiente de subir',
          style: TextStyle(color: uploaded ? AppTheme.primaryGreen : Colors.orange, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(uploaded ? Icons.replay : Icons.upload_file, color: AppTheme.primaryGreen),
          onPressed: () {},
        ),
      ),
    );
  }
}

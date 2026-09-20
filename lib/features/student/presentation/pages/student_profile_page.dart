import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _nameController = TextEditingController(text: 'Juan Pérez López');
  final _phoneController = TextEditingController(text: '5512345678');
  String _selectedModality = 'Residencias';
  double _gpa = 9.2;
  
  final List<String> _skills = ['Flutter', 'Dart', 'Firebase', 'SQL', 'Git', 'Scrum'];
  final _skillController = TextEditingController();

  // Estados para simular carga de archivos
  final Map<String, double> _uploadProgress = {};
  final Map<String, bool> _isUploaded = {
    'Kárdex': true,
    'Carta': false,
    'CV': true,
  };

  final List<Map<String, dynamic>> _evaluations = [
    {
      'empresa': 'Tech Solutions TESOEM',
      'rating': 5,
      'comentario': 'Excelente desempeño en el desarrollo de módulos móviles. Demostró gran dominio de Flutter.',
      'fecha': 'Ene 2024'
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  // Simulación de pick de imagen (Visual)
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Cambiar Foto de Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
              title: const Text('Tomar Foto'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
              title: const Text('Elegir de Galería'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // Simulación de carga de archivo (Visual con progreso)
  Future<void> _simulateUpload(String docName) async {
    setState(() {
      _uploadProgress[docName] = 0.0;
      _isUploaded[docName] = false;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _uploadProgress[docName] = i / 10.0;
      });
    }

    setState(() {
      _uploadProgress.remove(docName);
      _isUploaded[docName] = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$docName subido correctamente'), backgroundColor: AppTheme.primaryGreen),
      );
    }
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
            // Cabecera con Fotografía Interactiva
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
                        child: GestureDetector(
                          onTap: _showImageSourceActionSheet,
                          child: const CircleAvatar(
                            backgroundColor: AppTheme.primaryGreen,
                            radius: 18,
                            child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Ingeniería en Sistemas Computacionales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  Text('Matrícula: 2020210340', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sección de Datos y Habilidades (Sin cambios drásticos para brevedad)
            const Text('Habilidades Técnicas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _skills.map((s) => Chip(label: Text(s), backgroundColor: Colors.white, side: const BorderSide(color: AppTheme.primaryGreen))).toList(),
            ),
            const SizedBox(height: 32),

            // NUEVO: SECCIÓN DE DOCUMENTOS CON PROGRESO
            const Text('Documentos Comprobatorios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInteractiveDocTile('Kárdex', 'Constancia de créditos oficial'),
            _buildInteractiveDocTile('Carta', 'Carta de presentación institucional'),
            _buildInteractiveDocTile('CV', 'Currículum Vitae actualizado (PDF)'),
            
            const SizedBox(height: 32),

            const Text('Prestigio Académico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._evaluations.map((e) => _buildEvaluationCard(e)).toList(),

            const SizedBox(height: 40),
            ElevatedButton(onPressed: () {}, child: const Text('GUARDAR PERFIL')),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveDocTile(String id, String desc) {
    bool uploading = _uploadProgress.containsKey(id);
    bool done = _isUploaded[id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                done ? Icons.check_circle : Icons.picture_as_pdf,
                color: done ? AppTheme.primaryGreen : Colors.grey,
              ),
              title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
              trailing: uploading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: Icon(done ? Icons.refresh : Icons.upload_file, color: AppTheme.primaryGreen),
                    onPressed: () => _simulateUpload(id),
                  ),
            ),
            if (uploading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _uploadProgress[id],
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationCard(Map<String, dynamic> e) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: ListTile(
        title: Text(e['empresa'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(e['comentario']),
        trailing: const Icon(Icons.star, color: Colors.amber),
      ),
    );
  }
}

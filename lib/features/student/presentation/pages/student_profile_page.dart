import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _skillController;
  double _gpa = 8.0;
  String _modality = 'Servicio Social';
  List<String> _skills = [];
  bool _isLoading = true;

  final Map<String, double> _uploadProgress = {};
  final Map<String, bool> _isUploaded = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _skillController = TextEditingController();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _gpa = (data['gpa'] ?? 8.0).toDouble();
          _modality = data['modality'] ?? 'Servicio Social';
          _skills = List<String>.from(data['skills'] ?? []);
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _db.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gpa': _gpa,
        'modality': _modality,
        'skills': _skills,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Perfil actualizado con éxito!'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _simulateUpload(String docType) async {
    setState(() => _uploadProgress[docType] = 0.1);
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _uploadProgress[docType] = i / 10.0);
    }
    setState(() {
      _uploadProgress.remove(docType);
      _isUploaded[docType] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mi Perfil Profesional', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveProfile,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cabecera y Foto
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      child: const Icon(Icons.person, size: 60, color: AppTheme.primaryGreen),
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
              ),
              const SizedBox(height: 32),

              // 2. Datos Generales
              const Text('Información Académica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _modality,
                decoration: const InputDecoration(labelText: 'Estado Actual', prefixIcon: Icon(Icons.school_outlined)),
                items: ['Servicio Social', 'Residencias', 'Recién Egresado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _modality = val!),
              ),
              const SizedBox(height: 24),
              Text('Promedio: ${_gpa.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _gpa,
                min: 7.0, max: 10.0, divisions: 30,
                activeColor: AppTheme.primaryGreen,
                onChanged: (val) => setState(() => _gpa = val),
              ),

              const SizedBox(height: 32),

              // 3. Habilidades
              const Text('Habilidades Técnicas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillController,
                      decoration: const InputDecoration(hintText: 'ej: Java, SQL, Git'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSkill,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(50, 50)),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _skills.map((s) => Chip(
                  label: Text(s),
                  onDeleted: () => setState(() => _skills.remove(s)),
                  deleteIconColor: Colors.red,
                )).toList(),
              ),

              const SizedBox(height: 32),
              const Divider(),

              // 4. Prestigio Académico (Real-Time)
              const Row(
                children: [
                  Icon(Icons.verified, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('Prestigio y Evaluaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _buildRealTimeEvaluations(),

              const SizedBox(height: 32),

              // 5. Documentos
              const Text('Documentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildFileCard('Kárdex Oficial'),
              _buildFileCard('CV en PDF'),

              const SizedBox(height: 48),
              Center(
                child: TextButton.icon(
                  onPressed: () => _auth.signOut(),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('CERRAR SESIÓN', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealTimeEvaluations() {
    final user = _auth.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('evaluations').where('studentId', isEqualTo: user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Aún no tienes evaluaciones.', style: TextStyle(color: Colors.grey, fontSize: 12));
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['companyName'] ?? 'Empresa', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['comment'] ?? ''),
                trailing: Text('${data['rating']} ⭐', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFileCard(String title) {
    bool uploading = _uploadProgress.containsKey(title);
    bool done = _isUploaded[title] ?? false;
    return Card(
      child: ListTile(
        leading: Icon(done ? Icons.check_circle : Icons.upload_file, color: done ? AppTheme.primaryGreen : Colors.grey),
        title: Text(title),
        subtitle: uploading ? LinearProgressIndicator(value: _uploadProgress[title]) : const Text('PDF / DOCX'),
        trailing: IconButton(icon: const Icon(Icons.add), onPressed: () => _simulateUpload(title)),
      ),
    );
  }
}

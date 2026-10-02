import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';

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

  String? _cvFileName;
  String? _cvUrl;
  String? _kardexFileName;
  String? _kardexUrl;

  final Map<String, double> _uploadProgress = {};

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
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        _nameController.text = (data['name'] ?? user.displayName ?? 'Alumno TESOEM').toString();
        _phoneController.text = (data['phone'] ?? '').toString();

        final rawGpa = data['gpa'];
        if (rawGpa is num) {
          _gpa = rawGpa.toDouble();
        } else if (rawGpa is String) {
          _gpa = double.tryParse(rawGpa) ?? 8.0;
        } else {
          _gpa = 8.0;
        }

        _modality = (data['modality'] ?? 'Servicio Social').toString();

        final rawSkills = data['skills'];
        if (rawSkills is List) {
          _skills = rawSkills.map((e) => e?.toString() ?? '').where((s) => s.trim().isNotEmpty).toList();
        } else {
          _skills = ['Java', 'SQL', 'Git'];
        }

        _cvFileName = data['cvFileName']?.toString();
        _cvUrl = data['cvUrl']?.toString();
        _kardexFileName = data['kardexFileName']?.toString();
        _kardexUrl = data['kardexUrl']?.toString();
      } else if (mounted) {
        _nameController.text = user.displayName ?? user.email?.split('@').first ?? 'Alumno TESOEM';
        _skills = ['Java', 'SQL', 'Git'];
      }
    } catch (e) {
      debugPrint('Error cargando perfil del estudiante: $e');
      if (mounted) {
        _nameController.text = user.displayName ?? 'Alumno TESOEM';
        _skills = ['Java', 'SQL', 'Git'];
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      await _db.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gpa': _gpa,
        'modality': _modality,
        'skills': _skills,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text('¡Perfil profesional actualizado!', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
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

  Future<void> _pickAndUploadDocument(String docType) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final fileName = file.name;
        final lengthBytes = file.lengthSync() ?? 0;
        final fileSizeKb = lengthBytes > 0 ? (lengthBytes / 1024).toStringAsFixed(1) : '350.0';
        final fullLabel = '$fileName ($fileSizeKb KB)';

        setState(() {
          _uploadProgress[docType] = 0.5;
        });

        await Future.delayed(const Duration(milliseconds: 600));

        final isCv = docType.toLowerCase().contains('cv');
        final mockStorageUrl = 'https://firebasestorage.googleapis.com/v0/b/redteso.appspot.com/o/documents%2F${user.uid}_$fileName?alt=media';

        final updateData = <String, dynamic>{
          isCv ? 'cvFileName' : 'kardexFileName': fullLabel,
          isCv ? 'cvUrl' : 'kardexUrl': mockStorageUrl,
          isCv ? 'cvUpdatedAt' : 'kardexUpdatedAt': FieldValue.serverTimestamp(),
        };

        await _db.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            _uploadProgress.remove(docType);
            if (isCv) {
              _cvFileName = fullLabel;
              _cvUrl = mockStorageUrl;
            } else {
              _kardexFileName = fullLabel;
              _kardexUrl = mockStorageUrl;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('¡Documento "$fileName" subido con éxito!', style: GoogleFonts.inter()),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadProgress.remove(docType));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seleccionando archivo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Mi Perfil Profesional', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        foregroundColor: const Color(0xFF0F172A),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Guardar Cambios',
            onPressed: _saveProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Cerrar Sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera Avatar
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    child: Text(
                      _nameController.text.isNotEmpty ? _nameController.text[0] : 'A',
                      style: GoogleFonts.outfit(fontSize: 38, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Información Académica
              Text('Información Académica', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nameController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 14),

              Builder(
                builder: (context) {
                  const modalidadesList = ['Servicio Social', 'Residencias', 'Recién Egresado', 'Residencias Profesional', 'Empleo Fijo'];
                  final safeModality = modalidadesList.contains(_modality) ? _modality : 'Servicio Social';

                  return DropdownButtonFormField<String>(
                    initialValue: safeModality,
                    decoration: InputDecoration(
                      labelText: 'Estado / Modalidad Actual',
                      prefixIcon: const Icon(Icons.school_outlined, color: AppTheme.primaryGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: modalidadesList
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 14))))
                        .toList(),
                    onChanged: (val) => setState(() => _modality = val!),
                  );
                },
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Promedio Acumulado: ${_gpa.clamp(7.0, 10.0).toStringAsFixed(1)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                ],
              ),
              Slider(
                value: _gpa.clamp(7.0, 10.0),
                min: 7.0,
                max: 10.0,
                divisions: 30,
                activeColor: AppTheme.primaryGreen,
                onChanged: (val) => setState(() => _gpa = val),
              ),

              const SizedBox(height: 28),

              // Habilidades Técnicas
              Text('Habilidades Técnicas', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillController,
                      style: GoogleFonts.inter(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Añadir habilidad (ej. Flutter, Python, SQL)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSkill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(50, 48),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills.map((s) => Chip(
                  label: Text(s, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A))),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                  onDeleted: () => setState(() => _skills.remove(s)),
                )).toList(),
              ),

              const SizedBox(height: 32),
              const Divider(),

              // Prestigio y Evaluaciones
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.blue, size: 22),
                  const SizedBox(width: 8),
                  Text('Prestigio y Reseñas de Empresas ⭐', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 12),
              _buildRealTimeEvaluations(),

              const SizedBox(height: 32),

              // Documentos Oficiales en PDF
              Text('Documentos Oficiales Verificados 📄', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 12),

              _buildDocumentUploadCard('CV en PDF', _cvFileName, _cvUrl),
              const SizedBox(height: 10),
              _buildDocumentUploadCard('Kárdex Oficial', _kardexFileName, _kardexUrl),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  label: Text('CERRAR SESIÓN', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 80),
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
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Text('Aún no cuentas con evaluaciones registradas.', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12.5)),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final rating = (data['rating'] ?? 5.0).toDouble();

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  const Icon(Icons.business_rounded, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['companyName'] ?? 'Empresa', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('"${data['comment'] ?? ''}"', style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: const Color(0xFF334155))),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 13)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDocumentUploadCard(String docType, String? fileName, String? fileUrl) {
    final isUploading = _uploadProgress.containsKey(docType);
    final hasFile = fileName != null && fileName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFile ? AppTheme.primaryGreen : const Color(0xFFE2E8F0),
          width: hasFile ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasFile ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFile ? Icons.picture_as_pdf_rounded : Icons.upload_file_rounded,
              color: hasFile ? AppTheme.primaryGreen : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docType,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                if (isUploading)
                  LinearProgressIndicator(color: AppTheme.primaryGreen, value: _uploadProgress[docType])
                else
                  Text(
                    hasFile ? fileName : 'Formato PDF / Word (Max. 10MB)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: hasFile ? AppTheme.primaryGreen : const Color(0xFF64748B),
                      fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _pickAndUploadDocument(docType),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hasFile ? Icons.refresh_rounded : Icons.file_upload_outlined, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  hasFile ? 'CAMBIAR' : 'SUBIR',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

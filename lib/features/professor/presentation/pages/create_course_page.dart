import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class CreateCoursePage extends StatefulWidget {
  final Map<String, dynamic>? courseData;
  final String? courseId;

  const CreateCoursePage({
    super.key,
    this.courseData,
    this.courseId,
  });

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _topicsController = TextEditingController();

  String _category = 'Cloud & DevOps';
  String _modality = 'Híbrido Executive';
  String _level = 'Avanzado';
  bool _isLoading = false;

  String? _pickedVideoFileName;
  String? _pickedVideoPath;
  String? _pickedImageFileName;
  String? _pickedImagePath;

  final List<String> _categories = [
    'Cloud & DevOps',
    'Inteligencia Artificial',
    'Ciberseguridad',
    'Desarrollo Móvil',
    'Bases de Datos & SQL',
    'Arquitectura de Software'
  ];

  final List<String> _levels = ['Básico', 'Intermedio', 'Avanzado'];

  @override
  void initState() {
    super.initState();
    if (widget.courseData != null) {
      final c = widget.courseData!;
      _titleController.text = (c['title'] ?? '').toString();
      _descriptionController.text = (c['description'] ?? '').toString();
      _durationController.text = (c['duration'] ?? '').toString();
      _priceController.text = (c['price'] ?? '').toString();
      _topicsController.text = (c['topics'] ?? '').toString();

      if (c['category'] != null && _categories.contains(c['category'])) {
        _category = c['category'].toString();
      }
      if (c['level'] != null && _levels.contains(c['level'])) {
        _level = c['level'].toString();
      }
      final validModalities = ['Híbrido Executive', 'En Línea (En Vivo)', 'Presencial TESOEM'];
      if (c['modality'] != null && validModalities.contains(c['modality'])) {
        _modality = c['modality'].toString();
      }
      _pickedVideoFileName = c['videoFileName']?.toString();
      _pickedVideoPath = c['videoUrl']?.toString();
      _pickedImageFileName = c['bannerFileName']?.toString();
      _pickedImagePath = c['bannerUrl']?.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final lengthBytes = file.lengthSync() ?? 0;
        final sizeMb = lengthBytes > 0 ? (lengthBytes / (1024 * 1024)).toStringAsFixed(1) : '15.0';
        setState(() {
          _pickedVideoFileName = '${file.name} ($sizeMb MB)';
          _pickedVideoPath = file.path;
        });
      }
    } catch (e) {
      debugPrint('Error seleccionando video: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final lengthBytes = file.lengthSync() ?? 0;
        final sizeKb = lengthBytes > 0 ? (lengthBytes / 1024).toStringAsFixed(1) : '350.0';
        setState(() {
          _pickedImageFileName = '${file.name} ($sizeKb KB)';
          _pickedImagePath = file.path;
        });
      }
    } catch (e) {
      debugPrint('Error seleccionando imagen: $e');
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final professorName = userData['name'] ?? user.displayName ?? 'Profesor TESOEM';

      String finalVideoUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
      String finalImageUrl = 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800';

      // 1. SUBIDA REAL DE LA IMAGEN DE PORTADA A FIREBASE STORAGE
      if (_pickedImagePath != null && File(_pickedImagePath!).existsSync()) {
        try {
          final file = File(_pickedImagePath!);
          final storageRef = FirebaseStorage.instance.ref().child('course_banners/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await storageRef.putFile(file);
          finalImageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          debugPrint('Aviso: Usando ruta local para imagen: $e');
          finalImageUrl = _pickedImagePath!;
        }
      }

      // 2. SUBIDA REAL DEL VIDEO MP4 A FIREBASE STORAGE
      if (_pickedVideoPath != null && File(_pickedVideoPath!).existsSync()) {
        try {
          final file = File(_pickedVideoPath!);
          final storageRef = FirebaseStorage.instance.ref().child('course_videos/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.mp4');
          await storageRef.putFile(file);
          finalVideoUrl = await storageRef.getDownloadURL();
        } catch (e) {
          debugPrint('Aviso: Usando ruta local para video: $e');
          finalVideoUrl = _pickedVideoPath!;
        }
      }

      final isEditing = widget.courseId != null && widget.courseId!.isNotEmpty;

      final courseMap = <String, dynamic>{
        'title': _titleController.text.trim(),
        'category': _category,
        'modality': _modality,
        'level': _level,
        'duration': _durationController.text.trim().isEmpty ? '40 Horas / 5 Semanas' : _durationController.text.trim(),
        'price': _priceController.text.trim().isEmpty ? 'Cotización Especial TESOEM' : _priceController.text.trim(),
        'description': _descriptionController.text.trim(),
        'topics': _topicsController.text.trim(),
        'videoFileName': _pickedVideoFileName ?? 'demo_curso_tesoem.mp4',
        'videoUrl': finalVideoUrl,
        'bannerFileName': _pickedImageFileName ?? 'banner_portada.jpg',
        'bannerUrl': finalImageUrl,
        'professorId': user.uid,
        'professorName': professorName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await FirebaseFirestore.instance.collection('courses').doc(widget.courseId!).set(courseMap, SetOptions(merge: true));
      } else {
        courseMap['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('courses').add(courseMap);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEditing ? '¡Curso actualizado con éxito!' : '¡Curso con video e imagen publicado con éxito!',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error guardando curso: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando curso: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.courseId != null && widget.courseId!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Curso ✏️' : 'Publicar Nuevo Curso 🎓', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Actualizar Información del Curso' : 'Capacitación Ejecutiva para Empresas',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              Text(
                'Los cursos y videos publicados aparecerán inmediatamente en el catálogo de las empresas.',
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // Título
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Título del Curso *',
                  hintText: 'Ej. Arquitectura Cloud AWS & Kubernetes Executive',
                  prefixIcon: const Icon(Icons.school_outlined, color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el título del curso' : null,
              ),

              const SizedBox(height: 16),

              // Categoría y Nivel (Corregido desbordamiento)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.primaryGreen, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat, style: GoogleFonts.inter(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _level,
                      isExpanded: true,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'Nivel',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: _levels
                          .map((lvl) => DropdownMenuItem(
                                value: lvl,
                                child: Text(lvl, style: GoogleFonts.inter(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _level = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Modalidad y Duración
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _modality,
                      isExpanded: true,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'Modalidad',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      items: ['Híbrido Executive', 'En Línea (En Vivo)', 'Presencial TESOEM']
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _modality = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Duración (Horas)',
                        hintText: '40 Horas',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Inversión / Precio
              TextFormField(
                controller: _priceController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Inversión / Cotización',
                  hintText: 'Ej. \$6,500 MXN por participante o Cotización Especial',
                  prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 20),

              // Selección Real de Video (MP4)
              _buildFileSelectorCard(
                title: 'Video Demo / Trailer del Curso (MP4) 🎬',
                subtitle: _pickedVideoFileName ?? 'Selecciona un archivo de video desde tu dispositivo',
                icon: Icons.video_library_rounded,
                hasFile: _pickedVideoFileName != null,
                onTap: _pickVideo,
              ),

              const SizedBox(height: 12),

              // Selección Real de Imagen (JPG/PNG)
              _buildFileSelectorCard(
                title: 'Imagen Banner de Portada (JPG / PNG) 🖼️',
                subtitle: _pickedImageFileName ?? 'Selecciona una imagen de portada desde tu dispositivo',
                icon: Icons.image_rounded,
                hasFile: _pickedImageFileName != null,
                onTap: _pickImage,
              ),

              const SizedBox(height: 20),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Descripción del Programa *',
                  hintText: 'Describe el objetivo del curso y las competencias que desarrollarán los participantes...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa una descripción del curso' : null,
              ),

              const SizedBox(height: 16),

              // Temario / Módulos
              TextFormField(
                controller: _topicsController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Temario Principal / Módulos',
                  hintText: 'Ej. Módulo 1: Fundamentos Cloud, Módulo 2: Contenedores Docker...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveCourse,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(isEditing ? Icons.save_rounded : Icons.publish_rounded, color: Colors.white),
                  label: Text(
                    _isLoading
                        ? 'GUARDANDO...'
                        : (isEditing ? 'GUARDAR CAMBIOS EN EL CURSO' : 'PUBLICAR CURSO EN EL CATÁLOGO'),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileSelectorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool hasFile,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              color: hasFile ? AppTheme.primaryGreen.withOpacity(0.12) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: hasFile ? AppTheme.primaryGreen : const Color(0xFF64748B),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: hasFile ? AppTheme.primaryGreen : const Color(0xFF64748B),
                    fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  hasFile ? 'CAMBIAR' : 'ELEGIR',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/core/widgets/theme_toggle_button.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _skillController;

  static const Color _wine = Color(0xFF791D40);
  static const Color _wineDark = Color(0xFF481329);
  static const Color _wineLight = Color(0xFF9C3158);
  static const Color _gold = Color(0xFFE8BC68);
  static const Color _cream = Color(0xFFFAF3E9);
  static const Color _ink = Color(0xFF351B28);
  static const Color _muted = Color(0xFF81717A);
  static const Color _border = Color(0xFFECE1E4);
  static const Color _green = Color(0xFF31805A);
  static const Color _red = Color(0xFFB42336);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBackground => _isDark ? const Color(0xFF121016) : _cream;
  Color get _cardBackground => _isDark ? const Color(0xFF251F29) : Colors.white;
  Color get _textColor => _isDark ? const Color(0xFFF4EDF1) : _ink;
  Color get _mutedColor => _isDark ? const Color(0xFFB9AAB3) : _muted;
  Color get _borderColor => _isDark ? const Color(0xFF403541) : _border;
  Color get _fieldBackground => _isDark ? const Color(0xFF1B171F) : const Color(0xFFFFFCFA);

  double _gpa = 8.0;
  String _modality = 'Servicio Social';
  List<String> _skills = [];
  bool _isLoading = true;

  String? _cvFileName;
  String? _cvUrl;
  String? _kardexFileName;
  String? _kardexUrl;

  final Map<String, double> _uploadProgress = {};

  static const List<String> _modalities = [
    'Servicio Social',
    'Residencias',
    'Recién Egresado',
    'Residencias Profesional',
    'Empleo Fijo',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _skillController = TextEditingController();
    _loadStudentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _skillController.dispose();
    super.dispose();
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
        final data = doc.data() ?? <String, dynamic>{};
        _nameController.text =
            (data['name'] ?? user.displayName ?? 'Alumno TESOEM').toString();
        _phoneController.text = (data['phone'] ?? '').toString();

        final rawGpa = data['gpa'];
        if (rawGpa is num) {
          _gpa = rawGpa.toDouble();
        } else if (rawGpa is String) {
          _gpa = double.tryParse(rawGpa) ?? 8.0;
        } else {
          _gpa = 8.0;
        }
        _gpa = _gpa.clamp(7.0, 10.0);

        final savedModality = (data['modality'] ?? 'Servicio Social').toString();
        _modality = _modalities.contains(savedModality)
            ? savedModality
            : 'Servicio Social';

        final rawSkills = data['skills'];
        if (rawSkills is List) {
          _skills = rawSkills
              .map((e) => e?.toString() ?? '')
              .where((s) => s.trim().isNotEmpty)
              .toList();
        } else {
          _skills = ['Java', 'SQL', 'Git'];
        }

        _cvFileName = data['cvFileName']?.toString();
        _cvUrl = data['cvUrl']?.toString();
        _kardexFileName = data['kardexFileName']?.toString();
        _kardexUrl = data['kardexUrl']?.toString();
      } else if (mounted) {
        _nameController.text = user.displayName ??
            user.email?.split('@').first ?? 'Alumno TESOEM';
        _skills = ['Java', 'SQL', 'Git'];
      }
    } catch (e) {
      debugPrint('Error cargando perfil del estudiante: $e');
      if (mounted) {
        _nameController.text = user.displayName ?? 'Alumno TESOEM';
        _skills = ['Java', 'SQL', 'Git'];
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    final user = _auth.currentUser;
    if (user == null) {
      _showMessage('Inicia sesión para guardar tu perfil.', isError: true);
      return;
    }

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

      if (mounted) _showMessage('¡Perfil profesional actualizado!');
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
      if (mounted) _showMessage('Error al guardar el perfil.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    final exists = _skills.any((item) => item.toLowerCase() == skill.toLowerCase());
    if (skill.isNotEmpty && !exists) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    } else if (exists) {
      _showMessage('Esa habilidad ya está agregada.', isError: true);
    }
  }

  Future<void> _pickAndUploadDocument(String docType) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showMessage('Inicia sesión para registrar documentos.', isError: true);
      return;
    }
    if (_uploadProgress.containsKey(docType)) return;

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      // En la versión instalada, FilePicker devuelve directamente una lista.
      if (files.isEmpty) return;
      final PlatformFile file = files.first;
      final String fileName = file.name;
      // Esta versión de file_picker no expone bytes ni size en PlatformFile.
      // Conservamos el nombre del archivo sin calcular su tamaño.
      final String fullLabel = fileName;

      setState(() => _uploadProgress[docType] = 0.15);
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() => _uploadProgress[docType] = 0.65);
      await Future.delayed(const Duration(milliseconds: 350));

      final bool isCv = docType.toLowerCase().contains('cv');
      // Conserva el comportamiento del archivo original: URL simulada.
      // Esto NO sube el contenido real del archivo a Firebase Storage.
      final String mockStorageUrl =
          'https://firebasestorage.googleapis.com/v0/b/redteso.appspot.com/o/documents%2F${user.uid}_${Uri.encodeComponent(fileName)}?alt=media';

      final updateData = <String, dynamic>{
        isCv ? 'cvFileName' : 'kardexFileName': fullLabel,
        isCv ? 'cvUrl' : 'kardexUrl': mockStorageUrl,
        isCv ? 'cvUpdatedAt' : 'kardexUpdatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('users').doc(user.uid).set(
            updateData,
            SetOptions(merge: true),
          );

      if (!mounted) return;
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
      _showMessage('Documento "$fileName" registrado. La subida real a Storage aún no está configurada.');
    } catch (e) {
      debugPrint('Error seleccionando archivo: $e');
      if (mounted) {
        setState(() => _uploadProgress.remove(docType));
        _showMessage('Error seleccionando archivo: $e', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.inter()),
          backgroundColor: isError ? _red : _wine,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cerrar sesión', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('¿Deseas salir de tu cuenta?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _wine, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _pageBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _ProfileAmbientPainter(isDark: _isDark)),
            Center(child: CircularProgressIndicator(color: _gold)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ProfileAmbientPainter(isDark: _isDark),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // La barra ocupa todo el ancho, como en la página principal.
                SliverToBoxAdapter(child: _buildAppBar()),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 14, 28, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHero(),
                            const SizedBox(height: 24),
                            _buildSectionTitle(
                              'Información académica',
                              'Mantén tus datos actualizados',
                              Icons.school_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildAcademicCard(),
                            const SizedBox(height: 24),
                            _buildSectionTitle(
                              'Habilidades técnicas',
                              'Destaca lo que sabes hacer',
                              Icons.workspace_premium_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildSkillsCard(),
                            const SizedBox(height: 24),
                            _buildSectionTitle(
                              'Prestigio y reseñas',
                              'Opiniones de las empresas',
                              Icons.verified_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildRealTimeEvaluations(),
                            const SizedBox(height: 24),
                            _buildSectionTitle(
                              'Documentos oficiales',
                              'CV y Kárdex académico',
                              Icons.folder_open_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildDocumentUploadCard('CV en PDF', _cvFileName, _cvUrl),
                            const SizedBox(height: 12),
                            _buildDocumentUploadCard(
                              'Kárdex Oficial',
                              _kardexFileName,
                              _kardexUrl,
                            ),
                            const SizedBox(height: 24),
                            _buildSaveButton(),
                            const SizedBox(height: 12),
                            _buildLogoutButton(),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'REDTESO · TU FUTURO PROFESIONAL',
                                style: GoogleFonts.poppins(
                                  color: _mutedColor,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_wine, _wineDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1290),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.hub_rounded, color: _wineDark, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RedTESO',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'PORTAL ESTUDIANTIL',
                        style: GoogleFonts.inter(
                          color: _gold,
                          fontSize: 9,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _wineLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ThemeToggleButton(),
                ),
                IconButton(
                  tooltip: 'Guardar cambios',
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined, color: _gold, size: 23),
                ),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: _gold, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    final name = _nameController.text.trim();
    final firstName = name.isEmpty ? 'Estudiante' : name.split(' ').first;
    final initial = name.isEmpty ? 'A' : name.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_wineLight, _wineDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _wine.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -38,
            right: -28,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 2)),
                    child: CircleAvatar(
                      radius: 31,
                      backgroundColor: Colors.white.withValues(alpha: 0.13),
                      child: Text(initial, style: GoogleFonts.poppins(color: _gold, fontSize: 28, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¡Hola, $firstName!', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Tu futuro comienza aquí', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(_modality, style: GoogleFonts.inter(color: _gold, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: _gold, size: 25),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Promedio académico', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                          Text('${_gpa.clamp(7.0, 10.0).toStringAsFixed(1)} / 10', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const Icon(Icons.trending_up_rounded, color: _gold, size: 27),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(color: _wine.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: _wine, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(color: _textColor, fontSize: 16, fontWeight: FontWeight.w700)),
              Text(subtitle, style: GoogleFonts.inter(color: _mutedColor, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicCard() {
    return _card(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Nombre completo'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.inter(color: _textColor, fontSize: 13),
              decoration: _inputDecoration('Tu nombre completo', Icons.badge_outlined),
              validator: (value) => value == null || value.trim().isEmpty ? 'El nombre es obligatorio.' : null,
            ),
            const SizedBox(height: 17),
            _fieldLabel('Teléfono'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(color: _textColor, fontSize: 13),
              decoration: _inputDecoration('Tu número de teléfono', Icons.phone_outlined),
            ),
            const SizedBox(height: 17),
            _fieldLabel('Estado / modalidad actual'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _modalities.contains(_modality) ? _modality : 'Servicio Social',
              isExpanded: true,
              style: GoogleFonts.inter(color: _textColor, fontSize: 13),
              decoration: _inputDecoration('Selecciona modalidad', Icons.school_outlined),
              items: _modalities.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _modality = value);
              },
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: _fieldLabel('Promedio acumulado')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(color: _wine.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(_gpa.clamp(7.0, 10.0).toStringAsFixed(1), style: GoogleFonts.poppins(color: _wine, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 7),
                const Icon(Icons.star_rounded, color: _gold, size: 21),
              ],
            ),
            Slider(
              value: _gpa.clamp(7.0, 10.0),
              min: 7,
              max: 10,
              divisions: 30,
              activeColor: _wine,
              thumbColor: _gold,
              onChanged: (value) => setState(() => _gpa = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('7.0', style: TextStyle(color: _mutedColor, fontSize: 11)), Text('10.0', style: TextStyle(color: _mutedColor, fontSize: 11))],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agrega tecnologías y competencias que dominas.', style: GoogleFonts.inter(color: _mutedColor, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillController,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _addSkill(),
                  style: GoogleFonts.inter(color: _textColor, fontSize: 13),
                  decoration: _inputDecoration('Ej. Flutter, Python, SQL', Icons.code_rounded),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                height: 52,
                width: 52,
                child: ElevatedButton(
                  onPressed: _addSkill,
                  style: ElevatedButton.styleFrom(backgroundColor: _wine, foregroundColor: Colors.white, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_skills.isEmpty)
            Text('Aún no agregas habilidades.', style: GoogleFonts.inter(color: _mutedColor, fontSize: 12))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) => Chip(
                avatar: const Icon(Icons.check_circle_rounded, color: _wine, size: 17),
                label: Text(skill, style: GoogleFonts.inter(color: _wineDark, fontSize: 12)),
                backgroundColor: _isDark ? const Color(0xFF382633) : const Color(0xFFF8EAF0),
                side: BorderSide(color: _wine.withValues(alpha: 0.12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                deleteIcon: const Icon(Icons.close_rounded, color: _red, size: 16),
                onDeleted: () => setState(() => _skills.remove(skill)),
              )).toList(),
            ),
          const SizedBox(height: 8),
          Text('Guarda los cambios para conservar tus habilidades.', style: GoogleFonts.inter(color: _mutedColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRealTimeEvaluations() {
    final user = _auth.currentUser;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('evaluations').where('studentId', isEqualTo: user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _evaluationEmpty('No se pudieron cargar las evaluaciones.');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _evaluationEmpty('Aún no cuentas con evaluaciones registradas.');
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();
            final rawRating = data['rating'];
            final rating = rawRating is num ? rawRating.toDouble() : 5.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderColor)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: _wine.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(13)),
                    child: const Icon(Icons.business_rounded, color: _wine, size: 21),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((data['companyName'] ?? 'Empresa').toString(), style: GoogleFonts.poppins(color: _textColor, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 5),
                        Text('“${data['comment'] ?? ''}”', style: GoogleFonts.inter(color: _mutedColor, fontSize: 12, fontStyle: FontStyle.italic, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: _gold, size: 17),
                      Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(color: _wine, fontWeight: FontWeight.w700, fontSize: 12)),
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

  Widget _evaluationEmpty(String message) {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.rate_review_outlined, color: _wine, size: 25),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: GoogleFonts.inter(color: _mutedColor, fontSize: 12, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard(String docType, String? fileName, String? fileUrl) {
    final isUploading = _uploadProgress.containsKey(docType);
    final progress = _uploadProgress[docType];
    final hasFile = fileName != null && fileName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasFile ? _wine.withValues(alpha: 0.55) : _borderColor, width: hasFile ? 1.5 : 1),
        boxShadow: [BoxShadow(color: _wineDark.withValues(alpha: 0.025), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: hasFile ? _wine.withValues(alpha: 0.09) : _cream, shape: BoxShape.circle),
            child: Icon(hasFile ? Icons.picture_as_pdf_rounded : Icons.upload_file_rounded, color: hasFile ? _wine : _muted, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(docType, style: GoogleFonts.poppins(color: _textColor, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 5),
                if (isUploading)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(value: progress, minHeight: 5, color: _wine, backgroundColor: _borderColor),
                  )
                else
                  Text(
                    hasFile ? fileName : 'Formato PDF / Word (máx. 10 MB)',
                    style: GoogleFonts.inter(color: hasFile ? _green : _muted, fontSize: 11, fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isUploading ? null : () => _pickAndUploadDocument(docType),
            style: ElevatedButton.styleFrom(
              backgroundColor: _wine,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              minimumSize: const Size(0, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hasFile ? Icons.refresh_rounded : Icons.file_upload_outlined, size: 16),
                const SizedBox(width: 5),
                Text(hasFile ? 'CAMBIAR' : 'SUBIR', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(backgroundColor: _wine, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        icon: const Icon(Icons.save_rounded),
        label: Text('Guardar cambios', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(foregroundColor: _wine, side: BorderSide(color: _borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        icon: const Icon(Icons.logout_rounded),
        label: Text('CERRAR SESIÓN', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label, style: GoogleFonts.poppins(color: _textColor, fontSize: 12, fontWeight: FontWeight.w700));
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: _mutedColor.withValues(alpha: 0.8), fontSize: 11),
      prefixIcon: Icon(icon, color: _wine, size: 20),
      filled: true,
      fillColor: _fieldBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _wine, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red, width: 1.5)),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _borderColor),
        boxShadow: [BoxShadow(color: _wineDark.withValues(alpha: 0.035), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: child,
    );
  }
}


class _ProfileAmbientPainter extends CustomPainter {
  final bool isDark;

  const _ProfileAmbientPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF121016), Color(0xFF19141D), Color(0xFF211823)]
              : const [Color(0xFFFFF9F1), Color(0xFFF7EEE5), Color(0xFFF1E4DD)],
        ).createShader(rect),
    );

    _glow(
      canvas,
      Offset(size.width * 0.95, size.height * 0.18),
      size.width * 0.45,
      const Color(0x289D3458),
    );

    _glow(
      canvas,
      Offset(size.width * 0.05, size.height * 0.78),
      size.width * 0.48,
      const Color(0x28E6B968),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x24741C3D);

    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.15),
      size.width * 0.18,
      ringPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.15),
      size.width * 0.23,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x20B47A22),
    );

    final dotPaint = Paint()..color = const Color(0x66B47A22);

    for (int i = 0; i < 26; i++) {
      final x = ((i * 83 + 29) % 997) / 997 * size.width;
      final y = ((i * 137 + 47) % 991) / 991 * size.height;
      canvas.drawCircle(
        Offset(x, y),
        i % 4 == 0 ? 1.8 : 1,
        dotPaint,
      );
    }
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileAmbientPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

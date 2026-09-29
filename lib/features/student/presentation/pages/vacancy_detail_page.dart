import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/pages/company_profile_view_page.dart';
import 'package:red_teso/features/company/presentation/widgets/vacancy_location_map_widget.dart';

class VacancyDetailPage extends StatefulWidget {
  final Map<String, dynamic> vacancy;

  const VacancyDetailPage({super.key, required this.vacancy});

  @override
  State<VacancyDetailPage> createState() => _VacancyDetailPageState();
}

class _VacancyDetailPageState extends State<VacancyDetailPage> {
  bool _isApplying = false;
  bool _hasApplied = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyApplied();
  }

  // Verifica si el alumno ya se postuló anteriormente a esta vacante
  Future<void> _checkIfAlreadyApplied() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db
        .collection('applications')
        .where('studentId', isEqualTo: user.uid)
        .where('vacancyId', isEqualTo: widget.vacancy['id'])
        .get();

    if (doc.docs.isNotEmpty && mounted) {
      setState(() => _hasApplied = true);
    }
  }

  Future<void> _unapply() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Cancelar Postulación?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de cancelar tu postulación a "${widget.vacancy['puesto'] ?? 'esta vacante'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VOLVER'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SÍ, DESPOSTULARME', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isApplying = true);
      try {
        final docs = await _db
            .collection('applications')
            .where('studentId', isEqualTo: user.uid)
            .where('vacancyId', isEqualTo: widget.vacancy['id'])
            .get();

        for (final doc in docs.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          setState(() {
            _hasApplied = false;
            _isApplying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Postulación cancelada exitosamente', style: GoogleFonts.inter()),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isApplying = false);
        debugPrint('Error al cancelar postulación: $e');
      }
    }
  }

  void _apply() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isApplying = true);

    try {
      // Obtener el nombre real registrado del alumno desde Firestore
      String studentName = user.displayName ?? 'Alumno TESOEM';
      try {
        final studentDoc = await _db.collection('users').doc(user.uid).get();
        if (studentDoc.exists) {
          final data = studentDoc.data();
          final fetchedName = data?['name'] ?? data?['studentName'];
          if (fetchedName != null && fetchedName.toString().trim().isNotEmpty) {
            studentName = fetchedName.toString().trim();
          }
        }
      } catch (e) {
        debugPrint('Error obteniendo nombre del alumno: $e');
      }

      final companyId = widget.vacancy['companyId'] ?? '';
      final companyName = widget.vacancy['empresa'] ?? widget.vacancy['companyName'] ?? 'Empresa Colaboradora';

      // Guardar la postulación real en Firestore
      await _db.collection('applications').add({
        'studentId': user.uid,
        'studentName': studentName,
        'studentEmail': user.email ?? 'alumno@tesoem.edu.mx',
        'vacancyId': widget.vacancy['id'] ?? '',
        'vacancyName': widget.vacancy['puesto'] ?? 'Vacante TESOEM',
        'companyId': companyId,
        'companyName': companyName,
        'status': 'Enviado', // Estados: Enviado, En Revisión, En Entrevista, Aceptado, Descartado
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _hasApplied = true;
          _isApplying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text('¡Postulación enviada exitosamente!', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al postularse: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vacancy;
    final puesto = v['puesto'] ?? 'Vacante';
    final empresa = v['empresa'] ?? 'Empresa Colaboradora';
    final tipo = v['tipo'] ?? 'Residencias';
    final apoyo = v['apoyo'] ?? 0;
    final gpa = v['gpa'] ?? 8.0;
    final ingles = v['ingles'] ?? false;
    final ubicacion = v['ubicacion'] ?? 'Cerca de TESOEM / Los Reyes La Paz';
    final distanceKm = (v['distanceKm'] ?? 4.8).toDouble();
    final commuteMinutes = (v['commuteMinutes'] ?? 15).toInt();
    final transportTip = v['transportTip'] ?? 'Combi directa desde TESOEM o Metro Santa Marta';
    final requisitos = List<String>.from(v['requisitos'] ?? ['Proactividad', 'Trabajo en equipo']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Detalle de Vacante', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        foregroundColor: const Color(0xFF0F172A),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado principal de la Empresa
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CompanyProfileViewPage(companyName: empresa)),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'logo-${v['id']}',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.business_rounded, size: 36, color: AppTheme.primaryGreen),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            puesto,
                            style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                empresa,
                                style: GoogleFonts.inter(fontSize: 13.5, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.primaryGreen),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Chips resumen de modalidad y apoyo
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadgeChip(Icons.category_rounded, tipo, AppTheme.primaryGreen),
                _buildBadgeChip(Icons.monetization_on_rounded, '\$$apoyo MXN/mes', Colors.green),
                _buildBadgeChip(Icons.grade_rounded, 'GPA Mín: $gpa', Colors.orange),
                if (ingles) _buildBadgeChip(Icons.translate_rounded, 'Inglés Requerido', Colors.purple),
              ],
            ),

            const SizedBox(height: 24),

            // Tarjeta con Mapa Interactivo de la Ubicación y tiempo desde TESOEM
            VacancyLocationMapWidget(
              locationName: ubicacion,
              distanceKm: distanceKm,
              commuteMinutes: commuteMinutes,
              transportTip: transportTip,
              locationCoordinates: LatLng(
                (v['lat'] ?? 19.3621).toDouble(),
                (v['lng'] ?? -98.9806).toDouble(),
              ),
            ),

            const SizedBox(height: 24),

            // Sección Descripción
            Text('Descripción del Puesto', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                v['descripcion'] ?? 'Sin descripción disponible.',
                style: GoogleFonts.inter(fontSize: 13.5, height: 1.5, color: const Color(0xFF334155)),
              ),
            ),

            const SizedBox(height: 20),

            // Sección Requisitos
            Text('Habilidades y Requisitos', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: requisitos.map((req) {
                return Chip(
                  avatar: const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.primaryGreen),
                  label: Text(req, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A))),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

            // Botón Acción de Postulación / Cancelar Postulación
            if (_hasApplied)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Ya estás postulado a esta vacante',
                          style: GoogleFonts.outfit(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _unapply,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                      label: Text(
                        'CANCELAR POSTULACIÓN / DESPOSTULARME 🗑️',
                        style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              )
            else if (_isApplying)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'POSTULARME AHORA 🚀',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

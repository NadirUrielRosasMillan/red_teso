import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/pages/company_profile_view_page.dart';

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

  void _apply() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isApplying = true);

    try {
      // Guardar la postulación real en Firestore
      await _db.collection('applications').add({
        'studentId': user.uid,
        'studentName': user.displayName ?? 'Alumno TESOEM',
        'studentEmail': user.email,
        'vacancyId': widget.vacancy['id'],
        'vacancyName': widget.vacancy['puesto'],
        'companyId': widget.vacancy['companyId'],
        'companyName': widget.vacancy['empresa'],
        'status': 'Enviado', // Estados: Enviado, En Revisión, Aceptado, Rechazado
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _hasApplied = true;
          _isApplying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Postulación enviada exitosamente!'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al postularse: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vacancy;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Vacante'),
        foregroundColor: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado principal interactivo
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CompanyProfileViewPage(companyName: v['empresa'])),
                );
              },
              child: Row(
                children: [
                  Hero(
                    tag: 'logo-${v['id']}',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business, size: 48, color: AppTheme.primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['puesto'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(v['empresa'], style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Descripción', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(v['descripcion'] ?? 'Sin descripción disponible.', style: const TextStyle(height: 1.5)),
            const SizedBox(height: 40),

            if (_hasApplied)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Text('Ya estás postulado a esta vacante', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else if (_isApplying)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
                child: const Text('POSTULARME AHORA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

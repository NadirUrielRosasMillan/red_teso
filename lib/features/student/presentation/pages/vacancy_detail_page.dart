import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class VacancyDetailPage extends StatefulWidget {
  final Map<String, dynamic> vacancy;

  const VacancyDetailPage({super.key, required this.vacancy});

  @override
  State<VacancyDetailPage> createState() => _VacancyDetailPageState();
}

class _VacancyDetailPageState extends State<VacancyDetailPage> {
  bool _hasApplied = false;

  void _apply() {
    setState(() {
      _hasApplied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Te has postulado con éxito a ${widget.vacancy['puesto']}!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
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
            // Encabezado principal con animación Hero en el logo de la empresa
            Row(
              children: [
                Hero(
                  tag: 'logo-${v['id']}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business, size: 48, color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['puesto'] as String,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        v['empresa'] as String,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Chips identificadores
            Row(
              children: [
                Chip(
                  label: Text(v['tipo'] as String),
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('Promedio ≥ ${v['gpa']}'),
                  backgroundColor: Colors.orange[50],
                  labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Descripción de la Vacante',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              v['descripcion'] as String,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            const Text(
              'Requisitos Técnicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (v['requisitos'] as List<String>).map((req) {
                return Chip(
                  avatar: const Icon(Icons.check, size: 16, color: AppTheme.primaryGreen),
                  label: Text(req),
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // Botón de Postulación
            _hasApplied
                ? Container(
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
                        Text(
                          '¡Ya estás postulado a esta vacante!',
                          style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: const Text(
                      'POSTULARME AHORA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

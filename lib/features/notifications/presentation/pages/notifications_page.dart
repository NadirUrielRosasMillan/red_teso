import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  DateTime? _getDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  Future<void> _confirmDeleteNotification(BuildContext context, String docId, String title) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar Notificación?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('¿Deseas eliminar "$title" de tus avisos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notificación "$title" eliminada'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error al eliminar notificación: $e');
      }
    }
  }

  Future<void> _clearAllNotifications(BuildContext context, List<QueryDocumentSnapshot> docs) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Limpiar Notificaciones?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de eliminar todos los avisos recibidos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('LIMPIAR TODAS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se eliminaron todos los avisos'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error al limpiar notificaciones: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver notificaciones')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('toUserId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs.toList() ?? [];

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = _getDateTime(aData['createdAt']);
          final bTime = _getDateTime(bData['createdAt']);
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return -1;
          if (bTime == null) return 1;
          return bTime.compareTo(aTime);
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text('Notificaciones', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            foregroundColor: AppTheme.primaryGreen,
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (docs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.cleaning_services_rounded, color: Colors.red),
                  tooltip: 'Limpiar Todo',
                  onPressed: () => _clearAllNotifications(context, docs),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: snapshot.hasError
              ? Center(child: Text('Error: ${snapshot.error}'))
              : snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : docs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 70, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes avisos nuevos',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Las invitaciones y actualizaciones de tu proceso aparecerán aquí.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final docId = docs[index].id;
                            final n = docs[index].data() as Map<String, dynamic>;
                            final bool isRead = n['read'] ?? false;
                            final title = n['title'] ?? 'Aviso';
                            final message = n['message'] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : AppTheme.primaryGreen.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isRead ? const Color(0xFFE2E8F0) : AppTheme.primaryGreen.withValues(alpha: 0.3),
                                  width: isRead ? 1.0 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryGreen, size: 22),
                                ),
                                title: Text(
                                  title,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    message,
                                    style: GoogleFonts.inter(fontSize: 12.5, height: 1.35, color: const Color(0xFF334155)),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isRead)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                      tooltip: 'Eliminar',
                                      onPressed: () => _confirmDeleteNotification(context, docId, title),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Marcar como leída al tocar
                                  FirebaseFirestore.instance.collection('notifications').doc(docId).update({'read': true});
                                },
                              ),
                            );
                          },
                        ),
        );
      },
    );
  }
}

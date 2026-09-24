import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Inicia sesión')));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                  const Text('No tienes avisos nuevos', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final n = docs[index].data() as Map<String, dynamic>;
              final bool isRead = n['read'] ?? false;

              return Card(
                elevation: isRead ? 0 : 2,
                color: isRead ? Colors.grey[50] : Colors.green[50]?.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isRead ? Colors.grey[200]! : AppTheme.primaryGreen.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.info_outline, color: AppTheme.primaryGreen),
                  ),
                  title: Text(n['title'] ?? 'Aviso', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(n['message'] ?? ''),
                  trailing: !isRead 
                    ? const Icon(Icons.fiber_manual_record, color: AppTheme.primaryGreen, size: 12)
                    : null,
                  onTap: () {
                    // Marcar como leída al tocar
                    FirebaseFirestore.instance.collection('notifications').doc(docs[index].id).update({'read': true});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

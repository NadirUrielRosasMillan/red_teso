import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos simulados de notificaciones
    final List<Map<String, dynamic>> notifications = [
      {
        'titulo': '¡Empresa interesada!',
        'mensaje': 'Tech Solutions MX ha revisado tu perfil y te ha marcado como candidato destacado.',
        'fecha': 'Hace 10 min',
        'leida': false,
        'icono': Icons.star,
        'color': Colors.amber,
      },
      {
        'titulo': 'Vacante Aprobada',
        'mensaje': 'Tu publicación para "Desarrollador Java" ha sido validada por el administrador.',
        'fecha': 'Hace 2 horas',
        'leida': true,
        'icono': Icons.check_circle,
        'color': AppTheme.primaryGreen,
      },
      {
        'titulo': 'Nueva Postulación',
        'mensaje': 'Un alumno se ha postulado a tu vacante de "Residencias Profesionales".',
        'fecha': 'Ayer',
        'leida': true,
        'icono': Icons.person_add,
        'color': Colors.blue,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Marcar todo como leído'),
          )
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyNotifications()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: n['leida'] ? Colors.white : Colors.green[50]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: n['leida'] ? Colors.grey[200]! : AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: n['color'].withOpacity(0.1),
            child: Icon(n['icono'], color: n['color'], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      n['titulo'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: n['leida'] ? Colors.black87 : AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      n['fecha'],
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  n['mensaje'],
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          if (!n['leida'])
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Sin notificaciones por ahora',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

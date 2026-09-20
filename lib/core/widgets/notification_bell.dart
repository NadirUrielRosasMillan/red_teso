import 'package:flutter/material.dart';
import 'package:red_teso/features/notifications/presentation/pages/notifications_page.dart';

class NotificationBell extends StatelessWidget {
  final bool hasNotifications;
  final Color color;

  const NotificationBell({
    super.key,
    this.hasNotifications = true,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none_outlined, color: color),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsPage()),
            );
          },
        ),
        if (hasNotifications)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

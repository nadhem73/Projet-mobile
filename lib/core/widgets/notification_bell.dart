import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/navigation/app_routes.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';

/// Cloche avec le nombre de notifications non lues ; ouvre l'écran des notifications.
///
/// À placer dans une AppBar ou dans `PanelHeader.actions` (`onDark: true`).
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.onDark = false});

  /// true sur un fond coloré (icône blanche).
  final bool onDark;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _service = getIt<NotificationService>();
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final user = getIt<SessionService>().currentUser;
    if (user == null) return;
    final count = await _service.unreadCount(user.userId);
    if (mounted && count != _unread) setState(() => _unread = count);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _unread == 0 ? 'Notifications' : '$_unread notification(s) non lue(s)',
      onPressed: () async {
        await context.push(AppRoutes.notifications);
        _refresh();
      },
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text(_unread > 9 ? '9+' : '$_unread'),
        backgroundColor: AppColors.accent,
        child: Icon(
          _unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
          color: widget.onDark ? Colors.white : null,
        ),
      ),
    );
  }
}

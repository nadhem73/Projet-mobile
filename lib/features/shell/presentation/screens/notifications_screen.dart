import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';

/// Notifications de l'utilisateur connecté (tous les rôles).
/// Les notifications non lues sont mises en évidence puis marquées comme lues.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = getIt<NotificationService>();
  final int? _userId = getIt<SessionService>().currentUser?.userId;
  late Future<List<AppNotification>> _items = _load();

  Future<List<AppNotification>> _load() async {
    final userId = _userId;
    if (userId == null) return const [];
    final items = await _service.forUser(userId);
    // Affichées avec leur état « non lu », puis marquées lues pour la prochaine visite.
    if (items.any((n) => !n.isRead)) await _service.markAllRead(userId);
    return items;
  }

  static (IconData, Color) _style(String type) => switch (type) {
    NotificationTypes.appointment => (Icons.calendar_month_rounded, AppColors.moduleAppointment),
    NotificationTypes.prescription => (Icons.receipt_long_rounded, AppColors.moduleDoctor),
    NotificationTypes.insurance => (Icons.health_and_safety_rounded, AppColors.moduleInsurance),
    NotificationTypes.pharmacy => (Icons.local_pharmacy_rounded, AppColors.modulePharmacy),
    NotificationTypes.account => (Icons.manage_accounts_rounded, AppColors.primary),
    NotificationTypes.security => (Icons.lock_rounded, AppColors.error),
    NotificationTypes.medicalRecord => (Icons.folder_shared_rounded, AppColors.info),
    _ => (Icons.notifications_rounded, AppColors.accent),
  };

  String _when(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return DateFormat('d MMM yyyy', 'fr').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Aucune notification',
              message: 'Vous serez prévenu ici de vos rendez-vous, ordonnances et de l\'activité de votre compte.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final next = _load();
              setState(() => _items = next);
              await next;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final n = items[i];
                final (icon, color) = _style(n.type);
                return MediCard(
                  color: n.isRead ? null : color.withValues(alpha: 0.06),
                  borderColor: n.isRead ? null : color.withValues(alpha: 0.35),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(n.title, style: theme.textTheme.titleSmall)),
                                if (!n.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            if (n.body != null) ...[
                              const SizedBox(height: 2),
                              Text(n.body!, style: theme.textTheme.bodyMedium),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            Text(_when(n.createdAt), style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

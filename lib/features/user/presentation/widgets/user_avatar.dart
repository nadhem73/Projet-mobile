import 'package:flutter/material.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/widgets/display_widgets.dart';
import 'package:medilink/features/user/presentation/controllers/user_avatar_store.dart';

/// Photo de profil d'un utilisateur, ou ses initiales s'il n'en a pas.
/// Se met à jour automatiquement quand la photo change.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    required this.initials,
    this.size = 48,
    this.color,
    this.onDark = false,
  });

  final int userId;
  final String initials;
  final double size;
  final Color? color;

  /// true sur un fond coloré (initiales blanches sur cercle translucide).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final store = getIt<UserAvatarStore>();
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final bytes = store.peek(userId);
        if (bytes != null) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: onDark ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2) : null,
              image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
            ),
          );
        }
        if (onDark) {
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: size * 0.34),
            ),
          );
        }
        return MediAvatar(initials: initials, size: size, color: color);
      },
    );
  }
}

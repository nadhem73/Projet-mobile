import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';

/// Logo MediLink dessiné en code (s'adapte à la palette et au mode sombre).
class MediLogo extends StatelessWidget {
  const MediLogo({super.key, this.size = 72, this.showWordmark = false, this.onDark = false});

  final double size;
  final bool showWordmark;

  /// true si le logo est posé sur un fond sombre / coloré.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: onDark ? null : AppColors.brandGradient,
        color: onDark ? Colors.white.withValues(alpha: 0.14) : null,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: onDark ? Border.all(color: Colors.white.withValues(alpha: 0.3)) : null,
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );

    if (!showWordmark) return mark;

    final textColor = onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.22),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Medi', style: TextStyle(color: textColor)),
              TextSpan(text: 'Link', style: TextStyle(color: onDark ? AppColors.primarySoft : AppColors.primaryLight)),
            ],
          ),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: size * 0.42, letterSpacing: -0.5),
        ),
        Text(
          'TUNISIA',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textColor.withValues(alpha: 0.7),
            letterSpacing: 4,
            fontSize: size * 0.13,
          ),
        ),
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final unit = size.width;

    // Anneau de liaison (le « Link »)
    final ring =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * 0.045;
    canvas.drawCircle(c, unit * 0.3, ring);

    // Nœuds
    final node = Paint()..color = Colors.white;
    for (final o in [Offset(0, -unit * 0.3), Offset(unit * 0.3, 0), Offset(0, unit * 0.3), Offset(-unit * 0.3, 0)]) {
      canvas.drawCircle(c + o, unit * 0.055, node);
    }

    // Croix médicale
    final arm = unit * 0.13;
    final len = unit * 0.36;
    final cross = Paint()..color = Colors.white;
    final r = Radius.circular(arm * 0.35);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: arm, height: len), r), cross);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: len, height: arm), r), cross);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

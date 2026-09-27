import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/core/theme/medical_theme.dart';

/// 3D Animated Card Component
/// Features:
/// - 3D elevation with colored shadows
/// - Hover/tap animations with scale and elevation changes
/// - Glassmorphism variant
/// - Gradient backgrounds
/// - Ripple effects

class Medical3DCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final Color? color;
  final LinearGradient? gradient;
  final bool glassmorphism;
  final bool animateOnHover;
  final Duration animationDuration;
  final Curve animationCurve;
  final Widget? leading;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const Medical3DCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.elevation = 2,
    this.color,
    this.gradient,
    this.glassmorphism = false,
    this.animateOnHover = true,
    this.animationDuration = MedicalThemeData.shortDuration,
    this.animationCurve = MedicalThemeData.emphasizedCurve,
    this.leading,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  State<Medical3DCard> createState() => _Medical3DCardState();
}

class _Medical3DCardState extends State<Medical3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: widget.animationCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.animateOnHover) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.animateOnHover) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null && widget.animateOnHover) {
      _controller.reverse();
    }
  }

  void _onHover(bool hovered) {
    if (widget.onTap != null && widget.animateOnHover) {
      if (hovered) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget cardContent = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        margin: widget.margin,
        decoration: _buildDecoration(isDark),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onHover: _onHover,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: isDark
                ? medicalTealDarkPrimary.withValues(alpha: 0.1)
                : medicalTealPrimary.withValues(alpha: 0.1),
            highlightColor: isDark
                ? medicalTealDarkPrimary.withValues(alpha: 0.05)
                : medicalTealPrimary.withValues(alpha: 0.05),
            child: Padding(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: widget.crossAxisAlignment,
                mainAxisAlignment: widget.mainAxisAlignment,
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: widget.child),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 12),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: cardContent,
      );
    }

    return cardContent;
  }

  BoxDecoration _buildDecoration(bool isDark) {
    if (widget.glassmorphism) {
      return isDark
          ? MedicalThemeData.glassmorphismDark(
              borderRadius: widget.borderRadius,
            )
          : MedicalThemeData.glassmorphismLight(
              borderRadius: widget.borderRadius,
            );
    }

    if (widget.gradient != null) {
      return isDark
          ? MedicalThemeData.card3DDark(
              borderRadius: widget.borderRadius,
              gradient: widget.gradient,
            )
          : MedicalThemeData.card3DLight(
              borderRadius: widget.borderRadius,
              gradient: widget.gradient,
            );
    }

    return isDark
        ? MedicalThemeData.card3DDark(
            borderRadius: widget.borderRadius,
            color: widget.color,
            elevation: 2,
          )
        : MedicalThemeData.card3DLight(
            borderRadius: widget.borderRadius,
            color: widget.color,
            elevation: 2,
          );
  }
}

/// Animated Medical Button with 3D effects
class Medical3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final Color? foregroundColor;
  final double width;
  final double height;
  final bool isLoading;
  final Widget? loadingWidget;
  final bool glassmorphism;
  final bool animateOnHover;
  final Duration animationDuration;
  final Curve animationCurve;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final MainAxisAlignment mainAxisAlignment;

  const Medical3DButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.elevation = 2,
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.width = double.infinity,
    this.height = 56,
    this.isLoading = false,
    this.loadingWidget,
    this.glassmorphism = false,
    this.animateOnHover = true,
    this.animationDuration = MedicalThemeData.shortDuration,
    this.animationCurve = MedicalThemeData.emphasizedCurve,
    this.leadingIcon,
    this.trailingIcon,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  State<Medical3DButton> createState() => _Medical3DButtonState();
}

class _Medical3DButtonState extends State<Medical3DButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: widget.animationCurve),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.animationCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading && widget.animateOnHover) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading && widget.animateOnHover) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading && widget.animateOnHover) {
      _controller.reverse();
    }
  }

  void _onHover(bool hovered) {
    if (widget.onPressed != null && !widget.isLoading && widget.animateOnHover) {
      if (hovered) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveElevation = widget.elevation + _elevationAnimation.value;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Widget buttonContent = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: _buildDecoration(isDark, effectiveElevation),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onHover: _onHover,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: isDark
                ? medicalTealDarkPrimary.withValues(alpha: 0.1)
                : medicalTealPrimary.withValues(alpha: 0.1),
            highlightColor: isDark
                ? medicalTealDarkPrimary.withValues(alpha: 0.05)
                : medicalTealPrimary.withValues(alpha: 0.05),
            child: Container(
              padding: widget.padding,
              child: Row(
                mainAxisAlignment: widget.mainAxisAlignment,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.leadingIcon != null) ...[
                    Icon(
                      widget.leadingIcon,
                      color: widget.foregroundColor ??
                          (isDark ? medicalWhite : medicalWhite),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      color: widget.foregroundColor ??
                          (isDark ? medicalWhite : medicalWhite),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    child: widget.child,
                  ),
                  if (widget.trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      widget.trailingIcon,
                      color: widget.foregroundColor ??
                          (isDark ? medicalWhite : medicalWhite),
                      size: 20,
                    ),
                  ],
                  if (widget.isLoading) ...[
                    const SizedBox(width: 12),
                    widget.loadingWidget ??
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.foregroundColor ??
                                  (isDark ? medicalWhite : medicalWhite),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!isEnabled) {
      return Opacity(
        opacity: 0.6,
        child: MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: buttonContent,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: buttonContent,
    );
  }

  BoxDecoration _buildDecoration(bool isDark, double elevation) {
    if (widget.glassmorphism) {
      return isDark
          ? MedicalThemeData.glassmorphismDark(
              borderRadius: widget.borderRadius,
            )
          : MedicalThemeData.glassmorphismLight(
              borderRadius: widget.borderRadius,
            );
    }

    if (widget.gradient != null) {
      return isDark
          ? MedicalThemeData.card3DDark(
              borderRadius: widget.borderRadius,
              gradient: widget.gradient,
              elevation: elevation,
            )
          : MedicalThemeData.card3DLight(
              borderRadius: widget.borderRadius,
              gradient: widget.gradient,
              elevation: elevation,
            );
    }

    final bgColor = widget.backgroundColor ??
        (isDark ? medicalTealDarkPrimary : medicalTealPrimary);

    return isDark
        ? MedicalThemeData.card3DDark(
            borderRadius: widget.borderRadius,
            color: bgColor,
            elevation: elevation,
          )
        : MedicalThemeData.card3DLight(
            borderRadius: widget.borderRadius,
            color: bgColor,
            elevation: elevation,
          );
  }
}

/// Breathing Animation Widget for medical pulse effect
class MedicalBreathingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color lightColor;
  final Color darkColor;
  final double borderRadius;
  final bool repeat;

  const MedicalBreathingWidget({
    super.key,
    required this.child,
    this.duration = MedicalThemeData.breathingDuration,
    this.lightColor = medicalTealUltraLight,
    this.darkColor = medicalDarkSurface,
    this.borderRadius = 20,
    this.repeat = true,
  });

  @override
  State<MedicalBreathingWidget> createState() => _MedicalBreathingWidgetState();
}

class _MedicalBreathingWidgetState extends State<MedicalBreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return AnimatedContainer(
          duration: widget.duration,
          curve: MedicalThemeData.breathingCurve,
          decoration: isDark
              ? MedicalThemeData.breathingDark(
                  borderRadius: widget.borderRadius,
                  animation: _controller,
                )
              : MedicalThemeData.breathingLight(
                  borderRadius: widget.borderRadius,
                  animation: _controller,
                ),
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse Animation Widget for medical pulse effect
class MedicalPulseWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color color;
  final bool repeat;

  const MedicalPulseWidget({
    super.key,
    required this.child,
    this.duration = MedicalThemeData.pulseDuration,
    this.color = medicalTealPrimary,
    this.repeat = true,
  });

  @override
  State<MedicalPulseWidget> createState() => _MedicalPulseWidgetState();
}

class _MedicalPulseWidgetState extends State<MedicalPulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: isDark
              ? MedicalThemeData.pulseDark(
                  animation: _controller,
                  baseColor: widget.color,
                )
              : MedicalThemeData.pulseLight(
                  animation: _controller,
                  baseColor: widget.color,
                ),
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer Loading Widget
class MedicalShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Duration duration;
  final bool isDark;

  const MedicalShimmerWidget({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 12,
    this.duration = const Duration(milliseconds: 1500),
    this.isDark = false,
  });

  @override
  State<MedicalShimmerWidget> createState() => _MedicalShimmerWidgetState();
}

class _MedicalShimmerWidgetState extends State<MedicalShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
              colors: widget.isDark
                  ? [
                      Color(0xFF383838),
                      Color(0xFF424242),
                      Color(0xFF383838),
                    ]
                  : [
                      Color(0xFFE0E0E0),
                      Color(0xFFF5F5F5),
                      Color(0xFFE0E0E0),
                    ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 3D Page Transition Builder
class Medical3DPageTransitionBuilder extends PageTransitionsBuilder {
  const Medical3DPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final tween = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: MedicalThemeData.medicalCurve));

    final scaleTween = Tween<double>(begin: 0.95, end: 1.0).chain(
      CurveTween(curve: MedicalThemeData.emphasizedCurve),
    );

    final rotationTween = Tween<double>(begin: 0.02, end: 0.0).chain(
      CurveTween(curve: MedicalThemeData.deceleratedCurve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: ScaleTransition(
        scale: animation.drive(scaleTween),
        child: RotationTransition(
          turns: animation.drive(rotationTween),
          child: child,
        ),
      ),
    );
  }
}

/// 3D Flip Transition
class Medical3DFlipTransition extends PageTransitionsBuilder {
  const Medical3DFlipTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final angle = animation.value * 3.14159 / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Morphing Shape Transition
class MedicalMorphingTransition extends PageTransitionsBuilder {
  const MedicalMorphingTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final borderRadius = BorderRadius.circular(
          30 * (1 - animation.value),
        );

        return ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? medicalPrimaryDarkGradient
                  : medicalPrimaryGradient,
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Staggered Animation List
class MedicalStaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDuration;
  final Curve curve;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const MedicalStaggeredList({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 400),
    this.staggerDuration = const Duration(milliseconds: 100),
    this.curve = MedicalThemeData.emphasizedCurve,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return MedicalStaggeredItem(
          index: index,
          itemDuration: itemDuration,
          staggerDuration: staggerDuration,
          curve: curve,
          child: children[index],
        );
      },
    );
  }
}

class MedicalStaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration itemDuration;
  final Duration staggerDuration;
  final Curve curve;

  const MedicalStaggeredItem({
    super.key,
    required this.child,
    required this.index,
    required this.itemDuration,
    required this.staggerDuration,
    required this.curve,
  });

  @override
  State<MedicalStaggeredItem> createState() => _MedicalStaggeredItemState();
}

class _MedicalStaggeredItemState extends State<MedicalStaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.itemDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (widget.index * widget.staggerDuration.inMilliseconds /
                  widget.itemDuration.inMilliseconds)
              .clamp(0.0, 1.0),
          1.0,
          curve: widget.curve,
        ),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (widget.index * widget.staggerDuration.inMilliseconds /
                  widget.itemDuration.inMilliseconds)
              .clamp(0.0, 1.0),
          1.0,
          curve: widget.curve,
        ),
      ),
    );

    Future.delayed(
      Duration(milliseconds: widget.index * widget.staggerDuration.inMilliseconds),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Floating Action Button with 3D effect
class Medical3DFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool extended;
  final String? label;
  final IconData? icon;

  const Medical3DFAB({
    super.key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56,
    this.extended = false,
    this.label,
    this.icon,
  });

  @override
  State<Medical3DFAB> createState() => _Medical3DFABState();
}

class _Medical3DFABState extends State<Medical3DFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: MedicalThemeData.shortDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _controller.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _controller.reverse();
        },
        child: FloatingActionButton(
          onPressed: widget.onPressed,
          backgroundColor: widget.backgroundColor ?? medicalTealPrimary,
          foregroundColor: widget.foregroundColor ?? medicalWhite,
          elevation: _isHovered ? 12 : 8,
          focusElevation: 12,
          hoverElevation: 12,
          highlightElevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
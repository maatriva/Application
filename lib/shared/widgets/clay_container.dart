import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';

/// Reusable soft claymorphic card container supporting soft outer shadows,
/// subtle inner highlight gradients, customizable rounded corners (22-32px),
/// and gentle press animation feedback.
class ClayContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Color color;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  final Border? border;
  final double? width;
  final double? height;

  const ClayContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.color = Colors.white,
    this.gradient,
    this.padding,
    this.margin,
    this.onTap,
    this.shadows,
    this.border,
    this.width,
    this.height,
  });

  @override
  State<ClayContainer> createState() => _ClayContainerState();
}

class _ClayContainerState extends State<ClayContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveShadows = widget.shadows ?? AppColors.clayShadow;
    final effectiveBorder = widget.border ??
        Border.all(
          color: AppColors.softTeal.withValues(alpha: 0.35),
          width: 1.2,
        );

    final cardChild = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.onTap != null ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: widget.gradient == null ? widget.color : null,
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: effectiveBorder,
          boxShadow: effectiveShadows,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) {
      return cardChild;
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: cardChild,
    );
  }
}

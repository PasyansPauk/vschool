import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable Apple-style bouncing card widget.
/// Provides an immediate tactile press-down indentation effect (scale 0.96)
/// with haptic feedback, and provides the card's screen Rect upon release.
class ProMotionBouncingCard extends StatefulWidget {
  final Widget child;
  final void Function(BuildContext context, Rect sourceRect) onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;
  final BorderRadius? borderRadius;

  const ProMotionBouncingCard({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.pressedScale = 0.965,
    this.duration = const Duration(milliseconds: 110),
    this.borderRadius,
  });

  @override
  State<ProMotionBouncingCard> createState() => _ProMotionBouncingCardState();
}

class _ProMotionBouncingCardState extends State<ProMotionBouncingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Rect _getCurrentRect() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final origin = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        origin.dx,
        origin.dy,
        renderBox.size.width,
        renderBox.size.height,
      );
    }
    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(20, size.height / 2 - 100, size.width - 40, 200);
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isPressed) {
      _isPressed = true;
      HapticFeedback.lightImpact();
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
      final rect = _getCurrentRect();
      widget.onTap(context, rect);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              widget.onLongPress!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

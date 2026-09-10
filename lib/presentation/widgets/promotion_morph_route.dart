import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Helper widget to measure intrinsic child size dynamically
typedef OnWidgetSizeChange = void Function(Size size);

class _MeasureSizeRenderObject extends RenderProxyBox {
  Size? oldSize;
  OnWidgetSizeChange onChange;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (oldSize != newSize) {
      oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final OnWidgetSizeChange onChange;

  const _MeasureSize({
    required this.onChange,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _MeasureSizeRenderObject renderObject) {
    renderObject.onChange = onChange;
  }
}

/// Helper function to present a floating Apple ProMotion morphing modal.
/// - The modal smoothly expands directly from [sourceRect] ("овал" кнопки)
///   into an auto-sized Liquid Glass floating card fitted to the content.
/// - Cross-fades seamlessly with [collapsedChild] (the preview card) so
///   text and icons never appear or disappear abruptly.
/// - Smoothly collapses back into [sourceRect] when dismissed.
Future<T?> showProMotionCardModal<T>({
  required BuildContext context,
  required Rect sourceRect,
  double sourceRadius = 22.0,
  double targetRadius = 30.0,
  required bool isDark,
  Widget? collapsedChild,
  required Widget Function(BuildContext context, ScrollController scrollController) builder,
}) {
  return Navigator.of(context).push<T>(
    ProMotionMorphRoute<T>(
      sourceRect: sourceRect,
      sourceRadius: sourceRadius,
      targetRadius: targetRadius,
      isDark: isDark,
      collapsedChild: collapsedChild,
      builder: builder,
    ),
  );
}

class ProMotionMorphRoute<T> extends PageRoute<T> {
  final Rect sourceRect;
  final double sourceRadius;
  final double targetRadius;
  final bool isDark;
  final Widget? collapsedChild;
  final Widget Function(BuildContext context, ScrollController scrollController) builder;

  ProMotionMorphRoute({
    required this.sourceRect,
    this.sourceRadius = 22.0,
    this.targetRadius = 30.0,
    required this.isDark,
    this.collapsedChild,
    required this.builder,
    super.settings,
  });

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Закрыть карточку';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 360);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ProMotionMorphDialog<T>(
      route: this,
      animation: animation,
      sourceRect: sourceRect,
      sourceRadius: sourceRadius,
      targetRadius: targetRadius,
      isDark: isDark,
      collapsedChild: collapsedChild,
      builder: builder,
    );
  }
}

class _ProMotionMorphDialog<T> extends StatefulWidget {
  final ProMotionMorphRoute<T> route;
  final Animation<double> animation;
  final Rect sourceRect;
  final double sourceRadius;
  final double targetRadius;
  final bool isDark;
  final Widget? collapsedChild;
  final Widget Function(BuildContext context, ScrollController scrollController) builder;

  const _ProMotionMorphDialog({
    required this.route,
    required this.animation,
    required this.sourceRect,
    required this.sourceRadius,
    required this.targetRadius,
    required this.isDark,
    this.collapsedChild,
    required this.builder,
  });

  @override
  State<_ProMotionMorphDialog<T>> createState() => _ProMotionMorphDialogState<T>();
}

class _ProMotionMorphDialogState<T> extends State<_ProMotionMorphDialog<T>> {
  final ScrollController _scrollController = ScrollController();
  double? _measuredContentHeight;
  double _dragOffsetY = 0.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _dismiss() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  Rect _computeTargetRect(
    Size screenSize,
    EdgeInsets padding,
    double targetWidth,
    double availableHeight,
  ) {
    // Height adapts dynamically to content with zero empty space
    final double contentH = _measuredContentHeight ?? 280.0;
    final double targetHeight = contentH.clamp(100.0, availableHeight);

    final double left = (screenSize.width - targetWidth) / 2.0;
    final double top = padding.top + 20.0 + ((availableHeight - targetHeight) / 2.0);

    return Rect.fromLTWH(left, top, targetWidth, targetHeight);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final padding = media.padding;
    const double horizontalMargin = 18.0;
    // Constant width: pleasantly wide with comfortable screen margins
    final double targetWidth = min(screenSize.width - (horizontalMargin * 2), 364.0);
    final double availableHeight = screenSize.height - padding.top - padding.bottom - 40.0;

    final targetRect = _computeTargetRect(screenSize, padding, targetWidth, availableHeight);

    // Apple ProMotion ease curves: rapid responsive start, ultra-smooth cubic deceleration
    final curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: const Cubic(0.2, 0.9, 0.25, 1.0),
      reverseCurve: const Cubic(0.35, 0.0, 0.8, 0.15),
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          HapticFeedback.selectionClick();
        }
      },
      child: AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, _) {
          final t = curvedAnimation.value;

          // Interpolated geometry from source button rect to auto-sized target modal rect
          final currentRect = Rect.lerp(widget.sourceRect, targetRect, t)!;
          final currentRadius = lerpDouble(widget.sourceRadius, widget.targetRadius, t)!;

          // Backdrop scrim & blur
          final scrimOpacity = (0.58 * t).clamp(0.0, 1.0);
          final blurSigma = (26.0 * t).clamp(0.01, 26.0);

          final double containerOpacity = (t / 0.35).clamp(0.0, 1.0);
          final double borderOpacity = (t / 0.25).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Offstage Measurer: computes exact pixel height at the constant card width
              Positioned(
                top: 0,
                left: 0,
                width: targetWidth,
                child: Offstage(
                  offstage: true,
                  child: SizedBox(
                    width: targetWidth,
                    child: _MeasureSize(
                      onChange: (size) {
                        if (mounted &&
                            size.height > 40 &&
                            (_measuredContentHeight == null ||
                                (_measuredContentHeight! - size.height).abs() > 1)) {
                          setState(() {
                            _measuredContentHeight = size.height;
                          });
                        }
                      },
                      child: Material(
                        type: MaterialType.transparency,
                        child: widget.builder(context, ScrollController()),
                      ),
                    ),
                  ),
                ),
              ),

              // 1. Blurred Backdrop with tap-to-dismiss
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: Container(
                    color: CupertinoColors.black.withValues(alpha: scrimOpacity),
                  ),
                ),
              ),

              // 2. The Morphing Card itself ("овал") with smooth fade
              Positioned(
                left: currentRect.left,
                top: currentRect.top + _dragOffsetY,
                width: currentRect.width,
                height: currentRect.height,
                child: GestureDetector(
                  // Intercept taps inside card so background tap doesn't dismiss
                  onTap: () {},
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null && details.primaryDelta! > 0) {
                      setState(() {
                        _dragOffsetY = max(0.0, _dragOffsetY + details.primaryDelta!);
                      });
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (_dragOffsetY > 90.0 || (details.primaryVelocity ?? 0) > 400.0) {
                      _dismiss();
                    } else {
                      setState(() {
                        _dragOffsetY = 0.0;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(currentRadius),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: 0.35 * t * containerOpacity),
                          blurRadius: 32 * t,
                          spreadRadius: 1 * t,
                          offset: Offset(0, 12 * t),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(currentRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 30 * containerOpacity,
                          sigmaY: 30 * containerOpacity,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? const Color(0xDC1E1E22).withValues(alpha: 0.86 * containerOpacity)
                                : const Color(0xF2FFFFFF).withValues(alpha: 0.95 * containerOpacity),
                            borderRadius: BorderRadius.circular(currentRadius),
                            border: Border.all(
                              color: widget.isDark
                                  ? const Color(0x38FFFFFF).withValues(alpha: 0.22 * borderOpacity)
                                  : const Color(0x20000000).withValues(alpha: 0.12 * borderOpacity),
                              width: 0.8,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Collapsed Child (Preview): Fades out smoothly on expand,
                              // fades IN smoothly on collapse so card text never abruptly pops in!
                              if (widget.collapsedChild != null && t < 0.6)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: ((0.55 - t) / 0.55).clamp(0.0, 1.0),
                                    child: IgnorePointer(
                                      child: widget.collapsedChild!,
                                    ),
                                  ),
                                ),

                              // Expanded Full Content: Fades in smoothly as container grows
                              if (t > 0.15)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: ((t - 0.15) / 0.85).clamp(0.0, 1.0),
                                    child: _measuredContentHeight != null &&
                                            _measuredContentHeight! > availableHeight
                                        ? SingleChildScrollView(
                                            controller: _scrollController,
                                            physics: const BouncingScrollPhysics(),
                                            child: widget.builder(context, _scrollController),
                                          )
                                        : widget.builder(context, _scrollController),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

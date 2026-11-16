import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';

/// Interactive high-conversion Slide-to-Pay confirmation slider widget.
/// Features shimmering chevrons, gradient progress follow, spring return animation,
/// and smooth loading/completion state transitions.
class SlideToPayWidget extends StatefulWidget {
  final double totalAmount;
  final VoidCallback onConfirmed;
  final bool isLoading;
  final bool isCompleted;
  final bool enabled;
  final String? customLabel;

  const SlideToPayWidget({
    super.key,
    required this.totalAmount,
    required this.onConfirmed,
    this.isLoading = false,
    this.isCompleted = false,
    this.enabled = true,
    this.customLabel,
  });

  @override
  State<SlideToPayWidget> createState() => _SlideToPayWidgetState();
}

class _SlideToPayWidgetState extends State<SlideToPayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _resetController;
  Animation<double>? _resetAnimation;
  double _dragPosition = 0.0;
  bool _hasTriggered = false;

  static const double _height = 56.0;
  static const double _thumbSize = 48.0;
  static const double _padding = 4.0;
  static const double _threshold = 0.85;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        if (_resetAnimation != null) {
          setState(() {
            _dragPosition = _resetAnimation!.value;
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant SlideToPayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading && !widget.isCompleted) {
      _snapBack(0.0);
    }
    if (!widget.isCompleted && oldWidget.isCompleted) {
      _snapBack(0.0);
    }
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _snapBack(double maxDragDistance) {
    _hasTriggered = false;
    _resetAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetController.forward(from: 0.0);
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDragDistance) {
    if (!widget.enabled || widget.isLoading || widget.isCompleted || _hasTriggered) {
      return;
    }

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDragDistance);
      final progress = maxDragDistance > 0 ? _dragPosition / maxDragDistance : 0.0;

      if (progress >= _threshold && !_hasTriggered) {
        _hasTriggered = true;
        _dragPosition = maxDragDistance;
        widget.onConfirmed();
      }
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDragDistance) {
    if (!widget.enabled || widget.isLoading || widget.isCompleted) {
      return;
    }

    final progress = maxDragDistance > 0 ? _dragPosition / maxDragDistance : 0.0;
    if (progress < _threshold) {
      _snapBack(maxDragDistance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = widget.customLabel ??
        'SLIDE TO CONFIRM ORDER (\$${widget.totalAmount.toStringAsFixed(2)})';

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDragDistance =
            (totalWidth - _thumbSize - (_padding * 2)).clamp(0.0, double.infinity);
        final progress =
            maxDragDistance > 0 ? (_dragPosition / maxDragDistance).clamp(0.0, 1.0) : 0.0;

        return Container(
          key: const Key('slide_to_pay_track'),
          width: totalWidth,
          height: _height,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(_height / 2),
            border: Border.all(
              color: widget.isCompleted
                  ? AppColors.emerald
                  : colors.cardBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.4 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Dynamic Fill Gradient following thumb
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: (_dragPosition + _thumbSize + _padding).clamp(0.0, totalWidth),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_height / 2),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: widget.isCompleted
                          ? [AppColors.emerald, const Color(0xFF059669)]
                          : [
                              AppColors.electricCobalt.withValues(alpha: 0.7),
                              AppColors.electricCobalt,
                            ],
                    ),
                  ),
                ),
              ),

              // Shimmering Chevrons and Centered Label
              Center(
                child: Opacity(
                  opacity: (1.0 - (progress * 1.4)).clamp(0.0, 1.0),
                  child: Shimmer.fromColors(
                    baseColor: colors.textSecondary,
                    highlightColor: Colors.white,
                    period: const Duration(milliseconds: 1800),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '››› ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            label,
                            key: const Key('slide_to_pay_label'),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const Text(
                          ' ›››',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Interactive Draggable Slider Thumb
              Positioned(
                left: _padding + _dragPosition,
                top: _padding,
                child: GestureDetector(
                  key: const Key('slide_to_pay_thumb'),
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, maxDragDistance),
                  onHorizontalDragEnd: (details) =>
                      _onDragEnd(details, maxDragDistance),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.isCompleted
                          ? const LinearGradient(
                              colors: [AppColors.emerald, Color(0xFF059669)],
                            )
                          : AppColors.cobaltGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isCompleted
                                  ? AppColors.emerald
                                  : AppColors.electricCobalt)
                              .withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : widget.isCompleted
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 26,
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

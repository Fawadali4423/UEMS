import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uems/app/theme.dart';

/// An animated gradient button with ripple effects
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;
  final bool outlined;
  final List<Color>? gradientColors;

  const AnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.icon,
    this.outlined = false,
    this.gradientColors,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ?? [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
    ];

    if (widget.outlined) {
      return _buildOutlinedButton(context, colors);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width ?? double.infinity,
        height: widget.height,
        transform: Matrix4.diagonal3Values(_isPressed ? 0.95 : 1.0, _isPressed ? 0.95 : 1.0, 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.onPressed == null 
              ? [Colors.grey, Colors.grey.shade600]
              : colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed 
            ? []
            : [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Center(
              child: widget.isLoading 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    ).animate(target: _isPressed ? 1 : 0)
      .scaleXY(end: 0.95, duration: 100.ms);
  }

  Widget _buildOutlinedButton(BuildContext context, List<Color> colors) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width ?? double.infinity,
        height: widget.height,
        transform: Matrix4.diagonal3Values(_isPressed ? 0.95 : 1.0, _isPressed ? 0.95 : 1.0, 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors[0],
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Center(
              child: widget.isLoading 
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: colors[0],
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: colors[0],
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: colors[0],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

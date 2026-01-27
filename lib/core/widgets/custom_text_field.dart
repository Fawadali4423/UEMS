import 'package:flutter/material.dart';
import 'package:uems/app/theme.dart';

/// Custom text field with modern styling
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused 
          ? [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
      ),
      child: Focus(
        onFocusChange: (focused) {
          setState(() => _isFocused = focused);
        },
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          textCapitalization: widget.textCapitalization,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey[900],
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null 
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused 
                    ? AppTheme.primaryColor 
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                )
              : null,
            suffixIcon: widget.suffixIcon,
            labelStyle: TextStyle(
              color: _isFocused 
                ? AppTheme.primaryColor 
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            filled: true,
            fillColor: isDark 
              ? const Color(0xFF2D2D44) 
              : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark 
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }
}

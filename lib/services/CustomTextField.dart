import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final int maxLines;
  final Color? primaryColor; // Optional color for driver app (orange)

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.maxLines = 1,
    this.primaryColor, // Default to teal/green if not provided
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color textFieldColor = widget.primaryColor ?? theme.primaryColor;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color fieldFill =
        theme.inputDecorationTheme.fillColor ??
        (isDark ? const Color(0xFF203238) : const Color(0xFFF0FAFB));
    final Color hintColor =
        theme.textTheme.bodySmall?.color ?? onSurface.withOpacity(0.7);
    final Color outlineColor = _isFocused
        ? textFieldColor
        : textFieldColor.withOpacity(isDark ? 0.55 : 0.42);
    final Color shadowColor = isDark
        ? Colors.black.withOpacity(0.32)
        : Colors.black.withOpacity(0.14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.trim().isNotEmpty) ...[
          Text(
            widget.label,
            style: TextStyle(
              color: textFieldColor,
              fontSize: 15.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          constraints: BoxConstraints(minHeight: widget.maxLines > 1 ? 92 : 56),
          decoration: BoxDecoration(
            color: fieldFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: outlineColor,
              width: _isFocused ? 1.8 : 1.35,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: textFieldColor.withOpacity(isDark ? 0.28 : 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Focus(
            onFocusChange: (hasFocus) {
              setState(() => _isFocused = hasFocus);
            },
            child: TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              obscureText: widget.isPassword ? _obscureText : false,
              validator: widget.validator,
              maxLines: widget.maxLines,
              style: TextStyle(color: onSurface, fontSize: 15),
              decoration: InputDecoration(
                hintText: widget.hint,
                isDense: false,
                filled: false,
                hintStyle: TextStyle(
                  color: hintColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  widget.prefixIcon,
                  color: _isFocused
                      ? textFieldColor
                      : textFieldColor.withOpacity(isDark ? 0.8 : 0.65),
                  size: 22,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _isFocused
                              ? textFieldColor
                              : textFieldColor.withOpacity(isDark ? 0.8 : 0.65),
                          size: 21,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 17,
                ),
                errorStyle: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

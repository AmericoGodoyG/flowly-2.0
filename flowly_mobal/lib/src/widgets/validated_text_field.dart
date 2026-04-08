import 'package:flutter/material.dart';
import 'package:meu_app/src/app/flowly_theme.dart';

class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final String? Function(String?)? onChanged;
  final VoidCallback? onSuffixIconPressed;

  const ValidatedTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.onChanged,
    this.onSuffixIconPressed,
    super.key,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  String? _errorMessage;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateOnChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateOnChange);
    super.dispose();
  }

  void _validateOnChange() {
    if (_isFocused) {
      setState(() {
        _errorMessage =
            widget.validator?.call(widget.controller.text) ??
            widget.onChanged?.call(widget.controller.text);
      });
    }
  }

  void _validateOnSubmit() {
    setState(() {
      _errorMessage =
          widget.validator?.call(widget.controller.text) ??
          widget.onChanged?.call(widget.controller.text);
    });
  }

  bool get isValid =>
      _errorMessage == null && widget.controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isFocused = hasFocus);
            if (!hasFocus) {
              _validateOnSubmit();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0x1AFFFFFF),
              border: Border.all(
                color: _errorMessage != null
                    ? Colors.red.shade300.withValues(alpha: 0.5)
                    : _isFocused
                    ? flowlyPrimary.withValues(alpha: 0.8)
                    : flowlyBorder,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: flowlyPrimary.withValues(alpha: 0.22),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, color: flowlyMutedText)
                    : null,
                suffixIcon: widget.suffixIcon != null
                    ? IconButton(
                        icon: Icon(widget.suffixIcon),
                        color: flowlyMutedText,
                        onPressed: widget.onSuffixIconPressed,
                      )
                    : (isValid && widget.controller.text.isNotEmpty)
                    ? Icon(Icons.check_circle, color: Colors.green.shade600)
                    : null,
                errorText: _errorMessage,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

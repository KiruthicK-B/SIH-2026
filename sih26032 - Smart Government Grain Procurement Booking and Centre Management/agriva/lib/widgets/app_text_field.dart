import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? errorText;
  final String? suffixText;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool obscureText;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.suffixText,
    this.prefix,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          obscureText: obscureText,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixText: suffixText,
            prefix: prefix,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            counterText: '',
          ),
        ),
      ],
    );
  }
}

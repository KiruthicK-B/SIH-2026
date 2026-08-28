import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? errorText;
  final String? suffixText;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.suffixText,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixText: suffixText,
          ),
        ),
      ],
    );
  }
}

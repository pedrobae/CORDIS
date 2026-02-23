import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? instruction;
  final bool isMultiline;
  final bool isEnabled;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const LabeledTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.instruction,
    this.isMultiline = false,
    this.isEnabled = true,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(label, style: textTheme.labelLarge),
          TextFormField(
            validator: validator,
            controller: controller,
            decoration: InputDecoration(
              fillColor: isEnabled
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest,
              hintText: hint,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.shadow),
                borderRadius: BorderRadius.circular(0),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.surfaceContainer),
                borderRadius: BorderRadius.circular(0),
              ),
              visualDensity: VisualDensity.compact,
            ),
            maxLines: isMultiline ? null : 1,

            keyboardType: isMultiline
                ? TextInputType.multiline
                : TextInputType.text,
            enabled: isEnabled,
            obscureText: obscureText,
          ),
          if (instruction != null)
            Text(
              instruction!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.surfaceContainerLow,
              ),
            ),
        ],
      ),
    );
  }
}

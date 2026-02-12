import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? instruction;
  final bool isMultiline;
  final bool isEnabled;

  const LabeledTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.instruction,
    this.isMultiline = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        TextFormField(
          validator: validator,
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.surfaceContainerLowest),
              borderRadius: BorderRadius.circular(0),
            ),
            visualDensity: VisualDensity.compact,
          ),
          maxLines: isMultiline ? null : 1,
          keyboardType: isMultiline
              ? TextInputType.multiline
              : TextInputType.text,
          enabled: isEnabled,
        ),
        if (instruction != null)
          Text(
            instruction!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.surfaceContainerLow,
            ),
          ),
      ],
    );
  }
}

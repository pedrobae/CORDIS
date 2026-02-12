import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool isMultiline;
  final bool isEnabled;

  const LabeledTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.isMultiline = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        TextFormField(
          validator: validator,
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              borderRadius: BorderRadius.circular(0),
            ),
            visualDensity: VisualDensity.compact,
          ),
          maxLines: isMultiline ? null : 1,
          enabled: isEnabled,
        ),
      ],
    );
  }
}

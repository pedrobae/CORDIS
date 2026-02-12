import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
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
            hintText: label,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              borderRadius: BorderRadius.circular(0),
            ),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

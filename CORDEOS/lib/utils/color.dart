import 'package:flutter/material.dart';

Color colorFromHex(String? hexColor) {
    // If null, use default gray
    final hex = (hexColor ?? '#808080').replaceFirst('#', '');

    // If only 6 characters, add FF for full opacity
    final hexValue = hex.length == 6 ? 'FF$hex' : hex;
    return Color(int.parse(hexValue, radix: 16));
  }

String colorToHex(Color? color) {
  if (color == null) {
    return '#808080';
  }
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
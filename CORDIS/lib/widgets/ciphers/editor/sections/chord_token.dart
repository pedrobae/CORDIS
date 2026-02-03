import 'package:cordis/models/ui/content_token.dart';
import 'package:flutter/material.dart';

class ChordToken extends StatelessWidget {
  final ContentToken token;
  final Color sectionColor;
  final TextStyle textStyle;

  const ChordToken({
    super.key,
    required this.token,
    required this.sectionColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 21,
      decoration: BoxDecoration(
        color: sectionColor,
        borderRadius: BorderRadius.circular(10.5),
      ),
      child: Center(
        child: Text(
          token.text,
          textAlign: TextAlign.center,
          style: textStyle.copyWith(
            fontSize: textStyle.fontSize! * 0.8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class ContentToken {
  String text;
  final TokenType type;
  int? position;

  ContentToken({required this.text, required this.type, this.position});
}

enum TokenType {
  chord, // [Am], [F#m7]
  lyric, // Regular character
  space, // Whitespace
  newline, // Line break
  precedingChordTarget, // Token that exists when editing
}

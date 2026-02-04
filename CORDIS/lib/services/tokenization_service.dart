import 'package:cordis/models/ui/content_token.dart';

class TokenizationService {
  /// Tokenizes the given content string into a list of ContentTokens.
  /// Creates preceding chord target tokens in lines where there are no spaces before lyrics.
  List<ContentToken> tokenize(String content) {
    if (content.isEmpty) {
      return [];
    }

    final List<ContentToken> tokens = [];
    final List<ContentToken> lineTokens = [];
    bool spaceBeforeLyrics = false;
    bool foundLyricInLine = false;
    for (int index = 0; index < content.length; index++) {
      final char = content[index];
      if (char == '\n') {
        if (lineTokens.isEmpty) {
          // Handle empty lines
          tokens.add(ContentToken(type: TokenType.newline, text: char));
          continue;
        }
        lineTokens.add(ContentToken(type: TokenType.newline, text: char));
        if (!spaceBeforeLyrics) {
          // Insert preceding chord target tokens at the starts of lines
          lineTokens.insert(
            0,
            ContentToken(type: TokenType.precedingChordTarget, text: ''),
          );
        }

        // Add Line and Reset for the next line
        spaceBeforeLyrics = false;
        foundLyricInLine = false;
        tokens.addAll(lineTokens);
        lineTokens.clear();
      } else if (char == ' ' || char == '\t') {
        if (!foundLyricInLine) {
          spaceBeforeLyrics = true;
        }
        lineTokens.add(ContentToken(type: TokenType.space, text: char));
      } else if (char == '[') {
        index++; // Move past the '['
        String chordText = '';
        while (index < content.length && content[index] != ']') {
          chordText += content[index];
          index++;
        }
        lineTokens.add(ContentToken(type: TokenType.chord, text: chordText));
      } else {
        foundLyricInLine = true;
        lineTokens.add(ContentToken(type: TokenType.lyric, text: char));
      }
    }
    if (tokens.isNotEmpty && tokens.last.type == TokenType.newline) {
      tokens.removeLast();
    }

    if (lineTokens.isNotEmpty) {
      tokens.addAll(lineTokens);
    }
    return tokens;
  }

  String reconstructContent(List<ContentToken> tokens) {
    return tokens.map((token) {
      switch (token.type) {
        case TokenType.chord:
          return '[${token.text}]';
        case TokenType.lyric:
        case TokenType.space:
        case TokenType.newline:
          return token.text;
        case TokenType.precedingChordTarget:
          return ''; // Preceding chord targets are not represented in the content string
      }
    }).join();
  }
}

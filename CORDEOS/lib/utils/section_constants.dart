import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

enum SectionLabelType {
  verse,
  chorus,
  bridge,
  intro,
  outro,
  solo,
  preChorus,
  tag,
  finale,
  annotations,
  unknown,
}

extension SectionLabelTypeX on SectionLabelType {
  String get canonicalLabel {
    switch (this) {
      case SectionLabelType.verse:
        return 'Verse';
      case SectionLabelType.chorus:
        return 'Chorus';
      case SectionLabelType.bridge:
        return 'Bridge';
      case SectionLabelType.intro:
        return 'Intro';
      case SectionLabelType.outro:
        return 'Outro';
      case SectionLabelType.solo:
        return 'Solo';
      case SectionLabelType.preChorus:
        return 'Pre-Chorus';
      case SectionLabelType.tag:
        return 'Tag';
      case SectionLabelType.finale:
        return 'Finale';
      case SectionLabelType.annotations:
        return 'Annotations';
      case SectionLabelType.unknown:
        return 'Unlabeled Section';
    }
  }

  Color get color {
    switch (this) {
      case SectionLabelType.verse:
        return Color(0xFF2196F3);
      case SectionLabelType.chorus:
        return Color(0xFFF44336);
      case SectionLabelType.bridge:
        return Colors.green;
      case SectionLabelType.intro:
        return Color(0xFF9C27B0);
      case SectionLabelType.outro:
        return Colors.brown;
      case SectionLabelType.solo:
        return Colors.amber;
      case SectionLabelType.preChorus:
        return Colors.orange;
      case SectionLabelType.tag:
        return Colors.teal;
      case SectionLabelType.finale:
        return Color(0xFF3F51B5);
      case SectionLabelType.annotations:
        return Colors.grey;
      case SectionLabelType.unknown:
        return Colors.grey;
    }
  }

  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SectionLabelType.verse:
        return l10n.sectionVerse;
      case SectionLabelType.chorus:
        return l10n.sectionChorus;
      case SectionLabelType.bridge:
        return l10n.sectionBridge;
      case SectionLabelType.intro:
        return l10n.sectionIntro;
      case SectionLabelType.outro:
        return l10n.sectionOutro;
      case SectionLabelType.solo:
        return l10n.sectionSolo;
      case SectionLabelType.preChorus:
        return l10n.sectionPreChorus;
      case SectionLabelType.tag:
        return l10n.sectionTag;
      case SectionLabelType.finale:
        return l10n.sectionFinale;
      case SectionLabelType.annotations:
        return l10n.sectionAnnotations;
      case SectionLabelType.unknown:
        return l10n.sectionUnlabeled;
    }
  }
}

Map<Color, String> sectionCodes = {
  Color(0xFF2196F3): 'V',
  Color(0xFFF44336): 'C',
  Color(0xFF4CAF50): 'B',
  Color(0xFF9C27B0): 'I',
  Color(0xFF795548): 'O',
  Color(0xFFFFC107): 'S',
  Color(0xFFFF9800): 'PC',
  Color(0xFF009688): 'T',
  Color(0xFF3F51B5): 'F',
  Color(0xFF9E9E9E): 'A',
};

/// Common Section labels are iterated through on import / parsing to identify sections
/// MIGHT BE PRUDENT TO MAKE THIS LOCALIZABLE IN THE FUTURE
/// AREA OF OPTIMIZATION: use a more efficient data structure for lookups
const Map<String, SectionLabel> commonSectionLabels = {
  'verse': SectionLabel(
    labelVariations: [
      'verse',
      'verso',
      r'(?:\w+\s+)?parte(?:\s*\d+)?',
      r'(?:\w+\s+)?estrofe(?:\s*\d+)?',
    ],
    labelType: SectionLabelType.verse,
    color: Color(0xFF2196F3),
  ),
  'chorus': SectionLabel(
    labelVariations: ['chorus', 'coro', 'refrao', 'refrão'],
    labelType: SectionLabelType.chorus,
    color: Color(0xFFF44336),
  ),
  'bridge': SectionLabel(
    labelVariations: ['bridge', 'ponte'],
    labelType: SectionLabelType.bridge,
    color: Colors.green,
  ),
  'intro': SectionLabel(
    labelVariations: ['intro'],
    labelType: SectionLabelType.intro,
    color: Color(0xFF9C27B0),
  ),
  'outro': SectionLabel(
    labelVariations: ['outro'],
    labelType: SectionLabelType.outro,
    color: Colors.brown,
  ),
  'solo': SectionLabel(
    labelVariations: ['solo'],
    labelType: SectionLabelType.solo,
    color: Colors.amber,
  ),
  'pre-chorus': SectionLabel(
    labelVariations: ['pre[- ]?chorus', 'pre[- ]?refrao', 'pré[- ]?refrão'],
    labelType: SectionLabelType.preChorus,
    color: Colors.orange,
  ),
  'tag': SectionLabel(
    labelVariations: ['tag'],
    labelType: SectionLabelType.tag,
    color: Colors.teal,
  ),
  'finale': SectionLabel(
    labelVariations: ['finale', 'final'],
    labelType: SectionLabelType.finale,
    color: Color(0xFF3F51B5),
  ),
  'annotations': SectionLabel(
    labelVariations: ['notes', 'anotacoes', 'anotações'],
    labelType: SectionLabelType.annotations,
    color: Colors.grey,
  ),
};

class SectionLabel {
  final List<String> labelVariations;
  final SectionLabelType labelType;
  final Color color;

  const SectionLabel({
    required this.labelVariations,
    required this.labelType,
    required this.color,
  });

  String get canonicalLabel => labelType.canonicalLabel;

  String localizedLabel(BuildContext context) =>
      labelType.localizedLabel(context);

  factory SectionLabel.unknown() {
    return const SectionLabel(
      labelVariations: [],
      labelType: SectionLabelType.unknown,
      color: Colors.grey,
    );
  }
}

/// Checks if the code trimmed of a numeric suffix matches any of transition codes
bool isTransition(String sectionCode) {
  final trimmedCode = sectionCode.replaceAll(RegExp(r'\d+$'), '');
  final transitionCodes = ['I', 'B', 'PC', 'S', 'O', 'F'];
  return (transitionCodes.contains(trimmedCode));
}
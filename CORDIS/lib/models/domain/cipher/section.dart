import 'package:cordis/utils/color.dart' as c;
import 'package:flutter/cupertino.dart';

class Section {
  final int? id;
  int versionId;
  String contentType;
  String contentCode;
  String contentText;
  Color contentColor;

  Section({
    this.id,
    required this.versionId,
    required this.contentType,
    required this.contentCode,
    required this.contentText,
    required this.contentColor,
  });

  factory Section.fromSqLite(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      versionId: json['version_id'],
      contentType: json['content_type'],
      contentCode: json['content_code'],
      contentText: json['content_text'],
      contentColor: c.colorFromHex(json['content_color']),
    );
  }

  factory Section.fromFirestore(Map<String, String> map) {
    return Section(
      versionId: 0, // Will be set later
      contentType: map['contentType'] ?? '',
      contentCode: map['contentCode'] ?? '',
      contentText: map['contentText'] ?? '',
      contentColor: c.colorFromHex(map['contentColor'] ?? '#FFFFFFFF'),
    );
  }

  /// Converts to a map suitable for SQLite storage
  /// Later the version Id (int) gets assigned
  Map<String, dynamic> toMap() {
    return {
      'content_type': contentType,
      'content_code': contentCode,
      'content_text': contentText,
      'content_color': c.colorToHex(contentColor),
    };
  }

  Section copyWith({
    int? id,
    int? versionId,
    String? contentType,
    String? contentCode,
    String? contentText,
    Color? contentColor,
  }) {
    return Section(
      id: id ?? this.id,
      versionId: versionId ?? this.versionId,
      contentType: contentType ?? this.contentType,
      contentCode: contentCode ?? this.contentCode,
      contentText: contentText ?? this.contentText,
      contentColor: contentColor ?? this.contentColor,
    );
  }
}

import 'package:cordis/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum BugSeverity {
  low,
  medium,
  high,
  critical,
}

extension BugSeverityExtension on BugSeverity {
  String label(BuildContext context) {
    switch (this) {
      case BugSeverity.low:
        return AppLocalizations.of(context)!.low;
      case BugSeverity.medium:
        return AppLocalizations.of(context)!.medium;
      case BugSeverity.high:
        return AppLocalizations.of(context)!.high;
      case BugSeverity.critical:
        return AppLocalizations.of(context)!.critical;
    }
  }
}

enum NetworkState {
  online, 
  offline,
  intermittent,
}


class BugReport {
  // USER FILLED
  final String title;
  final String description;
  final String reproductionSteps;
  final String expectedBehavior;
  final String actualBehavior;
  final BugSeverity? severity;

  // AUTOMATIC
  final String deviceInfo;
  final String appVersion;
  final NetworkState networkState;

  BugReport({
    required this.title,
    required this.description,
    required this.reproductionSteps,
    required this.expectedBehavior,
    required this.actualBehavior,
    required this.deviceInfo,
    required this.appVersion,
    required this.networkState,
    this.severity, 
   });


  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'reproductionSteps': reproductionSteps,
      'expectedBehavior': expectedBehavior,
      'actualBehavior': actualBehavior,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'severity': severity?.toString().split('.').last, 
    };
    }
}
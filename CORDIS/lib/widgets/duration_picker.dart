import 'package:cordis/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class DurationPicker extends StatefulWidget {
  final Duration initialDuration;

  const DurationPicker({super.key, required this.initialDuration});

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialDuration.inMinutes;
    _seconds = widget.initialDuration.inSeconds.remainder(60);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.setPlaceholder(AppLocalizations.of(context)!.duration),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              CloseButton(
                onPressed: () => Navigator.pop(
                  context,
                  Duration(minutes: _minutes, seconds: _seconds),
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.pluralPlaceholder(AppLocalizations.of(context)!.minute),
                    style: textTheme.labelMedium,
                  ),
                  NumberPicker(
                    value: _minutes,
                    minValue: 0,
                    maxValue: 59,
                    onChanged: (value) => setState(() => _minutes = value),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.pluralPlaceholder(AppLocalizations.of(context)!.second),
                    style: textTheme.labelMedium,
                  ),
                  NumberPicker(
                    value: _seconds,
                    minValue: 0,
                    maxValue: 59,
                    onChanged: (value) => setState(() => _seconds = value),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/settings/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StyleSettings extends StatefulWidget {
  final bool secret;

  const StyleSettings({super.key, this.secret = false});

  @override
  State<StyleSettings> createState() => _StyleSettingsState();
}

class _StyleSettingsState extends State<StyleSettings> {
  double? _localCardWidthMult;
  double? _localLineSpacing;
  double? _localLineBreakSpacing;
  double? _localChordLyricSpacing;
  double? _localMinChordSpacing;
  double? _localLetterSpacing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<LayoutSetProvider>(
      builder: (context, settings, child) {
        _localCardWidthMult ??= settings.cardWidthMult.clamp(0.2, 1);
        _localLineSpacing ??= settings.lineSpacing.clamp(-5, 10);
        _localLineBreakSpacing ??= settings.lineBreakSpacing.clamp(-5, 10);
        _localChordLyricSpacing ??= settings.chordLyricSpacing.clamp(-5, 15);
        _localMinChordSpacing ??= settings.minChordSpacing.clamp(-5, 5);
        _localLetterSpacing ??= settings.letterSpacing.clamp(-3, 3);
        
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              // HEADER
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.styleSettings,
                    style: textTheme.titleMedium,
                  ),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // SCROLL DIRECTION SETTINGS
              _buildOption(
                context,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.scrollDirection,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    Switch(
                      value: settings.scrollDirection == Axis.vertical,
                      onChanged: (_) {
                        settings.toggleAxisDirection();
                      },
                      thumbIcon: WidgetStatePropertyAll(
                        settings.scrollDirection == Axis.vertical
                            ? const Icon(Icons.swap_vert)
                            : const Icon(Icons.swap_horiz),
                      ),
                      thumbColor: WidgetStatePropertyAll(colorScheme.primary),
                      trackColor: WidgetStatePropertyAll(
                        colorScheme.surfaceContainerHigh,
                      ),
                      trackOutlineColor: WidgetStatePropertyAll(
                        colorScheme.surfaceTint,
                      ),
                    ),
                  ],
                ),
              ),

              /// COMPACT VIEW
              _buildOption(
                context,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.compactView,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    Switch(
                      value: !settings.showSectionHeaders,
                      onChanged: (_) => settings.toggleSectionHeaders(),
                      thumbColor: WidgetStatePropertyAll(colorScheme.primary),
                      trackColor: WidgetStatePropertyAll(
                        colorScheme.surfaceContainerHigh,
                      ),
                      trackOutlineColor: WidgetStatePropertyAll(
                        colorScheme.surfaceTint,
                      ),
                    ),
                  ],
                ),
              ),

              // CARD WIDTH SETTINGS
              _buildOption(
                context,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.cardWidth,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      (1 / _localCardWidthMult!).toStringAsFixed(1),
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Slider(
                      value: _localCardWidthMult!,
                      min: 0.2,
                      max: 1.0,
                      onChanged: (v) {
                        setState(() => _localCardWidthMult = v);
                      },
                      onChangeEnd: (v) {
                        settings.setCardWidthMult(v);
                      },
                    ),
                  ],
                ),
              ),

              // FONT SETTINGS
              _buildOption(
                context,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: settings.fontFamily,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'OpenSans',
                            child: Text(
                              'OpenSans',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Asimovian',
                            child: Text(
                              'Asimovian',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Asimovian',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Atkinson',
                            child: Text(
                              'Atkinson',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Atkinson',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Caveat',
                            child: Text(
                              'Caveat',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Caveat',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) settings.setFontFamily(v);
                        },
                        underline: Container(),
                      ),
                    ),
                    const SizedBox(width: 32),
                    DropdownButton<double>(
                      value: settings.fontSize,
                      items: List.generate(12, (i) {
                        final double size = 12 + i * 2;
                        return DropdownMenuItem(
                          value: size,
                          child: Text(size.toString()),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) settings.setFontSize(v);
                      },
                      underline: Container(),
                    ),
                  ],
                ),
              ),

              if (widget.secret) ...[
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.lineSpacing,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        _localLineSpacing!.toStringAsFixed(1),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Slider(
                        value: _localLineSpacing!,
                        min: -5,
                        max: 10,
                        onChanged: (v) {
                          setState(() => _localLineSpacing = v);
                        },
                        onChangeEnd: (v) {
                          settings.setLineSpacing(v);
                        },
                      ),
                    ],
                  ),
                ),
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.lineBreakSpacing,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        _localLineBreakSpacing!.toStringAsFixed(1),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Slider(
                        value: _localLineBreakSpacing!,
                        min: -5,
                        max: 10,
                        onChanged: (v) {
                          setState(() => _localLineBreakSpacing = v);
                        },
                        onChangeEnd: (v) {
                          settings.setLineBreakSpacing(v);
                        },
                      ),
                    ],
                  ),
                ),
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.chordLyricSpacing,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        _localChordLyricSpacing!.toStringAsFixed(1),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Slider(
                        value: _localChordLyricSpacing!,
                        min: -5,
                        max: 15,
                        onChanged: (v) {
                          setState(() => _localChordLyricSpacing = v);
                        },
                        onChangeEnd: (v) {
                          settings.setChordLyricSpacing(v);
                        },
                      ),
                    ],
                  ),
                ),
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.minChordSpacing,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        _localMinChordSpacing!.toStringAsFixed(1),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Slider(
                        value: _localMinChordSpacing!,
                        min: -5,
                        max: 5,
                        onChanged: (v) {
                          setState(() => _localMinChordSpacing = v);
                        },
                        onChangeEnd: (v) {
                          settings.setMinChordSpacing(v);
                        },
                      ),
                    ],
                  ),
                ),
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.letterSpacing,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        _localLetterSpacing!.toStringAsFixed(1),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Slider(
                        value: _localLetterSpacing!,
                        min: -3,
                        max: 3,
                        onChanged: (v) {
                          setState(() => _localLetterSpacing = v);
                        },
                        onChangeEnd: (v) {
                          settings.setLetterSpacing(v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(),
            ],
          ),
        );
      },
    );
  }

  Container _buildOption(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: colorScheme.surfaceContainerLowest, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}

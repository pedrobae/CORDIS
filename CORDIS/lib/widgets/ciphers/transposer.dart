import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Transposer extends StatelessWidget {
  const Transposer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<LayoutSettingsProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          tooltip: 'Diminuir tom',
          onPressed: () => settings.transposeDown(),
        ),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  actionsAlignment: MainAxisAlignment.center,
                  title: const Text('Selecione um tom'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                      children: settings.keys.map((key) {
                        return ElevatedButton(
                          onPressed: () {
                            settings.selectKey(key);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(60, 48),
                          ),
                          child: Text(
                            key,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    FilledButton(
                      child: const Text('Tom original'),
                      onPressed: () => settings.resetToOriginalKey(),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                );
              },
            );
          },
          child: Text(
            settings.transposedKey,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Aumentar tom',
          onPressed: () => settings.transposeUp(),
        ),
      ],
    );
  }
}

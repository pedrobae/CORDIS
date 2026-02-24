import 'package:cordis/providers/transposition_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Transposer extends StatelessWidget {
  const Transposer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranspositionProvider>(
      builder: (context, tp, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: 'Diminuir tom',
              onPressed: () => tp.transposeDown(),
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
                          children: tp.chordRoots.map((key) {
                            return ElevatedButton(
                              onPressed: () {
                                tp.setTransposedKey(key);
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
                          onPressed: () => tp.setTransposedKey(null),
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
                tp.transposedKey ?? '-',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Aumentar tom',
              onPressed: () => tp.transposeUp(),
            ),
          ],
        );
      },
    );
  }
}

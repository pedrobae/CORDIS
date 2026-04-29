import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Transposer extends StatelessWidget {
  const Transposer({super.key});

  @override
  Widget build(BuildContext context) {
    final trans = context.read<TranspositionProvider>();

    return Selector<
      TranspositionProvider,
      ({String? transposed, String original, int versionID})
    >(
      selector: (context, tp) => (
        transposed: tp.transposedKey,
        original: tp.originalKey,
        versionID: tp.versionID,
      ),
      builder: (context, s, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => trans.transposeDown(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.remove),
              ),
            ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return SelectKeySheet(
                      initialKey: s.transposed,
                      originalKey: s.original,
                      versionID: s.versionID,
                      showSave: (s.versionID < 0) ? false : true,
                      onKeySelected: (key) {
                        trans.setTransposedKey(key);
                      },
                    );
                  },
                );
              },
              child: SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: Text(
                    s.transposed ?? s.original,
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => trans.transposeUp(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

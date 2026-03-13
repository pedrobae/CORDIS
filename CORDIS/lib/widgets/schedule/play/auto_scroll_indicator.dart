import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AutoScrollIndicator extends StatelessWidget {
  const AutoScrollIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AutoScrollProvider>(
      builder: (context, scrollProvider, child) {
        return GestureDetector(
          onTap: () {
            scrollProvider.toggleAutoScroll();
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceTint.withAlpha(204), // 0.8 * 255 = 204
              shape: BoxShape.circle,
            ),
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  value: scrollProvider.timerProgress,
                  color: colorScheme.primary,
                ),
                Icon(
                  scrollProvider.isAutoScrolling ? Icons.pause : Icons.play_arrow,
                  size: 24,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
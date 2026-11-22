import 'package:flutter/material.dart';
import '../utils/image_cache_helper.dart';

class EndScreen extends StatelessWidget {
  const EndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final bgCacheWidth = computeStableCacheWidth(context, maxWidth: 1920);
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            isPortrait ? 'assets/images/darthack_end.webp' : 'assets/images/darkhack_end_yoko.webp',
            cacheWidth: bgCacheWidth,
            gaplessPlayback: true,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

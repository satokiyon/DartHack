import 'package:flutter/material.dart';

class EndScreen extends StatelessWidget {
  const EndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            isPortrait ? 'assets/images/darthack_end.png' : 'assets/images/darkhack_end_yoko.png',
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

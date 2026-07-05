import 'package:flutter/material.dart';

class NetHackDPad extends StatelessWidget {
  final Function(String) onKeyPress;

  const NetHackDPad({super.key, required this.onKeyPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(75),
        border: Border.all(color: Colors.white12, width: 1.5),
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: [
          _buildDpadButton('y', '↖'),
          _buildDpadButton('k', '▲'),
          _buildDpadButton('u', '↗'),
          _buildDpadButton('h', '◀'),
          _buildDpadButton('.', '●'),
          _buildDpadButton('l', '▶'),
          _buildDpadButton('b', '↙'),
          _buildDpadButton('j', '▼'),
          _buildDpadButton('n', '↘'),
        ],
      ),
    );
  }

  Widget _buildDpadButton(String key, String label) {
    return GestureDetector(
      onTapDown: (_) => onKeyPress(key),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

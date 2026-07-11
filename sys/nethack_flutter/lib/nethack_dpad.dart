import 'package:flutter/material.dart';

class NetHackDPad extends StatelessWidget {
  final Map<String, String> directionLabels;
  final String centerLabel;
  final void Function(String) onDirectionPress;
  final void Function(String)? onDirectionLongPress;
  final VoidCallback onCenterTap;
  final VoidCallback onCenterLongPress;

  final double opacity;

  const NetHackDPad({
    super.key,
    required this.directionLabels,
    required this.centerLabel,
    required this.onDirectionPress,
    required this.onCenterTap,
    required this.onCenterLongPress,
    this.onDirectionLongPress,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(75),
        border: Border.all(color: const Color(0xFF3E3E3E).withValues(alpha: opacity), width: 1.5),
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: [
          _buildDirectionButton('y'),
          _buildDirectionButton('k'),
          _buildDirectionButton('u'),
          _buildDirectionButton('h'),
          _buildCenterButton(),
          _buildDirectionButton('l'),
          _buildDirectionButton('b'),
          _buildDirectionButton('j'),
          _buildDirectionButton('n'),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(String viKey) {
    return GestureDetector(
      onTap: () => onDirectionPress(viKey),
      onLongPress: onDirectionLongPress == null
          ? null
          : () => onDirectionLongPress!(viKey),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          directionLabels[viKey] ?? viKey,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: onCenterTap,
      onLongPress: onCenterLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              centerLabel,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

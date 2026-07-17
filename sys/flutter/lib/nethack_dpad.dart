import 'dart:math' as math;
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
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.all(4),
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

  double _getAngle(String viKey) {
    switch (viKey) {
      case 'k':
        return 0.0;
      case 'u':
        return math.pi / 4;
      case 'l':
        return math.pi / 2;
      case 'n':
        return 3 * math.pi / 4;
      case 'j':
        return math.pi;
      case 'b':
        return 5 * math.pi / 4;
      case 'h':
        return 3 * math.pi / 2;
      case 'y':
        return 7 * math.pi / 4;
      default:
        return 0.0;
    }
  }

  Widget _buildDirectionButton(String viKey) {
    final angle = _getAngle(viKey);
    return ClipPath(
      clipper: ArrowClipper(angle),
      child: CustomPaint(
        painter: ArrowPainter(
          angle: angle,
          borderColor: const Color(0xFF3E3E3E).withValues(alpha: opacity),
          borderWidth: 3.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: opacity),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onDirectionPress(viKey),
              onLongPress: onDirectionLongPress == null
                  ? null
                  : () => onDirectionLongPress!(viKey),
              child: Container(
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: opacity),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF3E3E3E).withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onCenterTap,
          onLongPress: onCenterLongPress,
          child: Container(
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
        ),
      ),
    );
  }
}

class ArrowClipper extends CustomClipper<Path> {
  final double angle;

  ArrowClipper(this.angle);

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final centerY = h / 2;

    final arrowWidth = w * 0.75;
    final halfW = arrowWidth / 2;

    // 基本の上向き矢印（五角形）のパス（中心 (0,0) 基準）
    final path = Path();
    path.moveTo(0, -h / 2);
    path.lineTo(halfW, -h * 0.1);
    path.lineTo(halfW, h / 2);
    path.lineTo(-halfW, h / 2);
    path.lineTo(-halfW, -h * 0.1);
    path.close();

    final matrix = Matrix4.translationValues(centerX, centerY, 0.0)
      ..rotateZ(angle);

    return path.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant ArrowClipper oldClipper) => oldClipper.angle != angle;
}

class ArrowPainter extends CustomPainter {
  final double angle;
  final Color borderColor;
  final double borderWidth;

  ArrowPainter({
    required this.angle,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final centerY = h / 2;

    final arrowWidth = w * 0.75;
    final halfW = arrowWidth / 2;

    final path = Path();
    path.moveTo(0, -h / 2);
    path.lineTo(halfW, -h * 0.1);
    path.lineTo(halfW, h / 2);
    path.lineTo(-halfW, h / 2);
    path.lineTo(-halfW, -h * 0.1);
    path.close();

    final matrix = Matrix4.translationValues(centerX, centerY, 0.0)
      ..rotateZ(angle);

    final transformedPath = path.transform(matrix.storage);

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(transformedPath, paint);
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}

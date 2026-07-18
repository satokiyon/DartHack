import 'dart:math' as math;
import 'package:flutter/material.dart';

class NetHackDPad extends StatefulWidget {
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
  State<NetHackDPad> createState() => _NetHackDPadState();
}

class _NetHackDPadState extends State<NetHackDPad> {
  // 現在押されているキー（ハイライト表示用）
  String? _pressedKey;

  // 9分割セルのキー配置（左上→右下の順）
  // 'c' は中央ボタン
  static const List<String> _keys = [
    'y', 'k', 'u',
    'h', 'c', 'l',
    'b', 'j', 'n',
  ];

  void _onCellTapDown(String key) {
    setState(() => _pressedKey = key);
  }

  void _onCellTapUp(String key) {
    if (key == 'c') {
      widget.onCenterTap();
    } else {
      widget.onDirectionPress(key);
    }
    setState(() => _pressedKey = null);
  }

  void _onCellTapCancel() {
    setState(() => _pressedKey = null);
  }

  void _onCellLongPress(String key) {
    setState(() => _pressedKey = null);
    if (key == 'c') {
      widget.onCenterLongPress();
    } else {
      widget.onDirectionLongPress?.call(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double padSize = 150.0;
    const double cellSize = padSize / 3;

    return SizedBox(
      width: padSize,
      height: padSize,
      child: Stack(
        children: [
          // ─── 見た目レイヤー ──────────────────────────────────
          // GridView で五角形/円ボタンを描画（タッチ判定なし・見た目のみ）
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(4),
              child: GridView.count(
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                children: [
                  _buildDirectionVisual('y'),
                  _buildDirectionVisual('k'),
                  _buildDirectionVisual('u'),
                  _buildDirectionVisual('h'),
                  _buildCenterVisual(),
                  _buildDirectionVisual('l'),
                  _buildDirectionVisual('b'),
                  _buildDirectionVisual('j'),
                  _buildDirectionVisual('n'),
                ],
              ),
            ),
          ),

          // ─── タッチ判定レイヤー ──────────────────────────────
          // 9分割の透明な四角形をすき間なく並べ、各方向・中央ボタンの判定を担う
          ...List.generate(9, (i) {
            final col = i % 3;
            final row = i ~/ 3;
            final key = _keys[i];
            return Positioned(
              left: col * cellSize,
              top: row * cellSize,
              width: cellSize,
              height: cellSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // 透明領域でもヒット判定あり
                onTapDown: (_) => _onCellTapDown(key),
                onTapUp: (_) => _onCellTapUp(key),
                onTapCancel: _onCellTapCancel,
                onLongPress: () => _onCellLongPress(key),
                onLongPressStart: (_) => setState(() => _pressedKey = key),
                onLongPressEnd: (_) => setState(() => _pressedKey = null),
              ),
            );
          }),
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

  /// 見た目のみの方向ボタン（五角形）。タッチ判定は持たない
  Widget _buildDirectionVisual(String viKey) {
    final angle = _getAngle(viKey);
    final isPressed = _pressedKey == viKey;
    final baseColor = isPressed
        ? const Color(0xFF4E4E4E) // 押下時は少し明るく
        : const Color(0xFF1E1E1E);
    return ClipPath(
      clipper: ArrowClipper(angle),
      child: CustomPaint(
        painter: ArrowPainter(
          angle: angle,
          borderColor: const Color(0xFF3E3E3E).withValues(alpha: widget.opacity),
          borderWidth: 3.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: widget.opacity),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              widget.directionLabels[viKey] ?? viKey,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 見た目のみの中央ボタン（円）。タッチ判定は持たない
  Widget _buildCenterVisual() {
    final isPressed = _pressedKey == 'c';
    final baseColor = isPressed
        ? const Color(0xFF4E4E4E) // 押下時は少し明るく
        : const Color(0xFF1E1E1E);
    return Container(
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: widget.opacity),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF3E3E3E).withValues(alpha: widget.opacity),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              widget.centerLabel,
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

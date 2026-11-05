import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../nethack_screen.dart';
import '../nethack_map_painter.dart';
import '../services/font_manager.dart';

void showFullMapDialog({
  required BuildContext context,
  required NetHackScreen screen,
  required bool useTiles,
  required ui.Image? tileImage,
  required int tileWidth,
  required int tileHeight,
  bool isTransparentTileset = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
        ),
        child: _FullMapDialogContent(
          screen: screen,
          useTiles: useTiles,
          tileImage: tileImage,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          isTransparentTileset: isTransparentTileset,
          l10n: l10n,
        ),
      );
    },
  );
}

class _FullMapDialogContent extends StatefulWidget {
  final NetHackScreen screen;
  final bool useTiles;
  final ui.Image? tileImage;
  final int tileWidth;
  final int tileHeight;
  final bool isTransparentTileset;
  final AppLocalizations l10n;

  const _FullMapDialogContent({
    required this.screen,
    required this.useTiles,
    required this.tileImage,
    required this.tileWidth,
    required this.tileHeight,
    this.isTransparentTileset = false,
    required this.l10n,
  });

  @override
  State<_FullMapDialogContent> createState() => _FullMapDialogContentState();
}

class _FullMapDialogContentState extends State<_FullMapDialogContent>
    with SingleTickerProviderStateMixin {
  final GlobalKey _viewerKey = GlobalKey();
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  late final FocusNode _focusNode;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;
  bool _isCloseButtonFocused = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    _toggleZoom(focalPoint: _doubleTapDetails?.localPosition);
  }

  /// 画面中心または指定座標を中心に拡大（6倍）と全体表示（等倍）をアニメーショントグル
  void _toggleZoom({Offset? focalPoint}) {
    if (_animationController.isAnimating) return;

    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    final Matrix4 endMatrix;
    if (currentScale > 1.05) {
      // 拡大中の場合は初期（全体表示）にスムーズにリセット
      endMatrix = Matrix4.identity();
    } else {
      // 全体表示中の場合は指定位置（またはビューポート中心）を中心に約6倍にズームイン
      const targetScale = 6.0;
      final RenderBox? box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
      final size = box?.size ?? const Size(400, 300);
      final center = focalPoint ?? Offset(size.width / 2, size.height / 2);
      final x = -center.dx * (targetScale - 1);
      final y = -center.dy * (targetScale - 1);
      endMatrix = Matrix4.identity()
        ..translateByDouble(x, y, 0.0, 1.0)
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
    }

    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward(from: 0.0);
  }

  /// ズームを全体表示（等倍）にリセット
  void _resetZoom() {
    if (_animationController.isAnimating) return;
    final currentMatrix = _transformationController.value;
    if (currentMatrix.isIdentity()) return;

    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward(from: 0.0);
  }

  /// ビューポート中心を基準に段階的にズームイン・アウト
  void _zoomBy(double factor) {
    if (_animationController.isAnimating) return;

    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(0.8, 30.0);
    if ((targetScale - currentScale).abs() < 0.001) return;

    final effectiveFactor = targetScale / currentScale;
    final RenderBox? box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size ?? const Size(400, 300);
    final cx = size.width / 2;
    final cy = size.height / 2;

    final tx = currentMatrix.storage[12];
    final ty = currentMatrix.storage[13];
    final newTx = cx - effectiveFactor * (cx - tx);
    final newTy = cy - effectiveFactor * (cy - ty);

    final newMatrix = Matrix4.identity()
      ..translateByDouble(newTx, newTy, 0.0, 1.0)
      ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);

    _transformationController.value = newMatrix;
  }

  /// マップのパン（平行移動）
  void _panBy(double dx, double dy) {
    final matrix = _transformationController.value.clone();
    matrix.translateByDouble(dx, dy, 0.0, 1.0);
    _transformationController.value = matrix;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent;
    final isRepeat = event is KeyRepeatEvent;
    if (!isDown && !isRepeat) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // 閉じる: Escape / q / Space
    if (key == LogicalKeyboardKey.escape ||
        (key == LogicalKeyboardKey.keyQ && !isCtrl) ||
        key == LogicalKeyboardKey.space) {
      if (isDown) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    // 決定: Enter / NumpadEnter
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (isDown) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    // Tab / Shift+Tab: フォーカス循環 (none ↔ closeButton)
    if (key == LogicalKeyboardKey.tab) {
      if (isDown) {
        setState(() {
          _isCloseButtonFocused = !_isCloseButtonFocused;
        });
      }
      return KeyEventResult.handled;
    }

    // ズームリセット: 0 / Home
    if (key == LogicalKeyboardKey.digit0 ||
        key == LogicalKeyboardKey.numpad0 ||
        key == LogicalKeyboardKey.home) {
      if (isDown) _resetZoom();
      return KeyEventResult.handled;
    }

    // 拡大トグル: z
    if (key == LogicalKeyboardKey.keyZ && !isCtrl) {
      if (isDown) _toggleZoom();
      return KeyEventResult.handled;
    }

    // ズームイン: + / = / NumpadAdd
    if (event.character == '+' ||
        key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadAdd) {
      _zoomBy(1.25);
      return KeyEventResult.handled;
    }

    // ズームアウト: - / NumpadSubtract
    if (event.character == '-' ||
        key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _zoomBy(0.8);
      return KeyEventResult.handled;
    }

    // パン移動量 (Shiftで2倍高速)
    final panStep = isShift ? 80.0 : 40.0;

    // パン（平行移動）: 矢印キーおよび Viキー (h, j, k, l, y, u, b, n)
    if (key == LogicalKeyboardKey.arrowLeft || (key == LogicalKeyboardKey.keyH && !isCtrl)) {
      _panBy(panStep, 0.0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight || (key == LogicalKeyboardKey.keyL && !isCtrl)) {
      _panBy(-panStep, 0.0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || (key == LogicalKeyboardKey.keyK && !isCtrl)) {
      _panBy(0.0, panStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || (key == LogicalKeyboardKey.keyJ && !isCtrl)) {
      _panBy(0.0, -panStep);
      return KeyEventResult.handled;
    }
    // 斜め Vi キー
    if (key == LogicalKeyboardKey.keyY && !isCtrl) {
      _panBy(panStep, panStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyU && !isCtrl) {
      _panBy(-panStep, panStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyB && !isCtrl) {
      _panBy(panStep, -panStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyN && !isCtrl) {
      _panBy(-panStep, -panStep);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = FontManager.instance.getMapCellSize(
      useTiles: widget.useTiles,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
    );
    final cellW = cellSize.width;
    final cellH = cellSize.height;
    final mapWidth = NetHackScreen.mapCols * cellW;
    final mapHeight = NetHackScreen.mapRows * cellH;

    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    final mapWidget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onDoubleTapDown: (details) => _doubleTapDetails = details,
        onDoubleTap: _onDoubleTap,
        child: InteractiveViewer(
          key: _viewerKey,
          transformationController: _transformationController,
          minScale: 0.8,
          maxScale: 30.0,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: mapWidth,
                height: mapHeight,
                child: CustomPaint(
                  painter: NetHackMapPainter(
                    screen: widget.screen,
                    tileImage: widget.tileImage,
                    tileWidth: widget.tileWidth,
                    tileHeight: widget.tileHeight,
                    useTiles: widget.useTiles,
                    isTransparentTileset: widget.isTransparentTileset,
                    fontId: FontManager.instance.getSelectedFont(FontTarget.map).id,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Widget dialogContent = Column(
      mainAxisSize: isPortrait ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Container(
          color: Colors.deepPurple[900],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.map, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.l10n.fullLevelMap,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: _isCloseButtonFocused
                      ? Colors.amberAccent.withValues(alpha: 0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _isCloseButtonFocused ? Colors.amberAccent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: _isCloseButtonFocused ? Colors.amberAccent : Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
        if (isPortrait)
          Expanded(child: mapWidget)
        else
          Flexible(child: mapWidget),
        Container(
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.l10n.pinchToZoom,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

    if (isPortrait) {
      dialogContent = SizedBox(
        width: double.infinity,
        height: mediaQuery.size.height * 0.65,
        child: dialogContent,
      );
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: dialogContent,
    );
  }
}

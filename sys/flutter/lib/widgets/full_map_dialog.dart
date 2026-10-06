import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nethack_screen.dart';
import '../nethack_map_painter.dart';

void showFullMapDialog({
  required BuildContext context,
  required NetHackScreen screen,
  required bool useTiles,
  required ui.Image? tileImage,
  required int tileWidth,
  required int tileHeight,
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
  final AppLocalizations l10n;

  const _FullMapDialogContent({
    required this.screen,
    required this.useTiles,
    required this.tileImage,
    required this.tileWidth,
    required this.tileHeight,
    required this.l10n,
  });

  @override
  State<_FullMapDialogContent> createState() => _FullMapDialogContentState();
}

class _FullMapDialogContentState extends State<_FullMapDialogContent>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
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
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (_animationController.isAnimating) return;

    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    final Matrix4 endMatrix;
    if (currentScale > 1.05) {
      // 拡大中の場合は初期（全体表示）にスムーズにリセット
      endMatrix = Matrix4.identity();
    } else {
      // 全体表示中の場合はタップ位置を中心に約6倍にズームイン
      const targetScale = 6.0;
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);
      endMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(targetScale);
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

  @override
  Widget build(BuildContext context) {
    final cellW = widget.useTiles ? 32.0 : 9.0;
    final cellH = widget.useTiles ? 32.0 : 16.0;
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
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
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

    return dialogContent;
  }
}

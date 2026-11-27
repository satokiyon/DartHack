import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/map_animation_event.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/utils/map_animation_controller.dart';
import 'package:darthack/widgets/nethack_animation_overlay_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('テキストモードで背景文字(bkchar/bkcolor)付き移動・攻撃・死亡・飛び道具がエラーなく描画される', () {
    final screen = NetHackScreen();
    screen.printGlyph(
      3,
      11,
      10,
      -1,
      '@'.codeUnitAt(0),
      0xFFFFFFFF,
      0,
      -1,
      '.'.codeUnitAt(0),
      0xFF888888,
    );
    screen.printGlyph(
      3,
      12,
      10,
      -1,
      'g'.codeUnitAt(0),
      0xFF00FF00,
      0x10, // MG_PET
      -1,
      '#'.codeUnitAt(0),
      0xFFAAAAAA,
    );

    final animCtrl = MapAnimationController();
    addTearDown(animCtrl.dispose);

    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.move,
      entityId: 0,
      fromX: 10,
      fromY: 10,
      toX: 11,
      toY: 10,
    ));
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.attack,
      entityId: 0,
      fromX: 11,
      fromY: 10,
      toX: 12,
      toY: 10,
      param1: 1,
    ));
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.death,
      entityId: 5,
      fromX: 14,
      fromY: 10,
      toX: 14,
      toY: 10,
      param1: -1,
      param2: 100, // 'd'
      param3: 0xFFFF0000,
    ));
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.projectile,
      entityId: 0,
      fromX: 11,
      fromY: 10,
      toX: 15,
      toY: 10,
      param1: -1,
      param2: 42, // '*'
      param3: 0xFFFFFF00,
    ));

    animCtrl.advance(const Duration(milliseconds: 40));

    final painter = NetHackAnimationOverlayPainter(
      screen: screen,
      animationController: animCtrl,
      tileImage: null,
      tileWidth: 32,
      tileHeight: 32,
      useTiles: false,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    expect(() => painter.paint(canvas, const Size(800, 600)), returnsNormally);
    recorder.endRecording().dispose();
  });

  test('透過・非透過タイルモードでアニメーションオーバーレイがエラーなく描画される', () async {
    final screen = NetHackScreen();
    screen.printGlyph(3, 5, 5, 10, '@'.codeUnitAt(0), 0xFFFFFFFF, 0, 2);
    screen.printGlyph(3, 6, 5, 11, 'd'.codeUnitAt(0), 0xFFFFFFFF, 0x10 | 0x80, 2);

    final recorderImg = ui.PictureRecorder();
    final canvasImg = Canvas(recorderImg);
    canvasImg.drawRect(const Rect.fromLTWH(0, 0, 1280, 128), Paint()..color = Colors.teal);
    final dummyImg = await recorderImg.endRecording().toImage(1280, 128);
    addTearDown(dummyImg.dispose);

    final animCtrl = MapAnimationController();
    addTearDown(animCtrl.dispose);

    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.move,
      entityId: 0,
      fromX: 4,
      fromY: 5,
      toX: 5,
      toY: 5,
    ));
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.attack,
      entityId: 0,
      fromX: 5,
      fromY: 5,
      toX: 6,
      toY: 5,
      param1: 1,
    ));
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.death,
      entityId: 9,
      fromX: 7,
      fromY: 5,
      toX: 7,
      toY: 5,
      param1: 12,
      param2: 111,
      param3: 0xFFFFFFFF,
    ));
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.projectile,
      entityId: 0,
      fromX: 5,
      fromY: 5,
      toX: 8,
      toY: 5,
      param1: 15,
      param2: 41,
      param3: 0xFFFFFFFF,
    ));

    animCtrl.advance(const Duration(milliseconds: 30));

    for (final isTransparent in [true, false]) {
      final painter = NetHackAnimationOverlayPainter(
        screen: screen,
        animationController: animCtrl,
        tileImage: dummyImg,
        tileWidth: 32,
        tileHeight: 32,
        useTiles: true,
        isTransparentTileset: isTransparent,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(800, 600)), returnsNormally);
      recorder.endRecording().dispose();
    }
  });

  test('anim_event が printGlyph より先行到着し移動先が床のままでもフォールバックグリフで正常描画される', () async {
    final screen = NetHackScreen();
    // 移動先セル (11, 10) はまだ床 (tile=2, bktile=2, char='.', bkchar='.') のまま
    screen.printGlyph(3, 11, 10, 2, '.'.codeUnitAt(0), 0xFF888888, 0, 2, '.'.codeUnitAt(0), 0xFF888888);

    final animCtrl = MapAnimationController();
    addTearDown(animCtrl.dispose);

    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.move,
      entityId: 0,
      fromX: 10,
      fromY: 10,
      toX: 11,
      toY: 10,
      param1: 10, // 主人公タイル
      param2: 64, // '@'
      param3: 0xFFFFFFFF,
    ));
    animCtrl.advance(const Duration(milliseconds: 40));

    final recorderImg = ui.PictureRecorder();
    final canvasImg = Canvas(recorderImg);
    canvasImg.drawRect(const Rect.fromLTWH(0, 0, 1280, 128), Paint()..color = Colors.amber);
    final dummyImg = await recorderImg.endRecording().toImage(1280, 128);
    addTearDown(dummyImg.dispose);

    for (final useTiles in [true, false]) {
      final painter = NetHackAnimationOverlayPainter(
        screen: screen,
        animationController: animCtrl,
        tileImage: useTiles ? dummyImg : null,
        tileWidth: 32,
        tileHeight: 32,
        useTiles: useTiles,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(800, 600)), returnsNormally);
      recorder.endRecording().dispose();
    }
  });

  test('岩押し消滅・光リング・パーティクル・持続マイクロ演出・フローティングテキストが全モードでエラーなく描画される', () async {
    final screen = NetHackScreen();
    screen.printGlyph(3, 10, 10, 10, '@'.codeUnitAt(0), 0xFFFFFFFF, 0, 2, '.'.codeUnitAt(0), 0xFF888888);
    screen.printGlyph(3, 12, 10, 11, 'o'.codeUnitAt(0), 0xFF00FF00, 0, 2, '.'.codeUnitAt(0), 0xFF888888);

    final recorderImg = ui.PictureRecorder();
    final canvasImg = Canvas(recorderImg);
    canvasImg.drawRect(const Rect.fromLTWH(0, 0, 1280, 128), Paint()..color = Colors.indigo);
    final dummyImg = await recorderImg.endRecording().toImage(1280, 128);
    addTearDown(dummyImg.dispose);

    final animCtrl = MapAnimationController(isJapanese: true);
    addTearDown(animCtrl.dispose);

    // 消滅岩押し
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.objectMove,
      entityId: MapObjectMoveKind.vanishing,
      fromX: 8,
      fromY: 10,
      toX: 9,
      toY: 10,
      param1: 20,
      param2: 96,
      param3: 0xFFAAAAAA,
    ));
    // 爆発 VFX（リング＋発光粒）＆砂埃（ドット粒）
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.vfx,
      entityId: MapVfxKind.explosion,
      fromX: 11,
      fromY: 10,
      toX: 11,
      toY: 10,
      param1: 0xFFFF6D00,
      param2: 3,
    ));
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.vfx,
      entityId: MapVfxKind.dust,
      fromX: 9,
      fromY: 10,
      toX: 9,
      toY: 10,
      param1: 0xFFD7CCC8,
      param2: 1,
    ));
    // 持続マイクロ演出（浮遊＋混乱＋石化＋混乱の手）
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.ambientStatus,
      entityId: AmbientStatusBits.levitating |
          AmbientStatusBits.confused |
          AmbientStatusBits.stoning |
          AmbientStatusBits.confusingHands,
      fromX: 10,
      fromY: 10,
      toX: 10,
      toY: 10,
    ));
    // 敵の逃走汗粒
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.ambientStatus,
      entityId: AmbientStatusBits.fleeing,
      fromX: 12,
      fromY: 10,
      toX: 12,
      toY: 10,
    ));
    // フローティングテキスト
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.floatingText,
      entityId: FloatingTextKind.dmgMon,
      fromX: 12,
      fromY: 10,
      toX: 12,
      toY: 10,
      param1: 24,
    ));

    animCtrl.advance(const Duration(milliseconds: 50));

    final modes = [
      (useTiles: false, transparent: false),
      (useTiles: true, transparent: true),
      (useTiles: true, transparent: false),
    ];
    for (final mode in modes) {
      animCtrl.canLiftFloatingGlyph = true;
      final painter = NetHackAnimationOverlayPainter(
        screen: screen,
        animationController: animCtrl,
        tileImage: mode.useTiles ? dummyImg : null,
        tileWidth: 32,
        tileHeight: 32,
        useTiles: mode.useTiles,
        isTransparentTileset: mode.transparent,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(800, 600)), returnsNormally);
      recorder.endRecording().dispose();
    }
  });

  test('麻痺（黄色ギザギザ縦棒2本）・浮遊・敵逃走（汗マーク）が全モードでエラーなく描画される', () async {
    final screen = NetHackScreen();
    screen.printGlyph(3, 10, 10, 698, '@'.codeUnitAt(0), 0xFFFFFFFF, 0, 1291, '.'.codeUnitAt(0), 0xFF888888);
    screen.printGlyph(3, 12, 10, 148, 'o'.codeUnitAt(0), 0xFF00FF00, 0, 1291, '.'.codeUnitAt(0), 0xFF888888);

    final recorderImg = ui.PictureRecorder();
    final canvasImg = Canvas(recorderImg);
    canvasImg.drawRect(const Rect.fromLTWH(0, 0, 1280, 1088), Paint()..color = Colors.indigo);
    final dummyImg = await recorderImg.endRecording().toImage(1280, 1088);
    addTearDown(dummyImg.dispose);

    final animCtrl = MapAnimationController(canLiftFloatingGlyph: true);
    addTearDown(animCtrl.dispose);

    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.ambientStatus,
      entityId: AmbientStatusBits.paralyzed | AmbientStatusBits.levitating,
      fromX: 10,
      fromY: 10,
      toX: 10,
      toY: 10,
    ));
    animCtrl.handleEvent(const MapAnimEvent(
      turnId: 1,
      eventType: MapAnimEventType.ambientStatus,
      entityId: AmbientStatusBits.fleeing,
      fromX: 12,
      fromY: 10,
      toX: 12,
      toY: 10,
    ));

    final modes = [
      (useTiles: false, transparent: false),
      (useTiles: true, transparent: true),
      (useTiles: true, transparent: false),
    ];
    for (final mode in modes) {
      final painter = NetHackAnimationOverlayPainter(
        screen: screen,
        animationController: animCtrl,
        tileImage: mode.useTiles ? dummyImg : null,
        tileWidth: 32,
        tileHeight: 32,
        useTiles: mode.useTiles,
        isTransparentTileset: mode.transparent,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(800, 600)), returnsNormally);
      recorder.endRecording().dispose();
    }
  });
}

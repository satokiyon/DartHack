import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/map_animation_event.dart';
import 'package:darthack/utils/map_animation_controller.dart';

void main() {
  group('MapAnimationController', () {
    test('移動補間は 0% で移動元オフセット、100% で自動クリアされる', () {
      final controller = MapAnimationController();
      addTearDown(controller.dispose);

      controller.handleEvent(const MapAnimEvent(
        turnId: 1,
        eventType: MapAnimEventType.move,
        entityId: 0,
        fromX: 10,
        fromY: 5,
        toX: 11,
        toY: 5,
        param1: 42,
        param2: 64, // '@'
        param3: 0xFFFFFFFF,
      ));

      expect(controller.hasActiveAnimations, isTrue);
      final t0 = controller.getCellTransform(11, 5);
      expect(t0, isNotNull);
      expect(t0!.dx, closeTo(-1.0, 0.001));
      expect(t0.dy, closeTo(0.0, 0.001));
      expect(t0.fallbackTile, 42);
      expect(t0.fallbackChar, '@');
      expect(t0.fallbackColor, 0xFFFFFFFF);

      // 中間地点 (60ms / 120ms) では dx が -1.0 〜 0.0 の間、かつ軽い上下バウンスで dy < 0 になる
      controller.advance(const Duration(milliseconds: 60));
      final tMid = controller.getCellTransform(11, 5);
      expect(tMid, isNotNull);
      expect(tMid!.dx, greaterThan(-1.0));
      expect(tMid.dx, lessThan(0.0));
      expect(tMid.dy, lessThan(-0.05));
      expect(tMid.dy, greaterThan(-0.12));

      // 完了後 (計 125ms) は自動クリア
      controller.advance(const Duration(milliseconds: 65));
      expect(controller.hasActiveAnimations, isFalse);
      expect(controller.getCellTransform(11, 5), isNull);
    });

    test('ポールアーム等の 2 マス攻撃バンプでも方向ベクトル正規化により踏み込み幅が過大にならない', () {
      final controller = MapAnimationController();
      addTearDown(controller.dispose);

      controller.handleEvent(const MapAnimEvent(
        turnId: 1,
        eventType: MapAnimEventType.attack,
        entityId: 0,
        fromX: 10,
        fromY: 10,
        toX: 12,
        toY: 10,
        param1: 1, // 命中
      ));

      // 往路ピーク付近 (35% * 130ms ≈ 45ms)
      controller.advance(const Duration(milliseconds: 45));
      final attackerT = controller.getCellTransform(10, 10);
      expect(attackerT, isNotNull);
      expect(attackerT!.dx, greaterThan(0.25));
      expect(attackerT.dx, lessThanOrEqualTo(0.36));

      // 被弾側にフラッシュが出ていること
      final targetT = controller.getCellTransform(12, 10);
      expect(targetT, isNotNull);
      expect(targetT!.flashAlpha, greaterThan(0.0));
    });

    test('多段攻撃で命中後にミスが来ても既存の被弾フラッシュが消されない', () {
      final controller = MapAnimationController();
      addTearDown(controller.dispose);

      // 1撃目: 命中
      controller.handleEvent(const MapAnimEvent(
        turnId: 2,
        eventType: MapAnimEventType.attack,
        entityId: 42,
        fromX: 5,
        fromY: 5,
        toX: 6,
        toY: 5,
        param1: 1,
      ));
      // 2撃目: ミス
      controller.handleEvent(const MapAnimEvent(
        turnId: 2,
        eventType: MapAnimEventType.attack,
        entityId: 42,
        fromX: 5,
        fromY: 5,
        toX: 6,
        toY: 5,
        param1: 0,
      ));

      controller.advance(const Duration(milliseconds: 20));
      final targetT = controller.getCellTransform(6, 5);
      expect(targetT, isNotNull);
      expect(targetT!.flashAlpha, greaterThan(0.0));
    });

    test('死亡フェードアウトは不透明度が低下し完了後に消える', () {
      final controller = MapAnimationController();
      addTearDown(controller.dispose);

      controller.handleEvent(const MapAnimEvent(
        turnId: 3,
        eventType: MapAnimEventType.death,
        entityId: 99,
        fromX: 15,
        fromY: 8,
        toX: 15,
        toY: 8,
        param1: 120,
        param2: 103, // 'g'
        param3: 0xFF00FF00,
      ));

      expect(controller.activeDeathFades.length, 1);
      expect(controller.activeDeathFades.first.opacity, closeTo(1.0, 0.01));

      controller.advance(const Duration(milliseconds: 120));
      expect(controller.activeDeathFades.first.opacity, lessThan(1.0));
      expect(controller.activeDeathFades.first.scale, lessThan(1.0));

      controller.advance(const Duration(milliseconds: 130));
      expect(controller.activeDeathFades, isEmpty);
      expect(controller.hasActiveAnimations, isFalse);
    });

    test('連続する飛び道具イベントは 1 本のウェイポイント経路に連結される', () {
      final controller = MapAnimationController();
      addTearDown(controller.dispose);

      controller.handleEvent(const MapAnimEvent(
        turnId: 4,
        eventType: MapAnimEventType.projectile,
        entityId: 0,
        fromX: 10,
        fromY: 10,
        toX: 11,
        toY: 10,
        param1: 200,
        param2: 41, // ')'
        param3: 0xFFFFFFFF,
      ));
      controller.handleEvent(const MapAnimEvent(
        turnId: 4,
        eventType: MapAnimEventType.projectile,
        entityId: 0,
        fromX: 11,
        fromY: 10,
        toX: 12,
        toY: 10,
        param1: 200,
        param2: 41,
        param3: 0xFFFFFFFF,
      ));

      expect(controller.activeProjectiles.length, 1);
      expect(controller.activeProjectiles.first.x, closeTo(10.0, 0.01));

      // 2ステップ合計 110ms の半分 (55ms) でちょうど中間 (11.0)
      controller.advance(const Duration(milliseconds: 55));
      expect(controller.activeProjectiles.first.x, closeTo(11.0, 0.05));

      controller.advance(const Duration(milliseconds: 60));
      expect(controller.activeProjectiles, isEmpty);
    });

    test('snapAll() は全アニメーションを即クリアし、旧世代 turnId の遅延イベントを破棄する', () {
      final controller = MapAnimationController();
      addTearDown(controller.dispose);

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.handleEvent(const MapAnimEvent(
        turnId: 5,
        eventType: MapAnimEventType.move,
        entityId: 0,
        fromX: 10,
        fromY: 10,
        toX: 11,
        toY: 10,
      ));
      expect(controller.hasActiveAnimations, isTrue);

      notifyCount = 0;
      controller.snapAll(minAcceptedTurnId: 6);
      expect(controller.hasActiveAnimations, isFalse);
      expect(notifyCount, 1);

      // 既に空の状態で再度 snapAll しても不要な通知は飛ばない
      controller.snapAll(minAcceptedTurnId: 6);
      expect(notifyCount, 1);

      // turnId = 5 の遅延イベントは破棄される
      controller.handleEvent(const MapAnimEvent(
        turnId: 5,
        eventType: MapAnimEventType.move,
        entityId: 7,
        fromX: 20,
        fromY: 10,
        toX: 21,
        toY: 10,
      ));
      expect(controller.hasActiveAnimations, isFalse);

      // turnId = 6 のイベントは受理される
      controller.handleEvent(const MapAnimEvent(
        turnId: 6,
        eventType: MapAnimEventType.move,
        entityId: 7,
        fromX: 20,
        fromY: 10,
        toX: 21,
        toY: 10,
      ));
      expect(controller.hasActiveAnimations, isTrue);
    });

    test('速度プリセット fast/slow で所要時間が変わり、enabled=false 時は無動作になる', () {
      final fastCtrl = MapAnimationController(speed: MapAnimationSpeed.fast);
      final slowCtrl = MapAnimationController(speed: MapAnimationSpeed.slow);
      addTearDown(fastCtrl.dispose);
      addTearDown(slowCtrl.dispose);

      const moveEvt = MapAnimEvent(
        turnId: 1,
        eventType: MapAnimEventType.move,
        entityId: 0,
        fromX: 5,
        fromY: 5,
        toX: 6,
        toY: 5,
      );

      fastCtrl.handleEvent(moveEvt);
      slowCtrl.handleEvent(moveEvt);

      // fast は 120 * 0.58 ≈ 70ms で完了、normal は 120ms、slow は 120 * 2.0 = 240ms
      fastCtrl.advance(const Duration(milliseconds: 75));
      slowCtrl.advance(const Duration(milliseconds: 75));
      expect(fastCtrl.hasActiveAnimations, isFalse);
      expect(slowCtrl.hasActiveAnimations, isTrue);

      // slow は 200ms 経過時点でもまだ再生中、250ms 経過で完了
      slowCtrl.advance(const Duration(milliseconds: 125));
      expect(slowCtrl.hasActiveAnimations, isTrue);

      // enabled = false にすると即クリアされ新規イベントも無視される
      slowCtrl.enabled = false;
      expect(slowCtrl.hasActiveAnimations, isFalse);
      slowCtrl.handleEvent(moveEvt);
      expect(slowCtrl.hasActiveAnimations, isFalse);
    });

    test('通常岩押しはバウンスなしで移動補間し、消滅岩押しは移動先をマスクせず後半フェードする', () {
      final controller = MapAnimationController();
      addTearDown(controller.dispose);

      // 通常岩押し (entityId=1)
      controller.handleEvent(const MapAnimEvent(
        turnId: 10,
        eventType: MapAnimEventType.objectMove,
        entityId: MapObjectMoveKind.persistent,
        fromX: 5,
        fromY: 5,
        toX: 6,
        toY: 5,
        param1: 300,
        param2: 96, // '`'
        param3: 0xFFAAAAAA,
      ));
      controller.advance(const Duration(milliseconds: 60));
      final tBoulder = controller.getCellTransform(6, 5);
      expect(tBoulder, isNotNull);
      expect(tBoulder!.dx, greaterThan(-1.0));
      expect(tBoulder.dx, lessThan(0.0));
      // 岩押しはホップバウンスなし
      expect(tBoulder.dy, closeTo(0.0, 0.001));
      expect(controller.animatedCellKeys, contains(5 * 80 + 6));

      // 消滅岩押し (entityId=2)
      controller.handleEvent(const MapAnimEvent(
        turnId: 10,
        eventType: MapAnimEventType.objectMove,
        entityId: MapObjectMoveKind.vanishing,
        fromX: 10,
        fromY: 5,
        toX: 11,
        toY: 5,
        param1: 300,
        param2: 96,
        param3: 0xFFAAAAAA,
      ));
      expect(controller.animatedCellKeys, isNot(contains(5 * 80 + 11)));
      expect(controller.activeVanishingObjectMoves, hasLength(1));
      expect(controller.activeVanishingObjectMoves.first.opacity, closeTo(1.0, 0.01));

      // 後半 (100ms / 120ms ≈ 83%) で縮小＋フェードアウト
      controller.advance(const Duration(milliseconds: 100));
      expect(controller.activeVanishingObjectMoves, hasLength(1));
      expect(controller.activeVanishingObjectMoves.first.opacity, lessThan(0.8));
      expect(controller.activeVanishingObjectMoves.first.scale, lessThan(0.95));

      controller.advance(const Duration(milliseconds: 30));
      expect(controller.activeVanishingObjectMoves, isEmpty);
    });

    test('VFXパーティクル・光リングの上限クランプと爆発シェイク復帰が機能する', () {
      final controller = MapAnimationController();
      addTearDown(controller.dispose);

      // 爆発を連続発火してもパーティクル上限 80・リング上限 8 を超えない
      for (int i = 0; i < 10; i++) {
        controller.handleEvent(MapAnimEvent(
          turnId: 20,
          eventType: MapAnimEventType.vfx,
          entityId: MapVfxKind.explosion,
          fromX: 10 + i,
          fromY: 10,
          toX: 10 + i,
          toY: 10,
          param1: 0xFFFF7043,
          param2: 3,
        ));
      }

      expect(controller.activeParticles.length, lessThanOrEqualTo(80));
      expect(controller.activeRings.length, lessThanOrEqualTo(8));
      controller.advance(const Duration(milliseconds: 20));
      expect(controller.screenShakeNotifier.value, isNot(Offset.zero));

      // シェイク終了後に Offset.zero へ完全復帰
      controller.advance(const Duration(milliseconds: 150));
      expect(controller.screenShakeNotifier.value, Offset.zero);
    });

    test('フローティングテキストはアニメーションOFFでも独立動作し、同セル最大3件＋スタガー発射される', () {
      final controller = MapAnimationController(
        enabled: false,
        floatingTextEnabled: true,
        isJapanese: true,
      );
      addTearDown(controller.dispose);

      // アニメーションOFFでも移動イベントは無視されるが、フローティングテキストは受理される
      controller.handleEvent(const MapAnimEvent(
        turnId: 30,
        eventType: MapAnimEventType.move,
        entityId: 0,
        fromX: 5,
        fromY: 5,
        toX: 6,
        toY: 5,
      ));
      expect(controller.hasActiveAnimations, isFalse);

      // 同セル・同ターンに 4 件（MISS=低優先, 盲目=中, ダメージ=高, 石化=致死最優先）
      controller.handleEvent(const MapAnimEvent(
        turnId: 30,
        eventType: MapAnimEventType.floatingText,
        entityId: FloatingTextKind.miss,
        fromX: 6,
        fromY: 5,
        toX: 6,
        toY: 5,
      ));
      controller.handleEvent(const MapAnimEvent(
        turnId: 30,
        eventType: MapAnimEventType.floatingText,
        entityId: FloatingTextKind.statusGain,
        fromX: 6,
        fromY: 5,
        toX: 6,
        toY: 5,
        param1: StatusTextCode.blind,
      ));
      controller.handleEvent(const MapAnimEvent(
        turnId: 30,
        eventType: MapAnimEventType.floatingText,
        entityId: FloatingTextKind.dmgHero,
        fromX: 6,
        fromY: 5,
        toX: 6,
        toY: 5,
        param1: 14,
      ));
      controller.handleEvent(const MapAnimEvent(
        turnId: 30,
        eventType: MapAnimEventType.floatingText,
        entityId: FloatingTextKind.statusGain,
        fromX: 6,
        fromY: 5,
        toX: 6,
        toY: 5,
        param1: StatusTextCode.stoning,
      ));

      expect(controller.hasActiveAnimations, isTrue);
      // t=0 ではスタガー index=0 のみ表示、200ms 経過で全 3 件が表示され MISS は淘汰されている
      controller.advance(const Duration(milliseconds: 200));
      final texts = controller.activeFloatingTexts.map((e) => e.text).toList();
      expect(texts, hasLength(3));
      expect(texts, containsAll(['-14', '盲目', '石化!']));
      expect(texts, isNot(contains('MISS')));

      // floatingTextEnabled = false で即時消去
      controller.floatingTextEnabled = false;
      expect(controller.activeFloatingTexts, isEmpty);
      expect(controller.hasActiveAnimations, isFalse);
    });

    test('持続的な状態マイクロ演出はTickerを起動せず、snapAllで維持・fromX=-1でクリアされる', () {
      final controller = MapAnimationController(canLiftFloatingGlyph: true);
      addTearDown(controller.dispose);

      controller.handleEvent(const MapAnimEvent(
        turnId: 40,
        eventType: MapAnimEventType.ambientStatus,
        entityId: AmbientStatusBits.levitating | AmbientStatusBits.confused,
        fromX: 12,
        fromY: 8,
        toX: 12,
        toY: 8,
      ));

      // 持続状態のみの場合は hasActiveAnimations=false（Ticker停止）、hasAnyVisuals=true
      expect(controller.hasActiveAnimations, isFalse);
      expect(controller.hasAmbientStatuses, isTrue);
      expect(controller.hasAnyVisuals, isTrue);

      final tFloat = controller.getCellTransform(12, 8);
      expect(tFloat, isNotNull);
      expect(tFloat!.isFloating, isTrue);
      expect(tFloat.floatLiftDy, closeTo(-0.11, 0.001));

      // 非透過タイル時は上浮きさせない
      controller.canLiftFloatingGlyph = false;
      expect(controller.getCellTransform(12, 8), isNull);
      expect(controller.activeAmbientStatuses, hasLength(1));

      // snapAll() では持続状態は消えない
      controller.snapAll(minAcceptedTurnId: 41);
      expect(controller.hasAmbientStatuses, isTrue);

      // fromX = -1 で全クリア
      controller.handleEvent(const MapAnimEvent(
        turnId: 41,
        eventType: MapAnimEventType.ambientStatus,
        entityId: 0,
        fromX: -1,
        fromY: -1,
        toX: -1,
        toY: -1,
      ));
      expect(controller.hasAmbientStatuses, isFalse);
      expect(controller.hasAnyVisuals, isFalse);
    });
  });
}

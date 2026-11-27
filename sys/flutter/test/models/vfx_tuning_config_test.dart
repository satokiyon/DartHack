import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/map_animation_event.dart';
import 'package:darthack/models/vfx_tuning_config.dart';
import 'package:darthack/models/vfx_tuning_defaults.dart';
import 'package:darthack/utils/map_animation_controller.dart';

void main() {
  group('VfxTuningConfig serialization and presets', () {
    test('kDefaultVfxTuning は defaults() と完全一致し、JSONラウンドトリップが可逆である', () {
      final std = VfxTuningConfig.defaults();
      expect(kDefaultVfxTuning, equals(std));

      for (final preset in [
        VfxTuningConfig.defaults(),
        VfxTuningConfig.subtle(),
        VfxTuningConfig.vivid(),
      ]) {
        final json = preset.toJson();
        final restored = VfxTuningConfig.fromJson(json);
        expect(restored, equals(preset));
      }
    });

    test('欠損キーや不正型を含む部分JSONでもデフォルト値へ安全にフォールバックする', () {
      final partial = VfxTuningConfig.fromJson({
        'motion': {'moveMs': 200, 'moveHopHeightRatio': 'invalid'},
        'particles': {
          'dust': {'count': 15},
        },
      });
      expect(partial.motion.moveMs, 200);
      expect(partial.motion.moveHopHeightRatio, closeTo(0.09, 0.0001));
      expect(partial.particleOf('dust').count, 15);
      expect(partial.particleOf('explosion').count, 16);
    });

    test('toDartConstSource() は全粒子・全リング定義を含む定数コードを生成する', () {
      final custom = VfxTuningConfig.defaults().copyWith(
        summonDemonColor: 0xFFAA1122,
      );
      final src = custom.toDartConstSource();
      expect(src, contains('const VfxTuningConfig kDefaultVfxTuning = VfxTuningConfig('));
      expect(src, contains('summonDemonColor: 0xFFAA1122,'));
      for (final k in VfxTuningConfig.particleKeys) {
        expect(src, contains("'$k': ParticleEffectTuning("));
      }
      for (final k in VfxTuningConfig.ringKeys) {
        expect(src, contains("'$k': RingEffectTuning("));
      }
    });
  });

  group('MapAnimationController tuning integration', () {
    test('カスタム moveMs・テレポート発着2リング・召喚3種色・9カテゴリ状態色が反映される', () {
      final custom = VfxTuningConfig.defaults().copyWith(
        motion: const MotionTuning(moveMs: 220),
        summonNormalColor: 0xFF112233,
        summonDemonColor: 0xFFDD2200,
        summonAngelColor: 0xFFFFEE00,
        floatingText: const FloatingTextTuning(statusLethalColor: 0xFF9900FF),
      );
      final ctrl = MapAnimationController(tuning: custom);
      addTearDown(ctrl.dispose);

      // 1. カスタム moveMs (220ms) では 150ms 時点でもまだ移動継続中
      ctrl.handleEvent(const MapAnimEvent(
        turnId: 1,
        eventType: MapAnimEventType.move,
        entityId: 0,
        fromX: 10,
        fromY: 10,
        toX: 11,
        toY: 10,
      ));
      ctrl.advance(const Duration(milliseconds: 150));
      expect(ctrl.hasActiveAnimations, isTrue);
      ctrl.advance(const Duration(milliseconds: 80));
      expect(ctrl.hasActiveAnimations, isFalse);

      // 2. テレポート (from != to) は出発地と到着地の 2 個のリングを生成する
      ctrl.handleEvent(const MapAnimEvent(
        turnId: 2,
        eventType: MapAnimEventType.vfx,
        entityId: MapVfxKind.teleport,
        fromX: 5,
        fromY: 5,
        toX: 12,
        toY: 8,
      ));
      expect(ctrl.activeRings, hasLength(2));

      // 3. 召喚サブタイプ色 (悪魔 param2=1) と幻覚動的色 (param1 != 0) の切り替え
      ctrl.snapAll(minAcceptedTurnId: 3);
      ctrl.handleEvent(const MapAnimEvent(
        turnId: 3,
        eventType: MapAnimEventType.vfx,
        entityId: MapVfxKind.summon,
        fromX: 10,
        fromY: 10,
        toX: 10,
        toY: 10,
        param1: 0,
        param2: 1, // 悪魔召喚
      ));
      expect(ctrl.activeRings.single.color, const Color(0xFFDD2200));

      ctrl.snapAll(minAcceptedTurnId: 4);
      ctrl.handleEvent(const MapAnimEvent(
        turnId: 4,
        eventType: MapAnimEventType.vfx,
        entityId: MapVfxKind.summon,
        fromX: 10,
        fromY: 10,
        toX: 10,
        toY: 10,
        param1: 0xFF00FFAA, // 幻覚ランダム色
        param2: 1,
      ));
      expect(ctrl.activeRings.single.color, const Color(0xFF00FFAA));

      // 4. 状態変化テキストの 9 カテゴリパレット反映
      ctrl.handleEvent(const MapAnimEvent(
        turnId: 4,
        eventType: MapAnimEventType.floatingText,
        entityId: FloatingTextKind.statusGain,
        fromX: 10,
        fromY: 10,
        toX: 10,
        toY: 10,
        param1: StatusTextCode.stoning,
      ));
      expect(ctrl.activeFloatingTexts.single.color, const Color(0xFF9900FF));
    });
  });
}

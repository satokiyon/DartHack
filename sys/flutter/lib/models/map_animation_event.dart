import 'package:flutter/material.dart';
import 'vfx_tuning_config.dart';

/// マップアニメーションの再生速度プリセット
enum MapAnimationSpeed {
  fast(0.58, 0, 'fast'),
  normal(1.0, 1, 'normal'),
  slow(2.0, 2, 'slow');

  /// 基準時間に乗じる倍率
  final double multiplier;

  /// C コア FFI へ渡す数値コード
  final int cMode;

  /// AppPrefs 保存用文字列
  final String prefValue;

  const MapAnimationSpeed(this.multiplier, this.cMode, this.prefValue);

  static MapAnimationSpeed fromPref(String? value) {
    switch (value) {
      case 'fast':
        return MapAnimationSpeed.fast;
      case 'slow':
        return MapAnimationSpeed.slow;
      default:
        return MapAnimationSpeed.normal;
    }
  }
}

/// アニメーション種別定数（winflutter.c の DartAnimEventCallback と一致）
abstract final class MapAnimEventType {
  static const int move = 1;
  static const int attack = 2;
  static const int death = 3;
  static const int projectile = 4;
  static const int objectMove = 5;
  static const int vfx = 6;
  static const int floatingText = 7;
  static const int ambientStatus = 8;
}

/// 岩押しなどのオブジェクト移動種別（eventType == objectMove の entityId）
abstract final class MapObjectMoveKind {
  /// 移動先にオブジェクトが残る通常押し出し（移動先を背景マスクして補間）
  static const int persistent = 1;

  /// 落とし穴・穴埋め・水没・テレポ罠などで移動先から消滅する押し出し
  static const int vanishing = 2;
}

/// パーティクル・光リング・画面シェイク VFX 種別（eventType == vfx の entityId）
abstract final class MapVfxKind {
  static const int dust = 1;
  static const int woodDebris = 2;
  static const int rockDebris = 3;
  static const int potionSplash = 4;
  static const int explosion = 5;
  static const int teleport = 6;
  static const int levelUp = 7;
  static const int summon = 8;
  static const int kickImpact = 9;
  static const int bigHitShake = 10;
}

/// フローティングテキスト種別（eventType == floatingText の entityId）
abstract final class FloatingTextKind {
  static const int dmgHero = 1;
  static const int dmgMon = 2;
  static const int miss = 3;
  static const int healHp = 4;
  static const int healPw = 5;
  static const int levelUp = 6;
  static const int statusGain = 7;
}

/// 状態変化フローティングテキストのコード定義（winflutter.c の StatusTextCode と一致）
abstract final class StatusTextCode {
  // 致死危機 (1..7)
  static const int stoning = 1;
  static const int slimed = 2;
  static const int strangled = 3;
  static const int foodPoisoning = 4;
  static const int terminalIllness = 5;
  static const int grabbed = 6;
  static const int inLava = 7;

  // 感覚・阻害 (10..25)
  static const int blind = 10;
  static const int deaf = 11;
  static const int confused = 12;
  static const int stunned = 13;
  static const int hallucinating = 14;
  static const int paralyzed = 15;
  static const int asleep = 16;
  static const int unconscious = 17;
  static const int engulfed = 18;
  static const int held = 19;
  static const int trapped = 20;
  static const int punished = 21;
  static const int slippery = 22;
  static const int woundedLegs = 23;
  static const int submerged = 24;
  static const int ironSensitive = 25;

  // 空腹 (30..35)
  static const int satiated = 30;
  static const int hungry = 31;
  static const int weak = 32;
  static const int fainting = 33;
  static const int fainted = 34;
  static const int starved = 35;

  // 荷重 (40..44)
  static const int burdened = 40;
  static const int stressed = 41;
  static const int strained = 42;
  static const int overtaxed = 43;
  static const int overloaded = 44;

  // 移動・強化 (50..56)
  static const int levitating = 50;
  static const int flying = 51;
  static const int riding = 52;
  static const int glowingHands = 53;
  static const int fast = 54;
  static const int invisible = 55;
  static const int holding = 56;

  // モンスター専用 (60..61)
  static const int fleeing = 60;
  static const int slowed = 61;

  /// コードと表示言語に応じた短いラベル文字列を返す
  static String? resolveLabel(int code, {required bool isJapanese}) {
    switch (code) {
      case stoning:
        return isJapanese ? '石化!' : 'Stoning!';
      case slimed:
        return isJapanese ? '粘液化!' : 'Slimed!';
      case strangled:
        return isJapanese ? '窒息!' : 'Strangled!';
      case foodPoisoning:
        return isJapanese ? '食中毒!' : 'Food Pois!';
      case terminalIllness:
        return isJapanese ? '病気!' : 'Ill!';
      case grabbed:
        return isJapanese ? '捕縛!' : 'Grabbed!';
      case inLava:
        return isJapanese ? '溶岩!' : 'In Lava!';
      case blind:
        return isJapanese ? '盲目' : 'Blind';
      case deaf:
        return isJapanese ? '難聴' : 'Deaf';
      case confused:
        return isJapanese ? '混乱' : 'Confused';
      case stunned:
        return isJapanese ? '朦朧' : 'Stunned';
      case hallucinating:
        return isJapanese ? '幻覚' : 'Hallu';
      case paralyzed:
        return isJapanese ? '麻痺' : 'Paralyzed';
      case asleep:
        return isJapanese ? '睡眠' : 'Asleep';
      case unconscious:
        return isJapanese ? '失神' : 'Unconscious';
      case engulfed:
        return isJapanese ? '丸呑み' : 'Engulfed';
      case held:
        return isJapanese ? '拘束' : 'Held';
      case trapped:
        return isJapanese ? '罠拘束' : 'Trapped';
      case punished:
        return isJapanese ? '懲罰' : 'Punished';
      case slippery:
        return isJapanese ? '滑手' : 'Slippery';
      case woundedLegs:
        return isJapanese ? '脚傷' : 'Wounded Legs';
      case submerged:
        return isJapanese ? '水没' : 'Submerged';
      case ironSensitive:
        return isJapanese ? '鉄過敏' : 'Iron';
      case satiated:
        return isJapanese ? '満腹' : 'Satiated';
      case hungry:
        return isJapanese ? '空腹' : 'Hungry';
      case weak:
        return isJapanese ? '衰弱' : 'Weak';
      case fainting:
        return isJapanese ? '失神寸前' : 'Fainting';
      case fainted:
        return isJapanese ? '失神' : 'Fainted';
      case starved:
        return isJapanese ? '飢餓!' : 'Starved!';
      case burdened:
        return isJapanese ? '重荷' : 'Burdened';
      case stressed:
        return isJapanese ? '圧迫' : 'Stressed';
      case strained:
        return isJapanese ? '過重' : 'Strained';
      case overtaxed:
        return isJapanese ? '超過重' : 'Overtaxed';
      case overloaded:
        return isJapanese ? '過積載!' : 'Overloaded!';
      case levitating:
        return isJapanese ? '浮遊' : 'Levitating';
      case flying:
        return isJapanese ? '飛行' : 'Flying';
      case riding:
        return isJapanese ? '騎乗' : 'Riding';
      case glowingHands:
        return isJapanese ? '発光' : 'Glowing Hands';
      case fast:
        return isJapanese ? '加速' : 'Fast';
      case invisible:
        return isJapanese ? '透明' : 'Invisible';
      case holding:
        return isJapanese ? '保持' : 'Holding';
      case fleeing:
        return isJapanese ? '逃走' : 'Fleeing';
      case slowed:
        return isJapanese ? '減速' : 'Slowed';
      default:
        return null;
    }
  }

  /// 状態種別に応じた視認性の高い表示色を返す（[tuning] 指定時は9カテゴリパレットを適用）
  static Color resolveColor(int code, {FloatingTextTuning? tuning}) {
    final t = tuning ?? const FloatingTextTuning();
    Color c(int argb) => Color(argb | 0xFF000000);
    switch (code) {
      case stoning:
      case strangled:
      case grabbed:
      case fainted:
      case starved:
      case overloaded:
        return c(t.statusLethalColor);
      case slimed:
        return c(t.statusSlimeColor);
      case foodPoisoning:
      case terminalIllness:
        return c(t.statusSicknessColor);
      case inLava:
      case engulfed:
      case overtaxed:
        return c(t.statusDangerColor);
      case confused:
      case stunned:
      case hallucinating:
        return c(t.statusMentalColor);
      case paralyzed:
      case asleep:
      case unconscious:
      case fleeing:
        return c(t.statusImmobilizeColor);
      case held:
      case trapped:
      case woundedLegs:
      case fainting:
      case strained:
      case hungry:
      case weak:
      case burdened:
      case stressed:
        return c(t.statusImpairColor);
      case blind:
      case deaf:
      case punished:
      case ironSensitive:
      case slippery:
      case submerged:
      case levitating:
      case flying:
      case invisible:
        return c(t.statusMovementColor);
      case satiated:
      case riding:
      case fast:
      case holding:
      case glowingHands:
      case slowed:
        return c(t.statusBuffColor);
      default:
        return Colors.white;
    }
  }

  /// 同一セル・同一ターンで同時発生した際の優先度（高いほど優先表示）
  static int resolvePriority(int code) {
    if (code >= stoning && code <= inLava) return 100;
    if (code == starved || code == fainted) return 85;
    if (code == overloaded || code == fainting) return 75;
    if (code >= blind && code <= ironSensitive) return 60;
    if (code == fleeing || code == slowed) return 55;
    if (code >= satiated && code <= weak) return 50;
    if (code >= burdened && code <= overtaxed) return 45;
    return 40;
  }
}

/// 持続的な状態マイクロ演出ビット（eventType == ambientStatus の entityId、11ビット）
abstract final class AmbientStatusBits {
  static const int sleep = 0x0001;
  static const int paralyzed = 0x0002;
  static const int confused = 0x0004;
  static const int stunned = 0x0008;
  static const int levitating = 0x0010;
  static const int stoning = 0x0020;
  static const int slimed = 0x0040;
  static const int sick = 0x0080;
  static const int strangledOrLava = 0x0100;
  static const int confusingHands = 0x0200;
  static const int fleeing = 0x0400;
}

/// 基準時間定義（標準速度時、ミリ秒）
///
/// 移動とカメラ追従を同一時間（120ms: 速い 70ms / 標準 120ms / 遅い 240ms）で
/// 完全同期させ、画面酔いを防ぎつつ視認性の高い滑らかな動きを実現する。
abstract final class MapAnimDurations {
  static const int moveMs = 120;
  static const int attackBumpMs = 140;
  static const int hitFeedbackMs = 160;
  static const int deathFadeMs = 240;
  static const int projectileStepMs = 55;
  static const int projectileMaxTotalMs = 260;
  static const int cameraFollowMs = 120;
  static const int particleMs = 260;
  static const int ringMs = 280;
  static const int floatingTextMs = 680;
  static const int floatingTextStaggerMs = 80;
  static const int screenShakeMs = 110;
}

/// C コア（Worker Isolate 経由）から受け取るアニメーションイベント
class MapAnimEvent {
  final int turnId;
  final int eventType;
  final int entityId;
  final int fromX;
  final int fromY;
  final int toX;
  final int toY;
  final int param1;
  final int param2;
  final int param3;

  const MapAnimEvent({
    required this.turnId,
    required this.eventType,
    required this.entityId,
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    this.param1 = 0,
    this.param2 = 0,
    this.param3 = 0,
  });

  factory MapAnimEvent.fromWorkerMap(Map<dynamic, dynamic> map) {
    return MapAnimEvent(
      turnId: (map['turnId'] as int?) ?? 0,
      eventType: (map['eventType'] as int?) ?? 0,
      entityId: (map['entityId'] as int?) ?? 0,
      fromX: (map['fromX'] as int?) ?? 0,
      fromY: (map['fromY'] as int?) ?? 0,
      toX: (map['toX'] as int?) ?? 0,
      toY: (map['toY'] as int?) ?? 0,
      param1: (map['param1'] as int?) ?? 0,
      param2: (map['param2'] as int?) ?? 0,
      param3: (map['param3'] as int?) ?? 0,
    );
  }
}

/// セル上のエンティティに適用される現在フレームの変換状態
class CellAnimTransform {
  /// 移動・バンプ・被弾揺れによる X 方向オフセット比率（-1.0 で 1 マス左）
  final double moveDx;

  /// 移動・バンプ・ホップによる Y 方向オフセット比率（-1.0 で 1 マス上）
  final double moveDy;

  /// 浮遊・飛行状態による上浮き Y オフセット比率（通常 -0.11、非浮遊時は 0.0）
  final double floatLiftDy;

  /// 浮遊・飛行状態として上浮き＆足元影を描画するかどうか
  final bool isFloating;

  /// 被弾フラッシュ強度（0.0 〜 1.0）
  final double flashAlpha;

  /// 被弾フラッシュ色
  final Color flashColor;

  /// `printGlyph` 未到着の先行フレームでも描画するためのフォールバックタイル ID
  final int? fallbackTile;

  /// `printGlyph` 未到着の先行フレームでも描画するためのフォールバック文字
  final String? fallbackChar;

  /// `printGlyph` 未到着の先行フレームでも描画するためのフォールバック ARGB 色
  final int? fallbackColor;

  /// 合計 X オフセット比率（移動・バンプ・被弾）
  double get dx => moveDx;

  /// 合計 Y オフセット比率（移動・バンプ＋浮遊上浮き）
  double get dy => moveDy + floatLiftDy;

  const CellAnimTransform({
    this.moveDx = 0.0,
    this.moveDy = 0.0,
    this.floatLiftDy = 0.0,
    this.isFloating = false,
    this.flashAlpha = 0.0,
    this.flashColor = Colors.white,
    this.fallbackTile,
    this.fallbackChar,
    this.fallbackColor,
  });
}

/// 死亡フェードアウト描画用スナップショット
class DeathFadeSnapshot {
  final int x;
  final int y;
  final int tile;
  final String char;
  final int color;
  final double opacity;
  final double scale;

  const DeathFadeSnapshot({
    required this.x,
    required this.y,
    required this.tile,
    required this.char,
    required this.color,
    required this.opacity,
    required this.scale,
  });
}

/// 穴埋め・水没・テレポ罠などで消滅するオブジェクト移動描画用スナップショット
class VanishingObjectMoveSnapshot {
  final double x;
  final double y;
  final int tile;
  final String char;
  final int color;
  final double opacity;
  final double scale;

  const VanishingObjectMoveSnapshot({
    required this.x,
    required this.y,
    required this.tile,
    required this.char,
    required this.color,
    required this.opacity,
    required this.scale,
  });
}

/// 飛び道具・光線描画用スナップショット
class ProjectileSnapshot {
  /// 補間済みのマップセル座標 X（小数）
  final double x;

  /// 補間済みのマップセル座標 Y（小数）
  final double y;

  final int tile;
  final String char;
  final int color;

  const ProjectileSnapshot({
    required this.x,
    required this.y,
    required this.tile,
    required this.char,
    required this.color,
  });
}

/// ドット粒・発光粒パーティクル描画用スナップショット
class ParticleSnapshot {
  /// マップセル座標系での中心 X（小数）
  final double x;

  /// マップセル座標系での中心 Y（小数）
  final double y;

  /// セル幅に対する粒子サイズ比率
  final double sizeRatio;

  final Color color;
  final double opacity;

  /// 発光粒として外周ソフトハロー（非 blur の半透明円）を伴うかどうか
  final bool isGlow;

  const ParticleSnapshot({
    required this.x,
    required this.y,
    required this.sizeRatio,
    required this.color,
    required this.opacity,
    this.isGlow = false,
  });
}

/// 同心円光リング VFX 描画用スナップショット
class RingEffectSnapshot {
  /// マップセル座標系での中心 X（小数）
  final double x;

  /// マップセル座標系での中心 Y（小数）
  final double y;

  /// セル幅基準の現在半径
  final double radiusCells;

  /// 線の太さ比率（セル幅基準）
  final double strokeRatio;

  final Color color;
  final double opacity;

  const RingEffectSnapshot({
    required this.x,
    required this.y,
    required this.radiusCells,
    required this.strokeRatio,
    required this.color,
    required this.opacity,
  });
}

/// フローティングテキスト描画用スナップショット
class FloatingTextSnapshot {
  final int x;
  final int y;
  final String text;
  final Color color;
  final double opacity;
  final double scale;

  /// セル高さに対する上方向オフセット比率（負値で上方向）
  final double yOffsetCells;

  const FloatingTextSnapshot({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    required this.opacity,
    required this.scale,
    required this.yOffsetCells,
  });
}

/// セル上の持続的な状態マイクロ演出スナップショット
class AmbientCellStatusSnapshot {
  final int x;
  final int y;
  final int mask;
  final double phase;
  final double moveDx;
  final double moveDy;

  const AmbientCellStatusSnapshot({
    required this.x,
    required this.y,
    required this.mask,
    required this.phase,
    this.moveDx = 0.0,
    this.moveDy = 0.0,
  });
}

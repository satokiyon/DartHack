import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 移動・近接戦闘・死亡・飛び道具・カメラ追従の時間およびイージング量設定
@immutable
class MotionTuning {
  final int moveMs;
  final double moveHopHeightRatio;
  final int attackBumpMs;
  final double attackBumpDistance;
  final int hitFeedbackMs;
  final double hitShakeRatio;
  final double hitFlashAlpha;
  final int hitFlashColor;
  final int deathFadeMs;
  final double deathEndScale;
  final int projectileStepMs;
  final int projectileMaxTotalMs;
  final int cameraFollowMs;
  final double vanishFadeStartT;
  final double vanishEndScale;
  final double speedFastMultiplier;
  final double speedNormalMultiplier;
  final double speedSlowMultiplier;

  const MotionTuning({
    this.moveMs = 120,
    this.moveHopHeightRatio = 0.09,
    this.attackBumpMs = 140,
    this.attackBumpDistance = 0.35,
    this.hitFeedbackMs = 160,
    this.hitShakeRatio = 0.14,
    this.hitFlashAlpha = 0.65,
    this.hitFlashColor = 0xFFFF5252,
    this.deathFadeMs = 240,
    this.deathEndScale = 0.65,
    this.projectileStepMs = 55,
    this.projectileMaxTotalMs = 260,
    this.cameraFollowMs = 120,
    this.vanishFadeStartT = 0.65,
    this.vanishEndScale = 0.55,
    this.speedFastMultiplier = 0.58,
    this.speedNormalMultiplier = 1.0,
    this.speedSlowMultiplier = 2.0,
  });

  /// `MapAnimationSpeed.cMode` (`0: fast, 1: normal, 2: slow`) に対応する速度倍率を返す
  double multiplierForMode(int cMode) {
    switch (cMode) {
      case 0:
        return speedFastMultiplier;
      case 2:
        return speedSlowMultiplier;
      default:
        return speedNormalMultiplier;
    }
  }

  MotionTuning copyWith({
    int? moveMs,
    double? moveHopHeightRatio,
    int? attackBumpMs,
    double? attackBumpDistance,
    int? hitFeedbackMs,
    double? hitShakeRatio,
    double? hitFlashAlpha,
    int? hitFlashColor,
    int? deathFadeMs,
    double? deathEndScale,
    int? projectileStepMs,
    int? projectileMaxTotalMs,
    int? cameraFollowMs,
    double? vanishFadeStartT,
    double? vanishEndScale,
    double? speedFastMultiplier,
    double? speedNormalMultiplier,
    double? speedSlowMultiplier,
  }) {
    return MotionTuning(
      moveMs: moveMs ?? this.moveMs,
      moveHopHeightRatio: moveHopHeightRatio ?? this.moveHopHeightRatio,
      attackBumpMs: attackBumpMs ?? this.attackBumpMs,
      attackBumpDistance: attackBumpDistance ?? this.attackBumpDistance,
      hitFeedbackMs: hitFeedbackMs ?? this.hitFeedbackMs,
      hitShakeRatio: hitShakeRatio ?? this.hitShakeRatio,
      hitFlashAlpha: hitFlashAlpha ?? this.hitFlashAlpha,
      hitFlashColor: hitFlashColor ?? this.hitFlashColor,
      deathFadeMs: deathFadeMs ?? this.deathFadeMs,
      deathEndScale: deathEndScale ?? this.deathEndScale,
      projectileStepMs: projectileStepMs ?? this.projectileStepMs,
      projectileMaxTotalMs: projectileMaxTotalMs ?? this.projectileMaxTotalMs,
      cameraFollowMs: cameraFollowMs ?? this.cameraFollowMs,
      vanishFadeStartT: vanishFadeStartT ?? this.vanishFadeStartT,
      vanishEndScale: vanishEndScale ?? this.vanishEndScale,
      speedFastMultiplier: speedFastMultiplier ?? this.speedFastMultiplier,
      speedNormalMultiplier: speedNormalMultiplier ?? this.speedNormalMultiplier,
      speedSlowMultiplier: speedSlowMultiplier ?? this.speedSlowMultiplier,
    );
  }

  Map<String, dynamic> toJson() => {
        'moveMs': moveMs,
        'moveHopHeightRatio': moveHopHeightRatio,
        'attackBumpMs': attackBumpMs,
        'attackBumpDistance': attackBumpDistance,
        'hitFeedbackMs': hitFeedbackMs,
        'hitShakeRatio': hitShakeRatio,
        'hitFlashAlpha': hitFlashAlpha,
        'hitFlashColor': hitFlashColor,
        'deathFadeMs': deathFadeMs,
        'deathEndScale': deathEndScale,
        'projectileStepMs': projectileStepMs,
        'projectileMaxTotalMs': projectileMaxTotalMs,
        'cameraFollowMs': cameraFollowMs,
        'vanishFadeStartT': vanishFadeStartT,
        'vanishEndScale': vanishEndScale,
        'speedFastMultiplier': speedFastMultiplier,
        'speedNormalMultiplier': speedNormalMultiplier,
        'speedSlowMultiplier': speedSlowMultiplier,
      };

  factory MotionTuning.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MotionTuning();
    const d = MotionTuning();
    return MotionTuning(
      moveMs: _readInt(json, 'moveMs', d.moveMs),
      moveHopHeightRatio: _readDouble(json, 'moveHopHeightRatio', d.moveHopHeightRatio),
      attackBumpMs: _readInt(json, 'attackBumpMs', d.attackBumpMs),
      attackBumpDistance: _readDouble(json, 'attackBumpDistance', d.attackBumpDistance),
      hitFeedbackMs: _readInt(json, 'hitFeedbackMs', d.hitFeedbackMs),
      hitShakeRatio: _readDouble(json, 'hitShakeRatio', d.hitShakeRatio),
      hitFlashAlpha: _readDouble(json, 'hitFlashAlpha', d.hitFlashAlpha),
      hitFlashColor: _readInt(json, 'hitFlashColor', d.hitFlashColor),
      deathFadeMs: _readInt(json, 'deathFadeMs', d.deathFadeMs),
      deathEndScale: _readDouble(json, 'deathEndScale', d.deathEndScale),
      projectileStepMs: _readInt(json, 'projectileStepMs', d.projectileStepMs),
      projectileMaxTotalMs: _readInt(json, 'projectileMaxTotalMs', d.projectileMaxTotalMs),
      cameraFollowMs: _readInt(json, 'cameraFollowMs', d.cameraFollowMs),
      vanishFadeStartT: _readDouble(json, 'vanishFadeStartT', d.vanishFadeStartT),
      vanishEndScale: _readDouble(json, 'vanishEndScale', d.vanishEndScale),
      speedFastMultiplier: _readDouble(json, 'speedFastMultiplier', d.speedFastMultiplier),
      speedNormalMultiplier: _readDouble(json, 'speedNormalMultiplier', d.speedNormalMultiplier),
      speedSlowMultiplier: _readDouble(json, 'speedSlowMultiplier', d.speedSlowMultiplier),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MotionTuning &&
          moveMs == other.moveMs &&
          moveHopHeightRatio == other.moveHopHeightRatio &&
          attackBumpMs == other.attackBumpMs &&
          attackBumpDistance == other.attackBumpDistance &&
          hitFeedbackMs == other.hitFeedbackMs &&
          hitShakeRatio == other.hitShakeRatio &&
          hitFlashAlpha == other.hitFlashAlpha &&
          hitFlashColor == other.hitFlashColor &&
          deathFadeMs == other.deathFadeMs &&
          deathEndScale == other.deathEndScale &&
          projectileStepMs == other.projectileStepMs &&
          projectileMaxTotalMs == other.projectileMaxTotalMs &&
          cameraFollowMs == other.cameraFollowMs &&
          vanishFadeStartT == other.vanishFadeStartT &&
          vanishEndScale == other.vanishEndScale &&
          speedFastMultiplier == other.speedFastMultiplier &&
          speedNormalMultiplier == other.speedNormalMultiplier &&
          speedSlowMultiplier == other.speedSlowMultiplier;

  @override
  int get hashCode => Object.hashAll([
        moveMs,
        moveHopHeightRatio,
        attackBumpMs,
        attackBumpDistance,
        hitFeedbackMs,
        hitShakeRatio,
        hitFlashAlpha,
        hitFlashColor,
        deathFadeMs,
        deathEndScale,
        projectileStepMs,
        projectileMaxTotalMs,
        cameraFollowMs,
        vanishFadeStartT,
        vanishEndScale,
        speedFastMultiplier,
        speedNormalMultiplier,
        speedSlowMultiplier,
      ]);
}

/// 単一種類のパーティクル発生パラメータ
@immutable
class ParticleEffectTuning {
  final int count;
  final double speedMin;
  final double speedMax;
  final double gravity;
  final double sizeMin;
  final double sizeMax;
  final int durationMs;
  final bool isGlow;
  final int defaultColor;

  const ParticleEffectTuning({
    required this.count,
    required this.speedMin,
    required this.speedMax,
    required this.gravity,
    required this.sizeMin,
    required this.sizeMax,
    required this.durationMs,
    required this.isGlow,
    required this.defaultColor,
  });

  ParticleEffectTuning copyWith({
    int? count,
    double? speedMin,
    double? speedMax,
    double? gravity,
    double? sizeMin,
    double? sizeMax,
    int? durationMs,
    bool? isGlow,
    int? defaultColor,
  }) {
    return ParticleEffectTuning(
      count: count ?? this.count,
      speedMin: speedMin ?? this.speedMin,
      speedMax: speedMax ?? this.speedMax,
      gravity: gravity ?? this.gravity,
      sizeMin: sizeMin ?? this.sizeMin,
      sizeMax: sizeMax ?? this.sizeMax,
      durationMs: durationMs ?? this.durationMs,
      isGlow: isGlow ?? this.isGlow,
      defaultColor: defaultColor ?? this.defaultColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'speedMin': speedMin,
        'speedMax': speedMax,
        'gravity': gravity,
        'sizeMin': sizeMin,
        'sizeMax': sizeMax,
        'durationMs': durationMs,
        'isGlow': isGlow,
        'defaultColor': defaultColor,
      };

  factory ParticleEffectTuning.fromJson(
    Map<String, dynamic>? json,
    ParticleEffectTuning fallback,
  ) {
    if (json == null) return fallback;
    return ParticleEffectTuning(
      count: _readInt(json, 'count', fallback.count),
      speedMin: _readDouble(json, 'speedMin', fallback.speedMin),
      speedMax: _readDouble(json, 'speedMax', fallback.speedMax),
      gravity: _readDouble(json, 'gravity', fallback.gravity),
      sizeMin: _readDouble(json, 'sizeMin', fallback.sizeMin),
      sizeMax: _readDouble(json, 'sizeMax', fallback.sizeMax),
      durationMs: _readInt(json, 'durationMs', fallback.durationMs),
      isGlow: _readBool(json, 'isGlow', fallback.isGlow),
      defaultColor: _readInt(json, 'defaultColor', fallback.defaultColor),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleEffectTuning &&
          count == other.count &&
          speedMin == other.speedMin &&
          speedMax == other.speedMax &&
          gravity == other.gravity &&
          sizeMin == other.sizeMin &&
          sizeMax == other.sizeMax &&
          durationMs == other.durationMs &&
          isGlow == other.isGlow &&
          defaultColor == other.defaultColor;

  @override
  int get hashCode => Object.hash(
        count,
        speedMin,
        speedMax,
        gravity,
        sizeMin,
        sizeMax,
        durationMs,
        isGlow,
        defaultColor,
      );
}

/// 単一種類の同心円光リング発生パラメータ
@immutable
class RingEffectTuning {
  final double startRadiusCells;
  final double endRadiusCells;
  final double strokeRatio;
  final int durationMs;
  final int color;

  const RingEffectTuning({
    required this.startRadiusCells,
    required this.endRadiusCells,
    required this.strokeRatio,
    required this.durationMs,
    required this.color,
  });

  RingEffectTuning copyWith({
    double? startRadiusCells,
    double? endRadiusCells,
    double? strokeRatio,
    int? durationMs,
    int? color,
  }) {
    return RingEffectTuning(
      startRadiusCells: startRadiusCells ?? this.startRadiusCells,
      endRadiusCells: endRadiusCells ?? this.endRadiusCells,
      strokeRatio: strokeRatio ?? this.strokeRatio,
      durationMs: durationMs ?? this.durationMs,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'startRadiusCells': startRadiusCells,
        'endRadiusCells': endRadiusCells,
        'strokeRatio': strokeRatio,
        'durationMs': durationMs,
        'color': color,
      };

  factory RingEffectTuning.fromJson(
    Map<String, dynamic>? json,
    RingEffectTuning fallback,
  ) {
    if (json == null) return fallback;
    return RingEffectTuning(
      startRadiusCells: _readDouble(json, 'startRadiusCells', fallback.startRadiusCells),
      endRadiusCells: _readDouble(json, 'endRadiusCells', fallback.endRadiusCells),
      strokeRatio: _readDouble(json, 'strokeRatio', fallback.strokeRatio),
      durationMs: _readInt(json, 'durationMs', fallback.durationMs),
      color: _readInt(json, 'color', fallback.color),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RingEffectTuning &&
          startRadiusCells == other.startRadiusCells &&
          endRadiusCells == other.endRadiusCells &&
          strokeRatio == other.strokeRatio &&
          durationMs == other.durationMs &&
          color == other.color;

  @override
  int get hashCode => Object.hash(
        startRadiusCells,
        endRadiusCells,
        strokeRatio,
        durationMs,
        color,
      );
}

/// パーティクル・リング・フローティングテキストの同時上限キャップ
@immutable
class VfxLimitsTuning {
  final int maxParticles;
  final int maxRings;
  final int maxFloatingTexts;
  final int maxFloatingTextsPerCellTurn;

  const VfxLimitsTuning({
    this.maxParticles = 80,
    this.maxRings = 8,
    this.maxFloatingTexts = 20,
    this.maxFloatingTextsPerCellTurn = 3,
  });

  VfxLimitsTuning copyWith({
    int? maxParticles,
    int? maxRings,
    int? maxFloatingTexts,
    int? maxFloatingTextsPerCellTurn,
  }) {
    return VfxLimitsTuning(
      maxParticles: maxParticles ?? this.maxParticles,
      maxRings: maxRings ?? this.maxRings,
      maxFloatingTexts: maxFloatingTexts ?? this.maxFloatingTexts,
      maxFloatingTextsPerCellTurn:
          maxFloatingTextsPerCellTurn ?? this.maxFloatingTextsPerCellTurn,
    );
  }

  Map<String, dynamic> toJson() => {
        'maxParticles': maxParticles,
        'maxRings': maxRings,
        'maxFloatingTexts': maxFloatingTexts,
        'maxFloatingTextsPerCellTurn': maxFloatingTextsPerCellTurn,
      };

  factory VfxLimitsTuning.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VfxLimitsTuning();
    const d = VfxLimitsTuning();
    return VfxLimitsTuning(
      maxParticles: _readInt(json, 'maxParticles', d.maxParticles),
      maxRings: _readInt(json, 'maxRings', d.maxRings),
      maxFloatingTexts: _readInt(json, 'maxFloatingTexts', d.maxFloatingTexts),
      maxFloatingTextsPerCellTurn:
          _readInt(json, 'maxFloatingTextsPerCellTurn', d.maxFloatingTextsPerCellTurn),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VfxLimitsTuning &&
          maxParticles == other.maxParticles &&
          maxRings == other.maxRings &&
          maxFloatingTexts == other.maxFloatingTexts &&
          maxFloatingTextsPerCellTurn == other.maxFloatingTextsPerCellTurn;

  @override
  int get hashCode => Object.hash(
        maxParticles,
        maxRings,
        maxFloatingTexts,
        maxFloatingTextsPerCellTurn,
      );
}

/// フローティングテキストの挙動およびカラーパレット設定
@immutable
class FloatingTextTuning {
  final int durationMs;
  final int staggerMs;
  final double riseCells;
  final double stackSpacingCells;
  final double fontSizeRatio;
  final double popScaleMax;
  final double outlineAlpha;

  // 基本数値・イベント色
  final int dmgHeroColor;
  final int dmgMonColor;
  final int missColor;
  final int healHpColor;
  final int healPwColor;
  final int levelUpColor;

  // 状態変化 9 カテゴリパレット
  final int statusLethalColor;
  final int statusSlimeColor;
  final int statusSicknessColor;
  final int statusDangerColor;
  final int statusMentalColor;
  final int statusImmobilizeColor;
  final int statusImpairColor;
  final int statusMovementColor;
  final int statusBuffColor;

  const FloatingTextTuning({
    this.durationMs = 680,
    this.staggerMs = 80,
    this.riseCells = 0.85,
    this.stackSpacingCells = 0.42,
    this.fontSizeRatio = 0.44,
    this.popScaleMax = 1.10,
    this.outlineAlpha = 0.92,
    this.dmgHeroColor = 0xFFFF5252,
    this.dmgMonColor = 0xFFFFEE58,
    this.missColor = 0xFFB0BEC5,
    this.healHpColor = 0xFF69F0AE,
    this.healPwColor = 0xFF40C4FF,
    this.levelUpColor = 0xFFFFD740,
    this.statusLethalColor = 0xFFFF5252,
    this.statusSlimeColor = 0xFF76FF03,
    this.statusSicknessColor = 0xFFE040FB,
    this.statusDangerColor = 0xFFFF7043,
    this.statusMentalColor = 0xFFFFD54F,
    this.statusImmobilizeColor = 0xFF80D8FF,
    this.statusImpairColor = 0xFFFFAB91,
    this.statusMovementColor = 0xFF81D4FA,
    this.statusBuffColor = 0xFF69F0AE,
  });

  FloatingTextTuning copyWith({
    int? durationMs,
    int? staggerMs,
    double? riseCells,
    double? stackSpacingCells,
    double? fontSizeRatio,
    double? popScaleMax,
    double? outlineAlpha,
    int? dmgHeroColor,
    int? dmgMonColor,
    int? missColor,
    int? healHpColor,
    int? healPwColor,
    int? levelUpColor,
    int? statusLethalColor,
    int? statusSlimeColor,
    int? statusSicknessColor,
    int? statusDangerColor,
    int? statusMentalColor,
    int? statusImmobilizeColor,
    int? statusImpairColor,
    int? statusMovementColor,
    int? statusBuffColor,
  }) {
    return FloatingTextTuning(
      durationMs: durationMs ?? this.durationMs,
      staggerMs: staggerMs ?? this.staggerMs,
      riseCells: riseCells ?? this.riseCells,
      stackSpacingCells: stackSpacingCells ?? this.stackSpacingCells,
      fontSizeRatio: fontSizeRatio ?? this.fontSizeRatio,
      popScaleMax: popScaleMax ?? this.popScaleMax,
      outlineAlpha: outlineAlpha ?? this.outlineAlpha,
      dmgHeroColor: dmgHeroColor ?? this.dmgHeroColor,
      dmgMonColor: dmgMonColor ?? this.dmgMonColor,
      missColor: missColor ?? this.missColor,
      healHpColor: healHpColor ?? this.healHpColor,
      healPwColor: healPwColor ?? this.healPwColor,
      levelUpColor: levelUpColor ?? this.levelUpColor,
      statusLethalColor: statusLethalColor ?? this.statusLethalColor,
      statusSlimeColor: statusSlimeColor ?? this.statusSlimeColor,
      statusSicknessColor: statusSicknessColor ?? this.statusSicknessColor,
      statusDangerColor: statusDangerColor ?? this.statusDangerColor,
      statusMentalColor: statusMentalColor ?? this.statusMentalColor,
      statusImmobilizeColor: statusImmobilizeColor ?? this.statusImmobilizeColor,
      statusImpairColor: statusImpairColor ?? this.statusImpairColor,
      statusMovementColor: statusMovementColor ?? this.statusMovementColor,
      statusBuffColor: statusBuffColor ?? this.statusBuffColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'durationMs': durationMs,
        'staggerMs': staggerMs,
        'riseCells': riseCells,
        'stackSpacingCells': stackSpacingCells,
        'fontSizeRatio': fontSizeRatio,
        'popScaleMax': popScaleMax,
        'outlineAlpha': outlineAlpha,
        'dmgHeroColor': dmgHeroColor,
        'dmgMonColor': dmgMonColor,
        'missColor': missColor,
        'healHpColor': healHpColor,
        'healPwColor': healPwColor,
        'levelUpColor': levelUpColor,
        'statusLethalColor': statusLethalColor,
        'statusSlimeColor': statusSlimeColor,
        'statusSicknessColor': statusSicknessColor,
        'statusDangerColor': statusDangerColor,
        'statusMentalColor': statusMentalColor,
        'statusImmobilizeColor': statusImmobilizeColor,
        'statusImpairColor': statusImpairColor,
        'statusMovementColor': statusMovementColor,
        'statusBuffColor': statusBuffColor,
      };

  factory FloatingTextTuning.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FloatingTextTuning();
    const d = FloatingTextTuning();
    return FloatingTextTuning(
      durationMs: _readInt(json, 'durationMs', d.durationMs),
      staggerMs: _readInt(json, 'staggerMs', d.staggerMs),
      riseCells: _readDouble(json, 'riseCells', d.riseCells),
      stackSpacingCells: _readDouble(json, 'stackSpacingCells', d.stackSpacingCells),
      fontSizeRatio: _readDouble(json, 'fontSizeRatio', d.fontSizeRatio),
      popScaleMax: _readDouble(json, 'popScaleMax', d.popScaleMax),
      outlineAlpha: _readDouble(json, 'outlineAlpha', d.outlineAlpha),
      dmgHeroColor: _readInt(json, 'dmgHeroColor', d.dmgHeroColor),
      dmgMonColor: _readInt(json, 'dmgMonColor', d.dmgMonColor),
      missColor: _readInt(json, 'missColor', d.missColor),
      healHpColor: _readInt(json, 'healHpColor', d.healHpColor),
      healPwColor: _readInt(json, 'healPwColor', d.healPwColor),
      levelUpColor: _readInt(json, 'levelUpColor', d.levelUpColor),
      statusLethalColor: _readInt(json, 'statusLethalColor', d.statusLethalColor),
      statusSlimeColor: _readInt(json, 'statusSlimeColor', d.statusSlimeColor),
      statusSicknessColor: _readInt(json, 'statusSicknessColor', d.statusSicknessColor),
      statusDangerColor: _readInt(json, 'statusDangerColor', d.statusDangerColor),
      statusMentalColor: _readInt(json, 'statusMentalColor', d.statusMentalColor),
      statusImmobilizeColor: _readInt(json, 'statusImmobilizeColor', d.statusImmobilizeColor),
      statusImpairColor: _readInt(json, 'statusImpairColor', d.statusImpairColor),
      statusMovementColor: _readInt(json, 'statusMovementColor', d.statusMovementColor),
      statusBuffColor: _readInt(json, 'statusBuffColor', d.statusBuffColor),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FloatingTextTuning &&
          durationMs == other.durationMs &&
          staggerMs == other.staggerMs &&
          riseCells == other.riseCells &&
          stackSpacingCells == other.stackSpacingCells &&
          fontSizeRatio == other.fontSizeRatio &&
          popScaleMax == other.popScaleMax &&
          outlineAlpha == other.outlineAlpha &&
          dmgHeroColor == other.dmgHeroColor &&
          dmgMonColor == other.dmgMonColor &&
          missColor == other.missColor &&
          healHpColor == other.healHpColor &&
          healPwColor == other.healPwColor &&
          levelUpColor == other.levelUpColor &&
          statusLethalColor == other.statusLethalColor &&
          statusSlimeColor == other.statusSlimeColor &&
          statusSicknessColor == other.statusSicknessColor &&
          statusDangerColor == other.statusDangerColor &&
          statusMentalColor == other.statusMentalColor &&
          statusImmobilizeColor == other.statusImmobilizeColor &&
          statusImpairColor == other.statusImpairColor &&
          statusMovementColor == other.statusMovementColor &&
          statusBuffColor == other.statusBuffColor;

  @override
  int get hashCode => Object.hashAll([
        durationMs,
        staggerMs,
        riseCells,
        stackSpacingCells,
        fontSizeRatio,
        popScaleMax,
        outlineAlpha,
        dmgHeroColor,
        dmgMonColor,
        missColor,
        healHpColor,
        healPwColor,
        levelUpColor,
        statusLethalColor,
        statusSlimeColor,
        statusSicknessColor,
        statusDangerColor,
        statusMentalColor,
        statusImmobilizeColor,
        statusImpairColor,
        statusMovementColor,
        statusBuffColor,
      ]);
}

/// 持続的な状態マイクロ演出（浮遊・バッジ・状態枠線）の設定
@immutable
class AmbientStatusTuning {
  final double floatLiftDy;
  final double shadowWidthRatio;
  final double shadowHeightRatio;
  final double shadowAlpha;
  final double arcStrokeRatio;
  final int arcColor;
  final double badgeFontSizeRatio;
  final double badgeBobAmplitude;
  final double frameStrokeRatio;
  final double frameAlpha;
  final double phaseStepPerTurn;

  const AmbientStatusTuning({
    this.floatLiftDy = -0.11,
    this.shadowWidthRatio = 0.56,
    this.shadowHeightRatio = 0.18,
    this.shadowAlpha = 0.45,
    this.arcStrokeRatio = 0.06,
    this.arcColor = 0xCC80D8FF,
    this.badgeFontSizeRatio = 0.36,
    this.badgeBobAmplitude = 0.04,
    this.frameStrokeRatio = 0.055,
    this.frameAlpha = 0.72,
    this.phaseStepPerTurn = 0.35,
  });

  AmbientStatusTuning copyWith({
    double? floatLiftDy,
    double? shadowWidthRatio,
    double? shadowHeightRatio,
    double? shadowAlpha,
    double? arcStrokeRatio,
    int? arcColor,
    double? badgeFontSizeRatio,
    double? badgeBobAmplitude,
    double? frameStrokeRatio,
    double? frameAlpha,
    double? phaseStepPerTurn,
  }) {
    return AmbientStatusTuning(
      floatLiftDy: floatLiftDy ?? this.floatLiftDy,
      shadowWidthRatio: shadowWidthRatio ?? this.shadowWidthRatio,
      shadowHeightRatio: shadowHeightRatio ?? this.shadowHeightRatio,
      shadowAlpha: shadowAlpha ?? this.shadowAlpha,
      arcStrokeRatio: arcStrokeRatio ?? this.arcStrokeRatio,
      arcColor: arcColor ?? this.arcColor,
      badgeFontSizeRatio: badgeFontSizeRatio ?? this.badgeFontSizeRatio,
      badgeBobAmplitude: badgeBobAmplitude ?? this.badgeBobAmplitude,
      frameStrokeRatio: frameStrokeRatio ?? this.frameStrokeRatio,
      frameAlpha: frameAlpha ?? this.frameAlpha,
      phaseStepPerTurn: phaseStepPerTurn ?? this.phaseStepPerTurn,
    );
  }

  Map<String, dynamic> toJson() => {
        'floatLiftDy': floatLiftDy,
        'shadowWidthRatio': shadowWidthRatio,
        'shadowHeightRatio': shadowHeightRatio,
        'shadowAlpha': shadowAlpha,
        'arcStrokeRatio': arcStrokeRatio,
        'arcColor': arcColor,
        'badgeFontSizeRatio': badgeFontSizeRatio,
        'badgeBobAmplitude': badgeBobAmplitude,
        'frameStrokeRatio': frameStrokeRatio,
        'frameAlpha': frameAlpha,
        'phaseStepPerTurn': phaseStepPerTurn,
      };

  factory AmbientStatusTuning.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AmbientStatusTuning();
    const d = AmbientStatusTuning();
    return AmbientStatusTuning(
      floatLiftDy: _readDouble(json, 'floatLiftDy', d.floatLiftDy),
      shadowWidthRatio: _readDouble(json, 'shadowWidthRatio', d.shadowWidthRatio),
      shadowHeightRatio: _readDouble(json, 'shadowHeightRatio', d.shadowHeightRatio),
      shadowAlpha: _readDouble(json, 'shadowAlpha', d.shadowAlpha),
      arcStrokeRatio: _readDouble(json, 'arcStrokeRatio', d.arcStrokeRatio),
      arcColor: _readInt(json, 'arcColor', d.arcColor),
      badgeFontSizeRatio: _readDouble(json, 'badgeFontSizeRatio', d.badgeFontSizeRatio),
      badgeBobAmplitude: _readDouble(json, 'badgeBobAmplitude', d.badgeBobAmplitude),
      frameStrokeRatio: _readDouble(json, 'frameStrokeRatio', d.frameStrokeRatio),
      frameAlpha: _readDouble(json, 'frameAlpha', d.frameAlpha),
      phaseStepPerTurn: _readDouble(json, 'phaseStepPerTurn', d.phaseStepPerTurn),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmbientStatusTuning &&
          floatLiftDy == other.floatLiftDy &&
          shadowWidthRatio == other.shadowWidthRatio &&
          shadowHeightRatio == other.shadowHeightRatio &&
          shadowAlpha == other.shadowAlpha &&
          arcStrokeRatio == other.arcStrokeRatio &&
          arcColor == other.arcColor &&
          badgeFontSizeRatio == other.badgeFontSizeRatio &&
          badgeBobAmplitude == other.badgeBobAmplitude &&
          frameStrokeRatio == other.frameStrokeRatio &&
          frameAlpha == other.frameAlpha &&
          phaseStepPerTurn == other.phaseStepPerTurn;

  @override
  int get hashCode => Object.hashAll([
        floatLiftDy,
        shadowWidthRatio,
        shadowHeightRatio,
        shadowAlpha,
        arcStrokeRatio,
        arcColor,
        badgeFontSizeRatio,
        badgeBobAmplitude,
        frameStrokeRatio,
        frameAlpha,
        phaseStepPerTurn,
      ]);
}

/// 画面シェイク設定（※大被ダメの発動閾値「最大HPの20%以上」はCコア固定）
@immutable
class ScreenShakeTuning {
  final int durationMs;
  final double explosionAmplitudePx;
  final double bigHitAmplitudePx;
  final double doorBreakAmplitudePx;

  const ScreenShakeTuning({
    this.durationMs = 110,
    this.explosionAmplitudePx = 3.0,
    this.bigHitAmplitudePx = 2.5,
    this.doorBreakAmplitudePx = 2.5,
  });

  ScreenShakeTuning copyWith({
    int? durationMs,
    double? explosionAmplitudePx,
    double? bigHitAmplitudePx,
    double? doorBreakAmplitudePx,
  }) {
    return ScreenShakeTuning(
      durationMs: durationMs ?? this.durationMs,
      explosionAmplitudePx: explosionAmplitudePx ?? this.explosionAmplitudePx,
      bigHitAmplitudePx: bigHitAmplitudePx ?? this.bigHitAmplitudePx,
      doorBreakAmplitudePx: doorBreakAmplitudePx ?? this.doorBreakAmplitudePx,
    );
  }

  Map<String, dynamic> toJson() => {
        'durationMs': durationMs,
        'explosionAmplitudePx': explosionAmplitudePx,
        'bigHitAmplitudePx': bigHitAmplitudePx,
        'doorBreakAmplitudePx': doorBreakAmplitudePx,
      };

  factory ScreenShakeTuning.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScreenShakeTuning();
    const d = ScreenShakeTuning();
    return ScreenShakeTuning(
      durationMs: _readInt(json, 'durationMs', d.durationMs),
      explosionAmplitudePx: _readDouble(json, 'explosionAmplitudePx', d.explosionAmplitudePx),
      bigHitAmplitudePx: _readDouble(json, 'bigHitAmplitudePx', d.bigHitAmplitudePx),
      doorBreakAmplitudePx: _readDouble(json, 'doorBreakAmplitudePx', d.doorBreakAmplitudePx),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenShakeTuning &&
          durationMs == other.durationMs &&
          explosionAmplitudePx == other.explosionAmplitudePx &&
          bigHitAmplitudePx == other.bigHitAmplitudePx &&
          doorBreakAmplitudePx == other.doorBreakAmplitudePx;

  @override
  int get hashCode => Object.hash(
        durationMs,
        explosionAmplitudePx,
        bigHitAmplitudePx,
        doorBreakAmplitudePx,
      );
}

/// アニメーション・VFX・フローティングテキスト全体の統合チューニング設定
@immutable
class VfxTuningConfig {
  static const List<String> particleKeys = [
    'dust',
    'woodDebrisLight',
    'woodDebrisHeavy',
    'rockDebris',
    'potionSplash',
    'explosion',
    'teleport',
    'levelUp',
    'summon',
    'kickImpact',
  ];

  static const List<String> ringKeys = [
    'explosionOuter',
    'explosionInner',
    'teleportDepart',
    'teleportArrive',
    'levelUp',
    'summon',
  ];

  final MotionTuning motion;
  final Map<String, ParticleEffectTuning> particles;
  final int summonNormalColor;
  final int summonDemonColor;
  final int summonAngelColor;
  final Map<String, RingEffectTuning> rings;
  final VfxLimitsTuning limits;
  final FloatingTextTuning floatingText;
  final AmbientStatusTuning ambient;
  final ScreenShakeTuning screenShake;

  const VfxTuningConfig({
    this.motion = const MotionTuning(),
    this.particles = defaultParticles,
    this.summonNormalColor = 0xFFCE93D8,
    this.summonDemonColor = 0xFFFF5252,
    this.summonAngelColor = 0xFFFFD54F,
    this.rings = defaultRings,
    this.limits = const VfxLimitsTuning(),
    this.floatingText = const FloatingTextTuning(),
    this.ambient = const AmbientStatusTuning(),
    this.screenShake = const ScreenShakeTuning(),
  });

  static const Map<String, ParticleEffectTuning> defaultParticles = {
    'dust': ParticleEffectTuning(
      count: 6,
      speedMin: 0.35,
      speedMax: 1.0,
      gravity: 0.4,
      sizeMin: 0.08,
      sizeMax: 0.14,
      durationMs: 220,
      isGlow: false,
      defaultColor: 0xFFD7CCC8,
    ),
    'woodDebrisLight': ParticleEffectTuning(
      count: 6,
      speedMin: 0.7,
      speedMax: 1.3,
      gravity: 2.2,
      sizeMin: 0.09,
      sizeMax: 0.16,
      durationMs: 280,
      isGlow: false,
      defaultColor: 0xFFA1887F,
    ),
    'woodDebrisHeavy': ParticleEffectTuning(
      count: 12,
      speedMin: 0.7,
      speedMax: 2.1,
      gravity: 2.2,
      sizeMin: 0.09,
      sizeMax: 0.16,
      durationMs: 280,
      isGlow: false,
      defaultColor: 0xFFA1887F,
    ),
    'rockDebris': ParticleEffectTuning(
      count: 10,
      speedMin: 0.6,
      speedMax: 1.8,
      gravity: 2.6,
      sizeMin: 0.09,
      sizeMax: 0.15,
      durationMs: 260,
      isGlow: false,
      defaultColor: 0xFFB0BEC5,
    ),
    'potionSplash': ParticleEffectTuning(
      count: 10,
      speedMin: 0.6,
      speedMax: 1.7,
      gravity: 1.6,
      sizeMin: 0.08,
      sizeMax: 0.14,
      durationMs: 260,
      isGlow: true,
      defaultColor: 0xFF40C4FF,
    ),
    'explosion': ParticleEffectTuning(
      count: 16,
      speedMin: 1.2,
      speedMax: 3.0,
      gravity: 0.4,
      sizeMin: 0.10,
      sizeMax: 0.18,
      durationMs: 300,
      isGlow: true,
      defaultColor: 0xFFFF7043,
    ),
    'teleport': ParticleEffectTuning(
      count: 8,
      speedMin: 0.4,
      speedMax: 1.3,
      gravity: -0.6,
      sizeMin: 0.08,
      sizeMax: 0.13,
      durationMs: 260,
      isGlow: true,
      defaultColor: 0xFF80D8FF,
    ),
    'levelUp': ParticleEffectTuning(
      count: 12,
      speedMin: 0.5,
      speedMax: 1.5,
      gravity: -1.1,
      sizeMin: 0.08,
      sizeMax: 0.14,
      durationMs: 340,
      isGlow: true,
      defaultColor: 0xFFFFF176,
    ),
    'summon': ParticleEffectTuning(
      count: 7,
      speedMin: 0.4,
      speedMax: 1.1,
      gravity: -0.3,
      sizeMin: 0.08,
      sizeMax: 0.13,
      durationMs: 240,
      isGlow: true,
      defaultColor: 0xFFCE93D8,
    ),
    'kickImpact': ParticleEffectTuning(
      count: 6,
      speedMin: 0.6,
      speedMax: 1.5,
      gravity: 1.0,
      sizeMin: 0.08,
      sizeMax: 0.13,
      durationMs: 200,
      isGlow: false,
      defaultColor: 0xFFFFE082,
    ),
  };

  static const Map<String, RingEffectTuning> defaultRings = {
    'explosionOuter': RingEffectTuning(
      startRadiusCells: 0.25,
      endRadiusCells: 1.65,
      strokeRatio: 0.14,
      durationMs: 300,
      color: 0xFFFF7043,
    ),
    'explosionInner': RingEffectTuning(
      startRadiusCells: 0.15,
      endRadiusCells: 1.10,
      strokeRatio: 0.10,
      durationMs: 240,
      color: 0xFFFFF59D,
    ),
    'teleportDepart': RingEffectTuning(
      startRadiusCells: 0.85,
      endRadiusCells: 0.15,
      strokeRatio: 0.09,
      durationMs: 220,
      color: 0xFF80D8FF,
    ),
    'teleportArrive': RingEffectTuning(
      startRadiusCells: 0.15,
      endRadiusCells: 0.95,
      strokeRatio: 0.10,
      durationMs: 260,
      color: 0xFF80D8FF,
    ),
    'levelUp': RingEffectTuning(
      startRadiusCells: 0.20,
      endRadiusCells: 1.20,
      strokeRatio: 0.11,
      durationMs: 340,
      color: 0xFFFFD740,
    ),
    'summon': RingEffectTuning(
      startRadiusCells: 0.90,
      endRadiusCells: 0.20,
      strokeRatio: 0.10,
      durationMs: 260,
      color: 0xFFCE93D8,
    ),
  };

  /// 標準プリセット
  factory VfxTuningConfig.defaults() => const VfxTuningConfig();

  /// 控えめプリセット（伝統的ローグライク寄りの高速・省エフェクト設定）
  factory VfxTuningConfig.subtle() {
    final p = <String, ParticleEffectTuning>{};
    defaultParticles.forEach((k, v) {
      p[k] = v.copyWith(
        count: (v.count * 0.55).round().clamp(2, 30),
        durationMs: (v.durationMs * 0.8).round(),
      );
    });
    return VfxTuningConfig(
      motion: const MotionTuning(
        moveMs: 90,
        moveHopHeightRatio: 0.05,
        attackBumpMs: 110,
        attackBumpDistance: 0.25,
        hitFeedbackMs: 120,
        hitFlashAlpha: 0.45,
        cameraFollowMs: 90,
      ),
      particles: Map.unmodifiable(p),
      floatingText: const FloatingTextTuning(
        durationMs: 540,
        riseCells: 0.65,
        fontSizeRatio: 0.38,
        popScaleMax: 1.03,
      ),
      screenShake: const ScreenShakeTuning(
        durationMs: 85,
        explosionAmplitudePx: 1.5,
        bigHitAmplitudePx: 1.2,
        doorBreakAmplitudePx: 1.0,
      ),
    );
  }

  /// 派手プリセット（アクション感・視認性を強調した設定）
  factory VfxTuningConfig.vivid() {
    final p = <String, ParticleEffectTuning>{};
    defaultParticles.forEach((k, v) {
      p[k] = v.copyWith(
        count: (v.count * 1.5).round().clamp(4, 32),
        speedMax: v.speedMax * 1.25,
        sizeMax: v.sizeMax * 1.15,
      );
    });
    return VfxTuningConfig(
      motion: const MotionTuning(
        moveMs: 130,
        moveHopHeightRatio: 0.13,
        attackBumpMs: 155,
        attackBumpDistance: 0.42,
        hitFeedbackMs: 185,
        hitFlashAlpha: 0.78,
        cameraFollowMs: 130,
      ),
      particles: Map.unmodifiable(p),
      limits: const VfxLimitsTuning(maxParticles: 120, maxRings: 12),
      floatingText: const FloatingTextTuning(
        durationMs: 780,
        riseCells: 1.05,
        fontSizeRatio: 0.50,
        popScaleMax: 1.22,
      ),
      screenShake: const ScreenShakeTuning(
        durationMs: 140,
        explosionAmplitudePx: 4.5,
        bigHitAmplitudePx: 3.5,
        doorBreakAmplitudePx: 3.5,
      ),
    );
  }

  ParticleEffectTuning particleOf(String key) =>
      particles[key] ?? defaultParticles[key] ?? defaultParticles['dust']!;

  RingEffectTuning ringOf(String key) =>
      rings[key] ?? defaultRings[key] ?? defaultRings['teleportArrive']!;

  VfxTuningConfig copyWith({
    MotionTuning? motion,
    Map<String, ParticleEffectTuning>? particles,
    int? summonNormalColor,
    int? summonDemonColor,
    int? summonAngelColor,
    Map<String, RingEffectTuning>? rings,
    VfxLimitsTuning? limits,
    FloatingTextTuning? floatingText,
    AmbientStatusTuning? ambient,
    ScreenShakeTuning? screenShake,
  }) {
    return VfxTuningConfig(
      motion: motion ?? this.motion,
      particles: particles != null ? Map.unmodifiable(particles) : this.particles,
      summonNormalColor: summonNormalColor ?? this.summonNormalColor,
      summonDemonColor: summonDemonColor ?? this.summonDemonColor,
      summonAngelColor: summonAngelColor ?? this.summonAngelColor,
      rings: rings != null ? Map.unmodifiable(rings) : this.rings,
      limits: limits ?? this.limits,
      floatingText: floatingText ?? this.floatingText,
      ambient: ambient ?? this.ambient,
      screenShake: screenShake ?? this.screenShake,
    );
  }

  Map<String, dynamic> toJson() => {
        'motion': motion.toJson(),
        'particles': {
          for (final k in particleKeys) k: particleOf(k).toJson(),
        },
        'summonNormalColor': summonNormalColor,
        'summonDemonColor': summonDemonColor,
        'summonAngelColor': summonAngelColor,
        'rings': {
          for (final k in ringKeys) k: ringOf(k).toJson(),
        },
        'limits': limits.toJson(),
        'floatingText': floatingText.toJson(),
        'ambient': ambient.toJson(),
        'screenShake': screenShake.toJson(),
      };

  factory VfxTuningConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VfxTuningConfig();
    final rawParticles = json['particles'];
    final parsedParticles = <String, ParticleEffectTuning>{};
    for (final k in particleKeys) {
      final fallback = defaultParticles[k]!;
      final sub = (rawParticles is Map && rawParticles[k] is Map)
          ? Map<String, dynamic>.from(rawParticles[k] as Map)
          : null;
      parsedParticles[k] = ParticleEffectTuning.fromJson(sub, fallback);
    }

    final rawRings = json['rings'];
    final parsedRings = <String, RingEffectTuning>{};
    for (final k in ringKeys) {
      final fallback = defaultRings[k]!;
      final sub = (rawRings is Map && rawRings[k] is Map)
          ? Map<String, dynamic>.from(rawRings[k] as Map)
          : null;
      parsedRings[k] = RingEffectTuning.fromJson(sub, fallback);
    }

    const d = VfxTuningConfig();
    return VfxTuningConfig(
      motion: MotionTuning.fromJson(_asMap(json['motion'])),
      particles: Map.unmodifiable(parsedParticles),
      summonNormalColor: _readInt(json, 'summonNormalColor', d.summonNormalColor),
      summonDemonColor: _readInt(json, 'summonDemonColor', d.summonDemonColor),
      summonAngelColor: _readInt(json, 'summonAngelColor', d.summonAngelColor),
      rings: Map.unmodifiable(parsedRings),
      limits: VfxLimitsTuning.fromJson(_asMap(json['limits'])),
      floatingText: FloatingTextTuning.fromJson(_asMap(json['floatingText'])),
      ambient: AmbientStatusTuning.fromJson(_asMap(json['ambient'])),
      screenShake: ScreenShakeTuning.fromJson(_asMap(json['screenShake'])),
    );
  }

  /// 本番コンパイル組み込み用の `lib/models/vfx_tuning_defaults.dart` ソースコードを自動生成する
  String toDartConstSource() {
    String hex(int v) => '0x${(v & 0xFFFFFFFF).toRadixString(16).toUpperCase().padLeft(8, '0')}';
    String dbl(double v) => v.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '.0');

    final buf = StringBuffer()
      ..writeln('// GENERATED OR UPDATED BY VFX STUDIO - DO NOT EDIT BY HAND UNLESS NEEDED.')
      ..writeln("import 'vfx_tuning_config.dart';")
      ..writeln()
      ..writeln('/// 本番ビルド（Release）にコンパイル組み込みされる確定済みVFX設定定数')
      ..writeln('const VfxTuningConfig kDefaultVfxTuning = VfxTuningConfig(')
      ..writeln('  motion: MotionTuning(')
      ..writeln('    moveMs: ${motion.moveMs},')
      ..writeln('    moveHopHeightRatio: ${dbl(motion.moveHopHeightRatio)},')
      ..writeln('    attackBumpMs: ${motion.attackBumpMs},')
      ..writeln('    attackBumpDistance: ${dbl(motion.attackBumpDistance)},')
      ..writeln('    hitFeedbackMs: ${motion.hitFeedbackMs},')
      ..writeln('    hitShakeRatio: ${dbl(motion.hitShakeRatio)},')
      ..writeln('    hitFlashAlpha: ${dbl(motion.hitFlashAlpha)},')
      ..writeln('    hitFlashColor: ${hex(motion.hitFlashColor)},')
      ..writeln('    deathFadeMs: ${motion.deathFadeMs},')
      ..writeln('    deathEndScale: ${dbl(motion.deathEndScale)},')
      ..writeln('    projectileStepMs: ${motion.projectileStepMs},')
      ..writeln('    projectileMaxTotalMs: ${motion.projectileMaxTotalMs},')
      ..writeln('    cameraFollowMs: ${motion.cameraFollowMs},')
      ..writeln('    vanishFadeStartT: ${dbl(motion.vanishFadeStartT)},')
      ..writeln('    vanishEndScale: ${dbl(motion.vanishEndScale)},')
      ..writeln('    speedFastMultiplier: ${dbl(motion.speedFastMultiplier)},')
      ..writeln('    speedNormalMultiplier: ${dbl(motion.speedNormalMultiplier)},')
      ..writeln('    speedSlowMultiplier: ${dbl(motion.speedSlowMultiplier)},')
      ..writeln('  ),')
      ..writeln('  particles: {');

    for (final k in particleKeys) {
      final p = particleOf(k);
      buf
        ..writeln("    '$k': ParticleEffectTuning(")
        ..writeln('      count: ${p.count},')
        ..writeln('      speedMin: ${dbl(p.speedMin)},')
        ..writeln('      speedMax: ${dbl(p.speedMax)},')
        ..writeln('      gravity: ${dbl(p.gravity)},')
        ..writeln('      sizeMin: ${dbl(p.sizeMin)},')
        ..writeln('      sizeMax: ${dbl(p.sizeMax)},')
        ..writeln('      durationMs: ${p.durationMs},')
        ..writeln('      isGlow: ${p.isGlow},')
        ..writeln('      defaultColor: ${hex(p.defaultColor)},')
        ..writeln('    ),');
    }

    buf
      ..writeln('  },')
      ..writeln('  summonNormalColor: ${hex(summonNormalColor)},')
      ..writeln('  summonDemonColor: ${hex(summonDemonColor)},')
      ..writeln('  summonAngelColor: ${hex(summonAngelColor)},')
      ..writeln('  rings: {');

    for (final k in ringKeys) {
      final r = ringOf(k);
      buf
        ..writeln("    '$k': RingEffectTuning(")
        ..writeln('      startRadiusCells: ${dbl(r.startRadiusCells)},')
        ..writeln('      endRadiusCells: ${dbl(r.endRadiusCells)},')
        ..writeln('      strokeRatio: ${dbl(r.strokeRatio)},')
        ..writeln('      durationMs: ${r.durationMs},')
        ..writeln('      color: ${hex(r.color)},')
        ..writeln('    ),');
    }

    buf
      ..writeln('  },')
      ..writeln('  limits: VfxLimitsTuning(')
      ..writeln('    maxParticles: ${limits.maxParticles},')
      ..writeln('    maxRings: ${limits.maxRings},')
      ..writeln('    maxFloatingTexts: ${limits.maxFloatingTexts},')
      ..writeln('    maxFloatingTextsPerCellTurn: ${limits.maxFloatingTextsPerCellTurn},')
      ..writeln('  ),')
      ..writeln('  floatingText: FloatingTextTuning(')
      ..writeln('    durationMs: ${floatingText.durationMs},')
      ..writeln('    staggerMs: ${floatingText.staggerMs},')
      ..writeln('    riseCells: ${dbl(floatingText.riseCells)},')
      ..writeln('    stackSpacingCells: ${dbl(floatingText.stackSpacingCells)},')
      ..writeln('    fontSizeRatio: ${dbl(floatingText.fontSizeRatio)},')
      ..writeln('    popScaleMax: ${dbl(floatingText.popScaleMax)},')
      ..writeln('    outlineAlpha: ${dbl(floatingText.outlineAlpha)},')
      ..writeln('    dmgHeroColor: ${hex(floatingText.dmgHeroColor)},')
      ..writeln('    dmgMonColor: ${hex(floatingText.dmgMonColor)},')
      ..writeln('    missColor: ${hex(floatingText.missColor)},')
      ..writeln('    healHpColor: ${hex(floatingText.healHpColor)},')
      ..writeln('    healPwColor: ${hex(floatingText.healPwColor)},')
      ..writeln('    levelUpColor: ${hex(floatingText.levelUpColor)},')
      ..writeln('    statusLethalColor: ${hex(floatingText.statusLethalColor)},')
      ..writeln('    statusSlimeColor: ${hex(floatingText.statusSlimeColor)},')
      ..writeln('    statusSicknessColor: ${hex(floatingText.statusSicknessColor)},')
      ..writeln('    statusDangerColor: ${hex(floatingText.statusDangerColor)},')
      ..writeln('    statusMentalColor: ${hex(floatingText.statusMentalColor)},')
      ..writeln('    statusImmobilizeColor: ${hex(floatingText.statusImmobilizeColor)},')
      ..writeln('    statusImpairColor: ${hex(floatingText.statusImpairColor)},')
      ..writeln('    statusMovementColor: ${hex(floatingText.statusMovementColor)},')
      ..writeln('    statusBuffColor: ${hex(floatingText.statusBuffColor)},')
      ..writeln('  ),')
      ..writeln('  ambient: AmbientStatusTuning(')
      ..writeln('    floatLiftDy: ${dbl(ambient.floatLiftDy)},')
      ..writeln('    shadowWidthRatio: ${dbl(ambient.shadowWidthRatio)},')
      ..writeln('    shadowHeightRatio: ${dbl(ambient.shadowHeightRatio)},')
      ..writeln('    shadowAlpha: ${dbl(ambient.shadowAlpha)},')
      ..writeln('    arcStrokeRatio: ${dbl(ambient.arcStrokeRatio)},')
      ..writeln('    arcColor: ${hex(ambient.arcColor)},')
      ..writeln('    badgeFontSizeRatio: ${dbl(ambient.badgeFontSizeRatio)},')
      ..writeln('    badgeBobAmplitude: ${dbl(ambient.badgeBobAmplitude)},')
      ..writeln('    frameStrokeRatio: ${dbl(ambient.frameStrokeRatio)},')
      ..writeln('    frameAlpha: ${dbl(ambient.frameAlpha)},')
      ..writeln('    phaseStepPerTurn: ${dbl(ambient.phaseStepPerTurn)},')
      ..writeln('  ),')
      ..writeln('  screenShake: ScreenShakeTuning(')
      ..writeln('    durationMs: ${screenShake.durationMs},')
      ..writeln('    explosionAmplitudePx: ${dbl(screenShake.explosionAmplitudePx)},')
      ..writeln('    bigHitAmplitudePx: ${dbl(screenShake.bigHitAmplitudePx)},')
      ..writeln('    doorBreakAmplitudePx: ${dbl(screenShake.doorBreakAmplitudePx)},')
      ..writeln('  ),')
      ..writeln(');');
    return buf.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VfxTuningConfig) return false;
    if (motion != other.motion ||
        summonNormalColor != other.summonNormalColor ||
        summonDemonColor != other.summonDemonColor ||
        summonAngelColor != other.summonAngelColor ||
        limits != other.limits ||
        floatingText != other.floatingText ||
        ambient != other.ambient ||
        screenShake != other.screenShake) {
      return false;
    }
    for (final k in particleKeys) {
      if (particleOf(k) != other.particleOf(k)) return false;
    }
    for (final k in ringKeys) {
      if (ringOf(k) != other.ringOf(k)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        motion,
        summonNormalColor,
        summonDemonColor,
        summonAngelColor,
        limits,
        floatingText,
        ambient,
        screenShake,
        Object.hashAll([for (final k in particleKeys) particleOf(k)]),
        Object.hashAll([for (final k in ringKeys) ringOf(k)]),
      );
}

/// 開発中（`kDebugMode`）のみ `tools/vfx_studio/vfx_tuning.json` を監視・ホットリロードするヘルパー。
/// Release ビルドでは一切のファイル探索・I/O を行わない。
class DebugVfxTuningReloader {
  DateTime? _lastLoadedMtime;

  /// 開発ワークスペース上の `tools/vfx_studio/vfx_tuning.json` を解決する
  static File? resolveStudioJsonFile() {
    final candidates = <String>[
      'tools/vfx_studio/vfx_tuning.json',
      'sys/flutter/tools/vfx_studio/vfx_tuning.json',
    ];
    for (final rel in candidates) {
      final f = File(rel);
      if (f.existsSync()) return f;
    }
    // 実行ファイル位置から親ディレクトリを遡って開発リポジトリを探索
    try {
      var dir = File(Platform.resolvedExecutable).parent;
      for (int i = 0; i < 8; i++) {
        final f1 = File('${dir.path}/tools/vfx_studio/vfx_tuning.json');
        if (f1.existsSync()) return f1;
        final f2 = File('${dir.path}/sys/flutter/tools/vfx_studio/vfx_tuning.json');
        if (f2.existsSync()) return f2;
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}
    return null;
  }

  /// `kDebugMode` かつ JSON ファイルが前回読込時より新しければ再パースして返す
  Future<VfxTuningConfig?> reloadIfChanged({bool force = false}) async {
    if (!kDebugMode) return null;
    try {
      final file = resolveStudioJsonFile();
      if (file == null || !await file.exists()) return null;
      final mtime = await file.lastModified();
      if (!force && _lastLoadedMtime != null && !mtime.isAfter(_lastLoadedMtime!)) {
        return null;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final activeMap = decoded['active'] is Map
            ? Map<String, dynamic>.from(decoded['active'] as Map)
            : Map<String, dynamic>.from(decoded);
        _lastLoadedMtime = mtime;
        return VfxTuningConfig.fromJson(activeMap);
      }
    } catch (e, st) {
      debugPrint('[DebugVfxTuningReloader] Failed to reload vfx_tuning.json: $e\n$st');
    }
    return null;
  }
}

Map<String, dynamic>? _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

int _readInt(Map<String, dynamic> map, String key, int fallback) {
  final v = map[key];
  if (v is int) return v;
  if (v is num) return v.round();
  return fallback;
}

double _readDouble(Map<String, dynamic> map, String key, double fallback) {
  final v = map[key];
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return fallback;
}

bool _readBool(Map<String, dynamic> map, String key, bool fallback) {
  final v = map[key];
  if (v is bool) return v;
  return fallback;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/map_animation_event.dart';
import '../models/vfx_tuning_config.dart';
import '../models/vfx_tuning_defaults.dart';
import '../nethack_screen.dart';

class _MoveEntry {
  final int entityId;
  final int fromX;
  final int fromY;
  final int toX;
  final int toY;
  final int? tile;
  final String? char;
  final int? color;
  final bool enableHop;
  final Duration startTime;
  final Duration duration;

  _MoveEntry({
    required this.entityId,
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    this.tile,
    this.char,
    this.color,
    this.enableHop = true,
    required this.startTime,
    required this.duration,
  });
}

class _VanishingMoveEntry {
  final int fromX;
  final int fromY;
  final int toX;
  final int toY;
  final int tile;
  final String char;
  final int color;
  final Duration startTime;
  final Duration duration;

  _VanishingMoveEntry({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.tile,
    required this.char,
    required this.color,
    required this.startTime,
    required this.duration,
  });
}

class _BumpEntry {
  final int cellX;
  final int cellY;
  final double dirX;
  final double dirY;
  final Duration startTime;
  final Duration duration;

  _BumpEntry({
    required this.cellX,
    required this.cellY,
    required this.dirX,
    required this.dirY,
    required this.startTime,
    required this.duration,
  });
}

class _HitEntry {
  final int cellX;
  final int cellY;
  final Duration startTime;
  final Duration duration;
  final double shakeSign;

  _HitEntry({
    required this.cellX,
    required this.cellY,
    required this.startTime,
    required this.duration,
    required this.shakeSign,
  });
}

class _DeathEntry {
  final int x;
  final int y;
  final int tile;
  final String char;
  final int color;
  final Duration startTime;
  final Duration duration;

  _DeathEntry({
    required this.x,
    required this.y,
    required this.tile,
    required this.char,
    required this.color,
    required this.startTime,
    required this.duration,
  });
}

class _ProjectileWaypoint {
  final int x;
  final int y;
  final int tile;
  final String char;
  final int color;

  const _ProjectileWaypoint({
    required this.x,
    required this.y,
    required this.tile,
    required this.char,
    required this.color,
  });
}

class _ProjectileTrack {
  final int turnId;
  final List<_ProjectileWaypoint> waypoints;
  final Duration startTime;
  Duration duration;

  _ProjectileTrack({
    required this.turnId,
    required this.waypoints,
    required this.startTime,
    required this.duration,
  });
}

class _ParticleEntry {
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double gravity;
  final double sizeRatio;
  final Color color;
  final bool isGlow;
  final Duration startTime;
  final Duration duration;

  _ParticleEntry({
    required this.startX,
    required this.startY,
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.sizeRatio,
    required this.color,
    required this.isGlow,
    required this.startTime,
    required this.duration,
  });
}

class _RingEntry {
  final double x;
  final double y;
  final double startRadiusCells;
  final double endRadiusCells;
  final double strokeRatio;
  final Color color;
  final Duration startTime;
  final Duration duration;

  _RingEntry({
    required this.x,
    required this.y,
    required this.startRadiusCells,
    required this.endRadiusCells,
    required this.strokeRatio,
    required this.color,
    required this.startTime,
    required this.duration,
  });
}

class _FloatingTextEntry {
  final int turnId;
  final int cellKey;
  final int x;
  final int y;
  final String text;
  final Color color;
  final int priority;
  final int stackIndex;
  final Duration startTime;
  final Duration duration;

  _FloatingTextEntry({
    required this.turnId,
    required this.cellKey,
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    required this.priority,
    required this.stackIndex,
    required this.startTime,
    required this.duration,
  });
}

class _ScreenShakeEntry {
  final double amplitudePx;
  final Duration startTime;
  final Duration duration;

  _ScreenShakeEntry({
    required this.amplitudePx,
    required this.startTime,
    required this.duration,
  });
}

/// マップ上の移動・近接戦闘・死亡・飛び道具・VFX・フローティングテキスト・
/// 持続的な状態マイクロ演出・控えめな画面シェイクを一元管理するコントローラ。
///
/// 非ブロッキングかつ次入力時即スナップ完了（NethackModern 方式）を前提とし、
/// 短期アニメーションが 0 件になると Ticker を完全停止する（持続状態のみの場合は
/// Ticker を起動せず CPU/GPU 負荷ゼロとテスト安全性を維持する）。
class MapAnimationController extends ChangeNotifier {
  static int _cellKey(int x, int y) => y * NetHackScreen.mapCols + x;

  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  Duration? _lastTickTime;
  final math.Random _rng = math.Random(42);

  bool _isEnabled;
  bool _floatingTextEnabled;
  bool isJapanese;
  bool _canLiftFloatingGlyph;
  MapAnimationSpeed speed;
  VfxTuningConfig _tuning;
  int _minAcceptedTurnId = 0;

  /// 持続的な状態マイクロ演出の位相（短期アニメ中・ターン更新時のみ進行）
  double _ambientPhase = 0.0;

  /// 画面シェイク専用 Notifier（平常時は InteractiveViewer の再ビルドを起こさない）
  final ValueNotifier<Offset> screenShakeNotifier = ValueNotifier<Offset>(Offset.zero);

  final Map<int, _MoveEntry> _movesByCell = {};
  final List<_VanishingMoveEntry> _vanishingMoves = [];
  final Map<int, _BumpEntry> _bumpsByCell = {};
  final Map<int, _HitEntry> _hitsByCell = {};
  final List<_DeathEntry> _deaths = [];
  final List<_ProjectileTrack> _projectiles = [];
  final List<_ParticleEntry> _particles = [];
  final List<_RingEntry> _rings = [];
  final List<_FloatingTextEntry> _floatingTexts = [];
  final Map<int, int> _ambientStatusesByCell = {};
  _ScreenShakeEntry? _screenShake;

  MapAnimationController({
    TickerProvider? vsync,
    bool? enabled,
    bool? floatingTextEnabled,
    this.isJapanese = true,
    bool? canLiftFloatingGlyph,
    this.speed = MapAnimationSpeed.normal,
    VfxTuningConfig? tuning,
  })  : _isEnabled = enabled ?? true,
        _floatingTextEnabled = floatingTextEnabled ?? true,
        _canLiftFloatingGlyph = canLiftFloatingGlyph ?? true,
        _tuning = tuning ?? kDefaultVfxTuning {
    if (vsync != null) {
      _ticker = vsync.createTicker(_onTick);
    }
  }

  VfxTuningConfig get tuning => _tuning;
  set tuning(VfxTuningConfig value) {
    if (_tuning == value) return;
    _tuning = value;
    notifyListeners();
  }

  bool get enabled => _isEnabled;
  set enabled(bool value) {
    if (_isEnabled == value) return;
    _isEnabled = value;
    if (!_isEnabled) {
      _clearAnimationEffects(includeFloatingTexts: false);
    }
    notifyListeners();
  }

  bool get floatingTextEnabled => _floatingTextEnabled;
  set floatingTextEnabled(bool value) {
    if (_floatingTextEnabled == value) return;
    _floatingTextEnabled = value;
    if (!_floatingTextEnabled && _floatingTexts.isNotEmpty) {
      _floatingTexts.clear();
      _stopTickerIfIdle();
      notifyListeners();
    }
  }

  bool get canLiftFloatingGlyph => _canLiftFloatingGlyph;
  set canLiftFloatingGlyph(bool value) {
    if (_canLiftFloatingGlyph == value) return;
    _canLiftFloatingGlyph = value;
    if (hasAmbientStatuses) {
      notifyListeners();
    }
  }

  int get minAcceptedTurnId => _minAcceptedTurnId;

  double get _speedMultiplier => _tuning.motion.multiplierForMode(speed.cMode);

  /// Ticker を駆動すべき短期アニメーション・エフェクトが 1 件以上あるか
  bool get hasActiveAnimations =>
      _movesByCell.isNotEmpty ||
      _vanishingMoves.isNotEmpty ||
      _bumpsByCell.isNotEmpty ||
      _hitsByCell.isNotEmpty ||
      _deaths.isNotEmpty ||
      _projectiles.isNotEmpty ||
      _particles.isNotEmpty ||
      _rings.isNotEmpty ||
      _floatingTexts.isNotEmpty ||
      _screenShake != null;

  /// 持続的な状態マイクロ演出が 1 セル以上存在するか（Ticker は起動しない）
  bool get hasAmbientStatuses => _isEnabled && _ambientStatusesByCell.isNotEmpty;

  /// オーバーレイペインタで何か描画すべき要素があるか
  bool get hasAnyVisuals => hasActiveAnimations || hasAmbientStatuses;

  Duration _scaledDuration(int baseMs) {
    final ms = (baseMs * _speedMultiplier).round().clamp(16, 4000);
    return Duration(milliseconds: ms);
  }

  void _ensureTickerRunning() {
    if (_ticker != null && !_ticker!.isActive) {
      _lastTickTime = null;
      _ticker!.start();
    }
  }

  void _stopTickerIfIdle() {
    if (!hasActiveAnimations && _ticker != null && _ticker!.isActive) {
      _ticker!.stop();
      _lastTickTime = null;
    }
  }

  void _onTick(Duration timestamp) {
    if (_lastTickTime == null) {
      _lastTickTime = timestamp;
      return;
    }
    final dt = timestamp - _lastTickTime!;
    _lastTickTime = timestamp;
    if (dt > Duration.zero) {
      advance(dt);
    }
  }

  /// 時間を進め、完了済みアニメーションを削除して描画通知する（テストからも直接呼び出し可能）。
  void advance(Duration dt) {
    if (dt <= Duration.zero || !hasActiveAnimations) return;
    _elapsed += dt;
    _ambientPhase = (_ambientPhase + dt.inMicroseconds / 1000000.0 * 3.2) % (math.pi * 2);
    _pruneExpired();
    _updateScreenShake();
    _stopTickerIfIdle();
    notifyListeners();
  }

  void _pruneExpired() {
    _movesByCell.removeWhere((_, e) => _elapsed >= e.startTime + e.duration);
    _vanishingMoves.removeWhere((e) => _elapsed >= e.startTime + e.duration);
    _bumpsByCell.removeWhere((_, e) => _elapsed >= e.startTime + e.duration);
    _hitsByCell.removeWhere((_, e) => _elapsed >= e.startTime + e.duration);
    _deaths.removeWhere((e) => _elapsed >= e.startTime + e.duration);
    _projectiles.removeWhere((e) => _elapsed >= e.startTime + e.duration);
    _particles.removeWhere((e) => _elapsed >= e.startTime + e.duration);
    _rings.removeWhere((e) => _elapsed >= e.startTime + e.duration);
    _floatingTexts.removeWhere((e) => _elapsed >= e.startTime + e.duration);
    if (_screenShake != null && _elapsed >= _screenShake!.startTime + _screenShake!.duration) {
      _screenShake = null;
    }
  }

  void _updateScreenShake() {
    final shake = _screenShake;
    if (shake == null) {
      if (screenShakeNotifier.value != Offset.zero) {
        screenShakeNotifier.value = Offset.zero;
      }
      return;
    }
    final t = _progress(shake.startTime, shake.duration);
    final decay = 1.0 - t;
    final dx = math.sin(t * math.pi * 6.0) * shake.amplitudePx * decay;
    final dy = math.cos(t * math.pi * 5.0) * shake.amplitudePx * 0.65 * decay;
    screenShakeNotifier.value = Offset(dx, dy);
  }

  /// C コアから届いたアニメーションイベントを登録する。
  /// 旧世代の遅延イベントや無効化中は即破棄する。
  void handleEvent(MapAnimEvent event) {
    // 持続状態の全クリア / 更新はターン境界スナップショットとして扱う
    if (event.eventType == MapAnimEventType.ambientStatus) {
      _handleAmbientStatus(event);
      return;
    }

    // フローティングテキストはメインアニメーション設定とは完全独立で制御
    if (event.eventType == MapAnimEventType.floatingText) {
      if (!_floatingTextEnabled) return;
      if (event.turnId < _minAcceptedTurnId) return;
      _handleFloatingText(event);
      if (hasActiveAnimations) {
        _ensureTickerRunning();
        notifyListeners();
      }
      return;
    }

    if (!_isEnabled) return;
    if (event.turnId < _minAcceptedTurnId) return;

    switch (event.eventType) {
      case MapAnimEventType.move:
        _handleMove(event);
        break;
      case MapAnimEventType.attack:
        _handleAttack(event);
        break;
      case MapAnimEventType.death:
        _handleDeath(event);
        break;
      case MapAnimEventType.projectile:
        _handleProjectile(event);
        break;
      case MapAnimEventType.objectMove:
        _handleObjectMove(event);
        break;
      case MapAnimEventType.vfx:
        _handleVfx(event);
        break;
      default:
        return;
    }

    if (hasActiveAnimations) {
      _ensureTickerRunning();
      notifyListeners();
    }
  }

  void _handleMove(MapAnimEvent event) {
    if (!_isValidCell(event.fromX, event.fromY) || !_isValidCell(event.toX, event.toY)) {
      return;
    }
    if (event.fromX == event.toX && event.fromY == event.toY) return;

    // もし移動元セルにまだ完了していない移動・バンプがあれば解除する
    _movesByCell.remove(_cellKey(event.fromX, event.fromY));
    _bumpsByCell.remove(_cellKey(event.fromX, event.fromY));

    final key = _cellKey(event.toX, event.toY);
    final int? fallbackTile = event.param1 > 0 || (event.param1 == 0 && event.param2 > 0)
        ? event.param1
        : null;
    final String? fallbackChar = event.param2 > 0 ? String.fromCharCode(event.param2) : null;
    final int? fallbackColor = event.param3 != 0 ? event.param3 : null;
    _movesByCell[key] = _MoveEntry(
      entityId: event.entityId,
      fromX: event.fromX,
      fromY: event.fromY,
      toX: event.toX,
      toY: event.toY,
      tile: fallbackTile,
      char: (fallbackChar != null && fallbackChar.isNotEmpty) ? fallbackChar : null,
      color: fallbackColor,
      enableHop: true,
      startTime: _elapsed,
      duration: _scaledDuration(_tuning.motion.moveMs),
    );
  }

  void _handleObjectMove(MapAnimEvent event) {
    if (!_isValidCell(event.fromX, event.fromY) || !_isValidCell(event.toX, event.toY)) {
      return;
    }
    if (event.fromX == event.toX && event.fromY == event.toY) return;

    final int? fallbackTile = event.param1 > 0 || (event.param1 == 0 && event.param2 > 0)
        ? event.param1
        : null;
    final String? fallbackChar = event.param2 > 0 ? String.fromCharCode(event.param2) : null;
    final int? fallbackColor = event.param3 != 0 ? event.param3 : null;

    if (event.entityId == MapObjectMoveKind.vanishing) {
      _vanishingMoves.add(_VanishingMoveEntry(
        fromX: event.fromX,
        fromY: event.fromY,
        toX: event.toX,
        toY: event.toY,
        tile: event.param1,
        char: (fallbackChar != null && fallbackChar.isNotEmpty) ? fallbackChar : '`',
        color: event.param3,
        startTime: _elapsed,
        duration: _scaledDuration(_tuning.motion.moveMs),
      ));
      return;
    }

    _movesByCell.remove(_cellKey(event.fromX, event.fromY));
    final key = _cellKey(event.toX, event.toY);
    _movesByCell[key] = _MoveEntry(
      entityId: -100,
      fromX: event.fromX,
      fromY: event.fromY,
      toX: event.toX,
      toY: event.toY,
      tile: fallbackTile,
      char: (fallbackChar != null && fallbackChar.isNotEmpty) ? fallbackChar : null,
      color: fallbackColor,
      enableHop: false,
      startTime: _elapsed,
      duration: _scaledDuration(_tuning.motion.moveMs),
    );
  }

  void _handleAttack(MapAnimEvent event) {
    if (!_isValidCell(event.fromX, event.fromY) || !_isValidCell(event.toX, event.toY)) {
      return;
    }
    final rawDx = (event.toX - event.fromX).toDouble();
    final rawDy = (event.toY - event.fromY).toDouble();
    final len = math.sqrt(rawDx * rawDx + rawDy * rawDy);
    if (len <= 0.0001) return;

    final dirX = rawDx / len;
    final dirY = rawDy / len;

    final attackerKey = _cellKey(event.fromX, event.fromY);
    _bumpsByCell[attackerKey] = _BumpEntry(
      cellX: event.fromX,
      cellY: event.fromY,
      dirX: dirX,
      dirY: dirY,
      startTime: _elapsed,
      duration: _scaledDuration(_tuning.motion.attackBumpMs),
    );

    final isHit = event.param1 != 0;
    if (isHit) {
      final targetKey = _cellKey(event.toX, event.toY);
      _hitsByCell[targetKey] = _HitEntry(
        cellX: event.toX,
        cellY: event.toY,
        startTime: _elapsed,
        duration: _scaledDuration(_tuning.motion.hitFeedbackMs),
        shakeSign: dirX != 0 ? (dirX > 0 ? 1.0 : -1.0) : 1.0,
      );
    }
  }

  void _handleDeath(MapAnimEvent event) {
    if (!_isValidCell(event.toX, event.toY)) return;
    final key = _cellKey(event.toX, event.toY);
    _movesByCell.remove(key);
    _bumpsByCell.remove(key);
    _hitsByCell.remove(key);
    _ambientStatusesByCell.remove(key);

    final charStr = event.param2 > 0 ? String.fromCharCode(event.param2) : ' ';
    _deaths.add(_DeathEntry(
      x: event.toX,
      y: event.toY,
      tile: event.param1,
      char: charStr.isNotEmpty ? charStr : ' ',
      color: event.param3,
      startTime: _elapsed,
      duration: _scaledDuration(_tuning.motion.deathFadeMs),
    ));
  }

  void _handleProjectile(MapAnimEvent event) {
    if (!_isValidCell(event.fromX, event.fromY) || !_isValidCell(event.toX, event.toY)) {
      return;
    }
    final charStr = event.param2 > 0 ? String.fromCharCode(event.param2) : '*';
    final safeChar = charStr.isNotEmpty ? charStr : '*';
    final endWp = _ProjectileWaypoint(
      x: event.toX,
      y: event.toY,
      tile: event.param1,
      char: safeChar,
      color: event.param3,
    );

    if (_projectiles.isNotEmpty) {
      final lastTrack = _projectiles.last;
      final lastWp = lastTrack.waypoints.last;
      if (lastTrack.turnId == event.turnId &&
          lastWp.x == event.fromX &&
          lastWp.y == event.fromY) {
        lastTrack.waypoints.add(endWp);
        final stepCount = math.max(1, lastTrack.waypoints.length - 1);
        final rawTotalMs = (stepCount * _tuning.motion.projectileStepMs * _speedMultiplier).round();
        final maxTotalMs = (_tuning.motion.projectileMaxTotalMs * _speedMultiplier).round();
        lastTrack.duration = Duration(milliseconds: rawTotalMs.clamp(40, math.max(40, maxTotalMs)));
        return;
      }
    }

    final startWp = _ProjectileWaypoint(
      x: event.fromX,
      y: event.fromY,
      tile: event.param1,
      char: safeChar,
      color: event.param3,
    );
    final waypoints = (event.fromX == event.toX && event.fromY == event.toY)
        ? [startWp]
        : [startWp, endWp];
    _projectiles.add(_ProjectileTrack(
      turnId: event.turnId,
      waypoints: waypoints,
      startTime: _elapsed,
      duration: _scaledDuration(_tuning.motion.projectileStepMs),
    ));
  }

  static Color _argbColor(int argb) => Color(argb | 0xFF000000);

  void _handleVfx(MapAnimEvent event) {
    if (!_isValidCell(event.toX, event.toY)) return;
    final cx = event.toX + 0.5;
    final cy = event.toY + 0.5;

    switch (event.entityId) {
      case MapVfxKind.dust:
        final p = _tuning.particleOf('dust');
        _spawnFromTuning(cx: cx, cy: cy + 0.25, tuning: p, color: _argbColor(p.defaultColor));
        break;
      case MapVfxKind.woodDebris:
        final isHeavy = event.param2 >= 2;
        final p = _tuning.particleOf(isHeavy ? 'woodDebrisHeavy' : 'woodDebrisLight');
        _spawnFromTuning(cx: cx, cy: cy, tuning: p, color: _argbColor(p.defaultColor));
        if (isHeavy) {
          _triggerScreenShake(_tuning.screenShake.doorBreakAmplitudePx);
        }
        break;
      case MapVfxKind.rockDebris:
        final p = _tuning.particleOf('rockDebris');
        _spawnFromTuning(cx: cx, cy: cy, tuning: p, color: _argbColor(p.defaultColor));
        break;
      case MapVfxKind.potionSplash:
        final p = _tuning.particleOf('potionSplash');
        // ゲーム内の薬色・幻覚ランダム色 (param1 != 0) を優先し、0 のみ defaultColor を使用
        final col = event.param1 != 0 ? _argbColor(event.param1) : _argbColor(p.defaultColor);
        _spawnFromTuning(cx: cx, cy: cy, tuning: p, color: col);
        break;
      case MapVfxKind.explosion:
        final p = _tuning.particleOf('explosion');
        final rOuter = _tuning.ringOf('explosionOuter');
        final rInner = _tuning.ringOf('explosionInner');
        final hasDynamicColor = event.param1 != 0;
        final outerCol = hasDynamicColor ? _argbColor(event.param1) : _argbColor(rOuter.color);
        final particleCol =
            hasDynamicColor ? _argbColor(event.param1) : _argbColor(p.defaultColor);
        _spawnRingFromTuning(x: cx, y: cy, tuning: rOuter, colorOverride: outerCol);
        _spawnRingFromTuning(x: cx, y: cy, tuning: rInner);
        _spawnFromTuning(cx: cx, cy: cy, tuning: p, color: particleCol);
        _triggerScreenShake(_tuning.screenShake.explosionAmplitudePx);
        break;
      case MapVfxKind.teleport:
        final p = _tuning.particleOf('teleport');
        final rDepart = _tuning.ringOf('teleportDepart');
        final rArrive = _tuning.ringOf('teleportArrive');
        if ((event.fromX != event.toX || event.fromY != event.toY) &&
            _isValidCell(event.fromX, event.fromY)) {
          _spawnRingFromTuning(
            x: event.fromX + 0.5,
            y: event.fromY + 0.5,
            tuning: rDepart,
          );
        }
        _spawnRingFromTuning(x: cx, y: cy, tuning: rArrive);
        _spawnFromTuning(cx: cx, cy: cy, tuning: p, color: _argbColor(p.defaultColor));
        break;
      case MapVfxKind.levelUp:
        final p = _tuning.particleOf('levelUp');
        final r = _tuning.ringOf('levelUp');
        _spawnRingFromTuning(x: cx, y: cy, tuning: r);
        _spawnFromTuning(cx: cx, cy: cy, tuning: p, color: _argbColor(p.defaultColor));
        break;
      case MapVfxKind.summon:
        final p = _tuning.particleOf('summon');
        final r = _tuning.ringOf('summon');
        // 幻覚時は param1 に非ゼロのランダム色が入る。非幻覚時は param2 の召喚種別から tuning 色を選択
        final Color summonCol;
        if (event.param1 != 0) {
          summonCol = _argbColor(event.param1);
        } else if (event.param2 == 1) {
          summonCol = _argbColor(_tuning.summonDemonColor);
        } else if (event.param2 == 2) {
          summonCol = _argbColor(_tuning.summonAngelColor);
        } else {
          summonCol = _argbColor(_tuning.summonNormalColor);
        }
        _spawnRingFromTuning(x: cx, y: cy, tuning: r, colorOverride: summonCol);
        _spawnFromTuning(cx: cx, cy: cy, tuning: p, color: summonCol);
        break;
      case MapVfxKind.kickImpact:
        final p = _tuning.particleOf('kickImpact');
        _spawnFromTuning(cx: cx, cy: cy, tuning: p, color: _argbColor(p.defaultColor));
        break;
      case MapVfxKind.bigHitShake:
        _triggerScreenShake(_tuning.screenShake.bigHitAmplitudePx);
        break;
      default:
        break;
    }
  }

  void _spawnFromTuning({
    required double cx,
    required double cy,
    required ParticleEffectTuning tuning,
    required Color color,
  }) {
    final duration = _scaledDuration(tuning.durationMs);
    final minSpd = math.min(tuning.speedMin, tuning.speedMax);
    final maxSpd = math.max(tuning.speedMin, tuning.speedMax);
    final minSz = math.min(tuning.sizeMin, tuning.sizeMax);
    final maxSz = math.max(tuning.sizeMin, tuning.sizeMax);

    for (int i = 0; i < tuning.count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final spd = minSpd + _rng.nextDouble() * (maxSpd - minSpd);
      final size = minSz + _rng.nextDouble() * (maxSz - minSz);
      _particles.add(_ParticleEntry(
        startX: cx + (_rng.nextDouble() - 0.5) * 0.25,
        startY: cy + (_rng.nextDouble() - 0.5) * 0.25,
        vx: math.cos(angle) * spd,
        vy: math.sin(angle) * spd,
        gravity: tuning.gravity,
        sizeRatio: size,
        color: color,
        isGlow: tuning.isGlow,
        startTime: _elapsed,
        duration: duration,
      ));
    }
    final maxParticles = math.max(1, _tuning.limits.maxParticles);
    if (_particles.length > maxParticles) {
      _particles.removeRange(0, _particles.length - maxParticles);
    }
  }

  void _spawnRingFromTuning({
    required double x,
    required double y,
    required RingEffectTuning tuning,
    Color? colorOverride,
  }) {
    _rings.add(_RingEntry(
      x: x,
      y: y,
      startRadiusCells: tuning.startRadiusCells,
      endRadiusCells: tuning.endRadiusCells,
      strokeRatio: tuning.strokeRatio,
      color: colorOverride ?? _argbColor(tuning.color),
      startTime: _elapsed,
      duration: _scaledDuration(tuning.durationMs),
    ));
    final maxRings = math.max(1, _tuning.limits.maxRings);
    if (_rings.length > maxRings) {
      _rings.removeRange(0, _rings.length - maxRings);
    }
  }

  void _triggerScreenShake(double amplitudePx) {
    if (amplitudePx <= 0.0) return;
    final current = _screenShake;
    if (current != null && current.amplitudePx > amplitudePx) {
      return;
    }
    _screenShake = _ScreenShakeEntry(
      amplitudePx: amplitudePx,
      startTime: _elapsed,
      duration: _scaledDuration(_tuning.screenShake.durationMs),
    );
    _updateScreenShake();
  }

  void _handleFloatingText(MapAnimEvent event) {
    if (!_isValidCell(event.toX, event.toY)) return;

    final ft = _tuning.floatingText;
    String? text;
    Color color = Colors.white;
    int priority = 50;

    switch (event.entityId) {
      case FloatingTextKind.dmgHero:
        if (event.param1 <= 0) return;
        text = '-${event.param1}';
        color = _argbColor(ft.dmgHeroColor);
        priority = 95;
        break;
      case FloatingTextKind.dmgMon:
        if (event.param1 <= 0) return;
        text = '-${event.param1}';
        color = event.param2 != 0 ? _argbColor(event.param2) : _argbColor(ft.dmgMonColor);
        priority = 85;
        break;
      case FloatingTextKind.miss:
        text = 'MISS';
        color = _argbColor(ft.missColor);
        priority = 30;
        break;
      case FloatingTextKind.healHp:
        if (event.param1 <= 0) return;
        text = '+${event.param1}';
        color = _argbColor(ft.healHpColor);
        priority = 70;
        break;
      case FloatingTextKind.healPw:
        if (event.param1 <= 0) return;
        text = '+${event.param1} Pw';
        color = _argbColor(ft.healPwColor);
        priority = 65;
        break;
      case FloatingTextKind.levelUp:
        text = 'LEVEL UP!';
        color = _argbColor(ft.levelUpColor);
        priority = 110;
        break;
      case FloatingTextKind.statusGain:
        text = StatusTextCode.resolveLabel(event.param1, isJapanese: isJapanese);
        if (text == null) return;
        color = StatusTextCode.resolveColor(event.param1, tuning: ft);
        priority = StatusTextCode.resolvePriority(event.param1);
        break;
      default:
        return;
    }

    final cellKey = _cellKey(event.toX, event.toY);
    final sameCellTurn = _floatingTexts
        .where((e) => e.cellKey == cellKey && e.turnId == event.turnId)
        .toList();

    if (sameCellTurn.any((e) => e.text == text)) {
      return;
    }

    final maxPerCell = math.max(1, _tuning.limits.maxFloatingTextsPerCellTurn);
    int stackIndex = sameCellTurn.length;
    if (sameCellTurn.length >= maxPerCell) {
      sameCellTurn.sort((a, b) => a.priority.compareTo(b.priority));
      final lowest = sameCellTurn.first;
      if (priority <= lowest.priority) {
        return;
      }
      stackIndex = lowest.stackIndex;
      _floatingTexts.remove(lowest);
    }

    final staggerDelay = Duration(
      milliseconds: (stackIndex * ft.staggerMs * _speedMultiplier).round().clamp(0, 1200),
    );
    _floatingTexts.add(_FloatingTextEntry(
      turnId: event.turnId,
      cellKey: cellKey,
      x: event.toX,
      y: event.toY,
      text: text,
      color: color,
      priority: priority,
      stackIndex: stackIndex,
      startTime: _elapsed + staggerDelay,
      duration: _scaledDuration(ft.durationMs),
    ));

    final maxTotal = math.max(1, _tuning.limits.maxFloatingTexts);
    if (_floatingTexts.length > maxTotal) {
      _floatingTexts.removeRange(0, _floatingTexts.length - maxTotal);
    }
  }

  void _handleAmbientStatus(MapAnimEvent event) {
    if (event.fromX < 0) {
      if (_ambientStatusesByCell.isNotEmpty) {
        _ambientStatusesByCell.clear();
        notifyListeners();
      }
      return;
    }
    if (!_isValidCell(event.toX, event.toY)) return;

    final key = _cellKey(event.toX, event.toY);
    final mask = event.entityId;
    final prev = _ambientStatusesByCell[key] ?? 0;

    if (mask == 0) {
      if (prev != 0) {
        _ambientStatusesByCell.remove(key);
        if (_isEnabled) {
          notifyListeners();
        }
      }
      return;
    }

    _ambientStatusesByCell[key] = mask;
    _ambientPhase = (_ambientPhase + _tuning.ambient.phaseStepPerTurn) % (math.pi * 2);
    if (_isEnabled) {
      notifyListeners();
    }
  }

  void _clearAnimationEffects({required bool includeFloatingTexts}) {
    _movesByCell.clear();
    _vanishingMoves.clear();
    _bumpsByCell.clear();
    _hitsByCell.clear();
    _deaths.clear();
    _projectiles.clear();
    _particles.clear();
    _rings.clear();
    _screenShake = null;
    if (screenShakeNotifier.value != Offset.zero) {
      screenShakeNotifier.value = Offset.zero;
    }
    if (includeFloatingTexts) {
      _floatingTexts.clear();
    }
    _stopTickerIfIdle();
  }

  /// 進行中の全短期アニメーションを即座に完了状態へスナップ（クリア）する。
  /// [minAcceptedTurnId] を指定した場合、それより古い世代の遅延イベントを以後破棄する。
  /// 持続的な状態マイクロ演出（_ambientStatusesByCell）は保持する。
  void snapAll({int? minAcceptedTurnId}) {
    if (minAcceptedTurnId != null && minAcceptedTurnId > _minAcceptedTurnId) {
      _minAcceptedTurnId = minAcceptedTurnId;
    }

    final hadAny = hasActiveAnimations;
    _clearAnimationEffects(includeFloatingTexts: true);

    if (hadAny) {
      notifyListeners();
    }
  }

  /// 持続状態を含む全ビジュアル状態をリセットする（マップ切替・ゲーム終了時用）。
  void clearAll() {
    final hadAny = hasAnyVisuals;
    _ambientStatusesByCell.clear();
    _clearAnimationEffects(includeFloatingTexts: true);
    if (hadAny) {
      notifyListeners();
    }
  }

  /// マスク・オーバーレイ描画対象となるセルのキー (`y * 80 + x`) 集合を返す。
  Iterable<int> get animatedCellKeys {
    if (!hasAnyVisuals) return const [];
    final keys = <int>{};
    keys.addAll(_movesByCell.keys);
    keys.addAll(_bumpsByCell.keys);
    keys.addAll(_hitsByCell.keys);
    if (_isEnabled && _canLiftFloatingGlyph) {
      for (final entry in _ambientStatusesByCell.entries) {
        if ((entry.value & AmbientStatusBits.levitating) != 0) {
          keys.add(entry.key);
        }
      }
    }
    return keys;
  }

  /// 指定セル `(x, y)` における現在フレームの描画オフセット・フラッシュ状態を返す。
  CellAnimTransform? getCellTransform(int x, int y) {
    final key = _cellKey(x, y);
    final move = _movesByCell[key];
    final bump = _bumpsByCell[key];
    final hit = _hitsByCell[key];
    final ambientMask = _isEnabled ? (_ambientStatusesByCell[key] ?? 0) : 0;
    final isFloating = _canLiftFloatingGlyph && (ambientMask & AmbientStatusBits.levitating) != 0;

    if (move == null && bump == null && hit == null && !isFloating) {
      return null;
    }

    final motion = _tuning.motion;
    double moveDx = 0.0;
    double moveDy = 0.0;
    double flashAlpha = 0.0;

    if (move != null) {
      final t = _progress(move.startTime, move.duration);
      final eased = Curves.easeOutQuad.transform(t);
      final remain = 1.0 - eased;
      moveDx += (move.fromX - move.toX) * remain;
      moveDy += (move.fromY - move.toY) * remain;
      if (move.enableHop && !isFloating) {
        moveDy -= math.sin(t * math.pi) * motion.moveHopHeightRatio;
      }
    }

    if (bump != null) {
      final t = _progress(bump.startTime, bump.duration);
      final dist = motion.attackBumpDistance;
      final double amount;
      if (t < 0.35) {
        amount = Curves.easeOut.transform(t / 0.35) * dist;
      } else {
        amount = (1.0 - Curves.easeInOut.transform((t - 0.35) / 0.65)) * dist;
      }
      moveDx += bump.dirX * amount;
      moveDy += bump.dirY * amount;
    }

    if (hit != null) {
      final t = _progress(hit.startTime, hit.duration);
      final decay = 1.0 - t;
      moveDx += math.sin(t * math.pi * 4.0) * motion.hitShakeRatio * decay * hit.shakeSign;
      flashAlpha = (motion.hitFlashAlpha * decay).clamp(0.0, 1.0);
    }

    final floatLiftDy = isFloating ? _tuning.ambient.floatLiftDy : 0.0;

    return CellAnimTransform(
      moveDx: moveDx,
      moveDy: moveDy,
      floatLiftDy: floatLiftDy,
      isFloating: isFloating,
      flashAlpha: flashAlpha,
      flashColor: _argbColor(motion.hitFlashColor),
      fallbackTile: move?.tile,
      fallbackChar: move?.char,
      fallbackColor: move?.color,
    );
  }

  /// 消滅する岩押し等（穴埋め・落とし穴・水没・テレポ罠）の現在スナップショット一覧
  List<VanishingObjectMoveSnapshot> get activeVanishingObjectMoves {
    if (_vanishingMoves.isEmpty) return const [];
    final fadeStart = _tuning.motion.vanishFadeStartT.clamp(0.05, 0.95);
    final endScale = _tuning.motion.vanishEndScale.clamp(0.1, 1.0);
    return _vanishingMoves.map((m) {
      final t = _progress(m.startTime, m.duration);
      final eased = Curves.easeOutQuad.transform(t);
      final x = m.fromX + (m.toX - m.fromX) * eased;
      final y = m.fromY + (m.toY - m.fromY) * eased;
      final fadeT = t <= fadeStart ? 0.0 : ((t - fadeStart) / (1.0 - fadeStart)).clamp(0.0, 1.0);
      final opacity = (1.0 - fadeT).clamp(0.0, 1.0);
      final scale = 1.0 - (1.0 - endScale) * fadeT;
      return VanishingObjectMoveSnapshot(
        x: x,
        y: y,
        tile: m.tile,
        char: m.char,
        color: m.color,
        opacity: opacity,
        scale: scale,
      );
    }).toList(growable: false);
  }

  /// 現在再生中の死亡フェードアウト一覧を返す。
  List<DeathFadeSnapshot> get activeDeathFades {
    if (_deaths.isEmpty) return const [];
    final endScale = _tuning.motion.deathEndScale.clamp(0.1, 1.0);
    return _deaths.map((d) {
      final t = _progress(d.startTime, d.duration);
      final opacity = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
      final scale = 1.0 - (1.0 - endScale) * t;
      return DeathFadeSnapshot(
        x: d.x,
        y: d.y,
        tile: d.tile,
        char: d.char,
        color: d.color,
        opacity: opacity,
        scale: scale,
      );
    }).toList(growable: false);
  }

  /// 現在再生中の飛び道具・光線の補間位置一覧を返す。
  List<ProjectileSnapshot> get activeProjectiles {
    if (_projectiles.isEmpty) return const [];
    final results = <ProjectileSnapshot>[];
    for (final track in _projectiles) {
      if (track.waypoints.isEmpty) continue;
      if (track.waypoints.length == 1) {
        final wp = track.waypoints.first;
        results.add(ProjectileSnapshot(
          x: wp.x.toDouble(),
          y: wp.y.toDouble(),
          tile: wp.tile,
          char: wp.char,
          color: wp.color,
        ));
        continue;
      }
      final t = _progress(track.startTime, track.duration);
      final segCount = track.waypoints.length - 1;
      final scaled = (t * segCount).clamp(0.0, segCount.toDouble());
      final idx = math.min(segCount - 1, scaled.floor());
      final localT = scaled - idx;
      final a = track.waypoints[idx];
      final b = track.waypoints[idx + 1];
      results.add(ProjectileSnapshot(
        x: a.x + (b.x - a.x) * localT,
        y: a.y + (b.y - a.y) * localT,
        tile: b.tile,
        char: b.char,
        color: b.color,
      ));
    }
    return results;
  }

  /// 現在再生中のドット粒・発光粒パーティクル一覧を返す。
  List<ParticleSnapshot> get activeParticles {
    if (_particles.isEmpty) return const [];
    return _particles.map((p) {
      final t = _progress(p.startTime, p.duration);
      final dtSec = t * (p.duration.inMicroseconds / 1000000.0);
      final x = p.startX + p.vx * dtSec;
      final y = p.startY + p.vy * dtSec + 0.5 * p.gravity * dtSec * dtSec;
      final opacity = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
      return ParticleSnapshot(
        x: x,
        y: y,
        sizeRatio: p.sizeRatio * (1.0 - 0.3 * t),
        color: p.color,
        opacity: opacity,
        isGlow: p.isGlow,
      );
    }).toList(growable: false);
  }

  /// 現在再生中の同心円光リング一覧を返す。
  List<RingEffectSnapshot> get activeRings {
    if (_rings.isEmpty) return const [];
    return _rings.map((r) {
      final t = _progress(r.startTime, r.duration);
      final eased = Curves.easeOutCubic.transform(t);
      final radius = r.startRadiusCells + (r.endRadiusCells - r.startRadiusCells) * eased;
      final opacity = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
      return RingEffectSnapshot(
        x: r.x,
        y: r.y,
        radiusCells: radius,
        strokeRatio: r.strokeRatio * (1.0 - 0.4 * t),
        color: r.color,
        opacity: opacity,
      );
    }).toList(growable: false);
  }

  /// 現在再生中のフローティングテキスト一覧を返す（スタガー開始前の項目は除外）。
  List<FloatingTextSnapshot> get activeFloatingTexts {
    if (_floatingTexts.isEmpty) return const [];
    final ft = _tuning.floatingText;
    final popExtra = math.max(0.0, ft.popScaleMax - 1.0);
    final results = <FloatingTextSnapshot>[];
    for (final f in _floatingTexts) {
      if (_elapsed < f.startTime) continue;
      final t = _progress(f.startTime, f.duration);
      final eased = Curves.easeOutCubic.transform(t);
      final stackOffset = -f.stackIndex * ft.stackSpacingCells;
      final floatUp = -ft.riseCells * eased;
      final scale = t < 0.15
          ? (0.85 + (0.15 + popExtra) * (t / 0.15))
          : (t < 0.30 ? (ft.popScaleMax - popExtra * ((t - 0.15) / 0.15)) : 1.0);
      final opacity = t < 0.70 ? 1.0 : (1.0 - (t - 0.70) / 0.30).clamp(0.0, 1.0);
      results.add(FloatingTextSnapshot(
        x: f.x,
        y: f.y,
        text: f.text,
        color: f.color,
        opacity: opacity,
        scale: scale,
        yOffsetCells: -0.25 + stackOffset + floatUp,
      ));
    }
    return results;
  }

  /// 持続的な状態マイクロ演出が有効なセル一覧を返す。
  List<AmbientCellStatusSnapshot> get activeAmbientStatuses {
    if (!hasAmbientStatuses) return const [];
    final results = <AmbientCellStatusSnapshot>[];
    for (final entry in _ambientStatusesByCell.entries) {
      final y = entry.key ~/ NetHackScreen.mapCols;
      final x = entry.key % NetHackScreen.mapCols;
      if (!_isValidCell(x, y)) continue;
      final transform = getCellTransform(x, y);
      results.add(AmbientCellStatusSnapshot(
        x: x,
        y: y,
        mask: entry.value,
        phase: _ambientPhase,
        moveDx: transform?.moveDx ?? 0.0,
        moveDy: transform?.moveDy ?? 0.0,
      ));
    }
    return results;
  }

  double _progress(Duration startTime, Duration duration) {
    if (duration <= Duration.zero) return 1.0;
    final p = (_elapsed - startTime).inMicroseconds / duration.inMicroseconds;
    return p.clamp(0.0, 1.0);
  }

  static bool _isValidCell(int x, int y) {
    return x >= 0 && x < NetHackScreen.mapCols && y >= 0 && y < NetHackScreen.mapRows;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    screenShakeNotifier.dispose();
    super.dispose();
  }
}

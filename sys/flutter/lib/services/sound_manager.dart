import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// サウンドカテゴリ（Cコアの sound_category と完全同期）
enum SoundCategory {
  se(1),
  heroMusic(2),
  achievement(3),
  bgm(4),
  voice(5),
  ambience(6);

  final int value;
  const SoundCategory(this.value);

  static SoundCategory fromValue(int val) {
    return SoundCategory.values.firstWhere(
      (e) => e.value == val,
      orElse: () => SoundCategory.se,
    );
  }
}

/// 音声再生プール用エントリ
class _PlayerEntry {
  final AudioPlayer player;
  String? currentSound;
  DateTime lastPlayTime;
  bool isPlaying = false;

  _PlayerEntry(this.player) : lastPlayTime = DateTime.now();
}

/// DartHack サウンド再生管理マネージャー
class SoundManager {
  static final SoundManager instance = SoundManager._internal();
  SoundManager._internal();

  static const int _maxConcurrentPlayers = 12;
  static const int _maxSameSoundInstances = 3;
  static const int _seCooldownMs = 60;
  static const int _microDelayThresholdMs = 25; // 同一フレーム内の二連撃判定閾値
  static const int _microDelayIntervalMs = 35;  // 二連撃のディレイ時間
  static const int _ambientCombatThrottleWindowMs = 100; // 環境戦闘SEスロットル窓
  static const int _maxAmbientCombatSePerWindow = 2;     // 窓あたりの最大環境戦闘SE数
  static const String _soundAssetPrefix = 'assets/sounds/';

  /// 重要・警告効果音（戦闘SEより優先して発音を保証）
  static const Set<String> _criticalSoundEffects = {
    'se_alarm.ogg',
    'se_wailing_of_the_banshee.ogg',
    'se_thunderclap.ogg',
    'se_glass_break.ogg',
    'se_crash.ogg',
    'se_trap_door_explodes.ogg',
    'se_flee_screaming.ogg',
    'se_potion_crash_and_break.ogg',
  };

  /// 2.1 ダンジョン分岐および固定特殊階層（フロア全体BGM）の定義セット
  static const Set<String> _floorBgmFiles = {
    // 2.1.1 主要分岐
    'amb_dungeon.ogg', 'amb_mines.ogg', 'amb_sokoban.ogg', 'amb_quest.ogg',
    'amb_gehennom.ogg', 'amb_vlad.ogg', 'amb_ludios.ogg', 'amb_tutorial.ogg',
    // 2.1.2 運命の大迷宮の特殊階層
    'amb_oracle.ogg', 'amb_rogue.ogg', 'amb_bigroom.ogg', 'amb_medusa.ogg', 'amb_castle.ogg',
    // 2.1.3 各分岐ダンジョンの特殊階層
    'amb_town.ogg', 'amb_minend.ogg', 'amb_sokoend.ogg', 'amb_quest_nemesis.ogg',
    // 2.1.4 ゲヘナ・悪魔階層
    'amb_valley.ogg', 'amb_juiblex.ogg', 'amb_baalzebub.ogg', 'amb_asmodeus.ogg',
    'amb_orcus.ogg', 'amb_wizard_tower.ogg', 'amb_fakewiz.ogg', 'amb_sanctum.ogg',
    // 2.1.5 精霊界
    'amb_plane_earth.ogg', 'amb_plane_air.ogg', 'amb_plane_fire.ogg',
    'amb_plane_water.ogg', 'amb_astral.ogg',
    // 2.1.6 システム・特殊
    'amb_title.ogg', 'amb_gameover.ogg', 'amb_ascension.ogg',
  };

  /// 2.2 地形・天候環境音のセット（フロアBGMと同時に再生）
  static const Set<String> _terrainAmbienceFiles = {
    'amb_water.ogg', 'amb_lava.ogg', 'amb_wind.ogg', 'amb_rain.ogg', 'amb_swamp.ogg',
  };

  final List<_PlayerEntry> _pool = [];
  AudioPlayer? _floorBgmPlayer;
  String? _currentFloorBgm;
  String? _lastFloorBgm;
  AudioPlayer? _roomBgmPlayer;
  String? _currentRoomBgm;
  AudioPlayer? _ambiencePlayer;
  String? _currentAmbience;
  String? _lastAmbience;

  final Set<String> _availableSounds = {};
  final Map<String, DateTime> _lastPlayTimeBySound = {};
  final Set<String> _pendingDoubleStrikes = {};
  final List<DateTime> _ambientCombatSePlayTimes = [];
  bool _isInitialized = false;

  int _floorFadeGen = 0;
  int _roomFadeGen = 0;
  bool _floorWasPlayingBeforeBackground = false;
  bool _roomWasPlayingBeforeBackground = false;
  bool _ambienceWasPlayingBeforeBackground = false;

  double _seVolume = 0.8;
  double _bgmVolume = 0.5;
  double _ambienceVolume = 0.6;
  double _voiceVolume = 0.8;
  bool _muted = false;
  bool _bgmEnabled = true;
  bool _seEnabled = true;
  bool _ambienceEnabled = true;

  double get seVolume => _seVolume;
  double get bgmVolume => _bgmVolume;
  double get ambienceVolume => _ambienceVolume;
  double get voiceVolume => _voiceVolume;
  bool get isMuted => _muted;
  bool get bgmEnabled => _bgmEnabled;
  bool get seEnabled => _seEnabled;
  bool get ambienceEnabled => _ambienceEnabled;

  /// 現在再生中のBGMファイル名（ルームBGMが再生中ならそれを、それ以外はフロアBGM）
  String? get currentBgm => _currentRoomBgm ?? _currentFloorBgm;
  String? get currentFloorBgm => _currentFloorBgm;
  String? get currentRoomBgm => _currentRoomBgm;

  /// 初期化: アセット一覧のスキャンとプレイヤーのプール生成
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _seVolume = prefs.getDouble('sound_se_volume') ?? 0.8;
      _bgmVolume = prefs.getDouble('sound_bgm_volume') ?? 0.5;
      _ambienceVolume = prefs.getDouble('sound_ambience_volume') ?? 0.6;
      _voiceVolume = prefs.getDouble('sound_voice_volume') ?? 0.8;
      _muted = prefs.getBool('sound_muted') ?? false;
      _bgmEnabled = prefs.getBool('sound_bgm_enabled') ?? true;
      _seEnabled = prefs.getBool('sound_se_enabled') ?? true;
      _ambienceEnabled = prefs.getBool('sound_ambience_enabled') ?? true;

      // アセットマニフェストから利用可能な音声一覧をインデックス化
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();
      for (final asset in allAssets) {
        if (asset.startsWith(_soundAssetPrefix)) {
          final filename = asset.substring(_soundAssetPrefix.length);
          if (filename.isNotEmpty && filename != '.gitkeep') {
            _availableSounds.add(filename);
          }
        }
      }

      // SEプレイヤープールを初期化 (最大12個)
      for (int i = 0; i < _maxConcurrentPlayers; i++) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        final entry = _PlayerEntry(player);
        player.onPlayerComplete.listen((_) {
          entry.isPlaying = false;
          entry.currentSound = null;
        });
        _pool.add(entry);
      }

      // フロアBGMプレイヤー
      _floorBgmPlayer = AudioPlayer();
      await _floorBgmPlayer!.setReleaseMode(ReleaseMode.loop);

      // ルームBGMプレイヤー
      _roomBgmPlayer = AudioPlayer();
      await _roomBgmPlayer!.setReleaseMode(ReleaseMode.loop);

      // 環境音（アンビエンス）プレイヤー
      _ambiencePlayer = AudioPlayer();
      await _ambiencePlayer!.setReleaseMode(ReleaseMode.loop);

      _isInitialized = true;
    } catch (_) {
      _isInitialized = true;
    }
  }

  /// サウンドファイルがアセットに存在するか確認
  bool hasSound(String filename) {
    return _availableSounds.contains(filename);
  }

  /// Cコアからのサウンドイベントをディスパッチ
  void handleSoundEvent(Map<dynamic, dynamic> event) {
    if (!_isInitialized || _muted) return;

    final catVal = event['category'] as int? ?? 1;
    final category = SoundCategory.fromValue(catVal);
    final filename = event['filename'] as String? ?? '';
    final text = event['text'] as String? ?? '';
    final volume = (event['volume'] as int? ?? 100).clamp(0, 100);
    final loopOrFlag = event['loopOrFlag'] as int? ?? 0;

    switch (category) {
      case SoundCategory.se:
        final isCrit = _criticalSoundEffects.contains(filename);
        if (_seEnabled) _playSe(filename, volume, isCritical: isCrit);
        break;
      case SoundCategory.achievement:
        if (_seEnabled) _playSe(filename, volume, isCritical: true);
        break;
      case SoundCategory.heroMusic:
        if (_seEnabled) _playInstrument(filename, text, volume, loopOrFlag != 0);
        break;
      case SoundCategory.bgm:
        if (_bgmEnabled) _playBgm(filename, volume, loopOrFlag);
        break;
      case SoundCategory.ambience:
        if (_terrainAmbienceFiles.contains(filename)) {
          // 2.2 地形・天候環境音（フロアBGMと同時に再生・距離減衰あり）
          if (_ambienceEnabled) _playAmbience(filename, volume, loopOrFlag);
        } else {
          // 2.3 特別な部屋・施設・テーマ部屋（フロアBGMとクロスフェードするルームBGM）
          if (_bgmEnabled) _playBgm(filename, volume, loopOrFlag);
        }
        break;
      case SoundCategory.voice:
        _playVoice(filename, text, volume);
        break;
    }
  }

  /// 効果音の再生（スロットル判定、二連撃マイクロディレイ、デバウンス制御）
  Future<void> _playSe(String filename, int cVolume, {bool isCritical = false}) async {
    if (!_seEnabled || filename.isEmpty || !hasSound(filename) || _pool.isEmpty) return;

    final now = DateTime.now();
    final isCombatSe = filename.startsWith('se_combat_') || filename.startsWith('se_mon_');
    final isAmbientCombat = isCombatSe && cVolume < 100;

    // 1. 環境戦闘SEスロットル機構（第三者同士の戦闘で密集時の音響飽和防止）
    if (isAmbientCombat) {
      _ambientCombatSePlayTimes.removeWhere(
        (t) => now.difference(t).inMilliseconds >= _ambientCombatThrottleWindowMs,
      );
      if (_ambientCombatSePlayTimes.length >= _maxAmbientCombatSePerWindow) {
        return; // 100ms枠内の環境戦闘SE上限に達したためスキップ
      }
    }

    // 2. 二連撃マイクロディレイ & デバウンス制御
    final lastPlay = _lastPlayTimeBySound[filename];
    if (lastPlay != null) {
      final diffMs = now.difference(lastPlay).inMilliseconds;
      if (diffMs < _seCooldownMs) {
        // 同一フレーム（0〜25ms以内）の二連撃（二刀流やモンスター爪×2）であり、まだ保留中でなければディレイ再生
        if (diffMs < _microDelayThresholdMs && !_pendingDoubleStrikes.contains(filename)) {
          _pendingDoubleStrikes.add(filename);
          Future.delayed(const Duration(milliseconds: _microDelayIntervalMs), () {
            _pendingDoubleStrikes.remove(filename);
            _executePlaySe(filename, cVolume, isCritical: isCritical);
          });
        }
        return; // 1発目のデバウンスとしてはここでリターン
      }
    }

    await _executePlaySe(filename, cVolume, isCritical: isCritical);
  }

  /// 効果音の実再生処理（優先度判定・空きプレイヤー取得・再生）
  Future<void> _executePlaySe(String filename, int cVolume, {bool isCritical = false}) async {
    if (!_seEnabled || _pool.isEmpty) return;

    final now = DateTime.now();
    _lastPlayTimeBySound[filename] = now;

    final isCombatSe = filename.startsWith('se_combat_') || filename.startsWith('se_mon_');
    if (isCombatSe && cVolume < 100) {
      _ambientCombatSePlayTimes.add(now);
    }

    // 同一サウンドの重複上限チェック (最大3音)
    int sameCount = 0;
    for (final entry in _pool) {
      if (entry.isPlaying && entry.currentSound == filename) {
        sameCount++;
      }
    }
    if (sameCount >= _maxSameSoundInstances) {
      return; // 同一音が密集しすぎているためスキップ
    }

    // 空きプレイヤーの取得
    _PlayerEntry? targetEntry;
    for (final entry in _pool) {
      if (!entry.isPlaying) {
        targetEntry = entry;
        break;
      }
    }

    // 空きがない場合の再利用（重要音は戦闘SEプレイヤーを優先的にプリエンプト）
    if (targetEntry == null) {
      if (isCritical) {
        for (final entry in _pool) {
          final cur = entry.currentSound ?? '';
          if (cur.startsWith('se_combat_') || cur.startsWith('se_mon_')) {
            targetEntry = entry;
            break;
          }
        }
      }
      targetEntry ??= _pool.reduce((a, b) => a.lastPlayTime.isBefore(b.lastPlayTime) ? a : b);
      try {
        await targetEntry.player.stop();
      } catch (_) {}
    }

    targetEntry.isPlaying = true;
    targetEntry.currentSound = filename;
    targetEntry.lastPlayTime = now;

    final finalVolume = (_seVolume * (cVolume / 100.0)).clamp(0.0, 1.0);
    try {
      await targetEntry.player.setVolume(finalVolume);
      await targetEntry.player.play(AssetSource('sounds/$filename'));
    } catch (_) {
      targetEntry.isPlaying = false;
      targetEntry.currentSound = null;
    }
  }

  /// 楽器演奏シーケンス
  Future<void> _playInstrument(String baseResource, String notes, int volume, bool isSingleFile) async {
    if (isSingleFile) {
      await _playSe(baseResource, volume);
      return;
    }

    if (notes.isEmpty) return;

    // 音符（A〜G）ごとに約120ms間隔で非同期に順次再生
    for (int i = 0; i < notes.length; i++) {
      final ch = notes[i].toUpperCase();
      if (ch.compareTo('A') >= 0 && ch.compareTo('G') <= 0) {
        final noteFile = '${baseResource}_$ch.ogg';
        unawaited(_playSe(noteFile, volume));
      }
      if (i < notes.length - 1) {
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }
  }

  /// フェードアウト処理 (pauseInsteadOfStop == true の場合は pause)
  Future<void> _fadeOut(AudioPlayer? player, double baseVolume, {bool pauseInsteadOfStop = false, bool isRoomPlayer = false}) async {
    if (player == null || (player.state != PlayerState.playing)) return;
    final int gen = isRoomPlayer ? ++_roomFadeGen : ++_floorFadeGen;
    try {
      for (int i = 5; i >= 1; i--) {
        if ((isRoomPlayer ? _roomFadeGen : _floorFadeGen) != gen) return;
        await player.setVolume(baseVolume * (i / 6.0));
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if ((isRoomPlayer ? _roomFadeGen : _floorFadeGen) != gen) return;
      if (pauseInsteadOfStop) {
        await player.pause();
      } else {
        await player.stop();
      }
    } catch (_) {}
  }

  /// フェードイン処理
  Future<void> _fadeIn(AudioPlayer? player, double targetVolume, {bool isRoomPlayer = false}) async {
    if (player == null) return;
    final int gen = isRoomPlayer ? ++_roomFadeGen : ++_floorFadeGen;
    try {
      await player.setVolume(0.0);
      for (int i = 1; i <= 6; i++) {
        if ((isRoomPlayer ? _roomFadeGen : _floorFadeGen) != gen) return;
        await Future.delayed(const Duration(milliseconds: 50));
        if ((isRoomPlayer ? _roomFadeGen : _floorFadeGen) != gen) return;
        await player.setVolume(targetVolume * (i / 6.0));
      }
    } catch (_) {}
  }

  /// BGMの再生制御（action: 0=nothing, 1=begin, 2=end, 3=update）
  Future<void> _playBgm(String filename, int proximity, int action) async {
    if (filename.isEmpty) return;

    final isFloorBgm = _floorBgmFiles.contains(filename);

    if (isFloorBgm) {
      // --- フロア全体のBGM ---
      if (action == 2) {
        await stopBgm();
        return;
      }

      if (!hasSound(filename)) {
        if (_currentFloorBgm != null && action == 1) {
          await stopBgm();
        }
        return;
      }

      // 同一フロアBGMが既に再生中の場合は継続再生
      if (_currentFloorBgm == filename && _floorBgmPlayer?.state == PlayerState.playing) {
        return;
      }

      try {
        // ルームBGMが鳴っていれば停止
        if (_roomBgmPlayer?.state == PlayerState.playing) {
          await _fadeOut(_roomBgmPlayer, _bgmVolume, isRoomPlayer: true);
          _currentRoomBgm = null;
        }

        // 旧フロアBGMをフェードアウト停止
        if (_floorBgmPlayer?.state == PlayerState.playing) {
          await _fadeOut(_floorBgmPlayer, _bgmVolume, isRoomPlayer: false);
        }

        _currentFloorBgm = filename;
        _lastFloorBgm = filename;
        await _floorBgmPlayer?.setReleaseMode(ReleaseMode.loop);
        await _floorBgmPlayer?.setVolume(0.0);
        await _floorBgmPlayer?.play(AssetSource('sounds/$filename'));
        unawaited(_fadeIn(_floorBgmPlayer, _bgmVolume, isRoomPlayer: false));
      } catch (_) {}
    } else {
      // --- 2.3 特別な部屋・テーマ部屋（ルームBGM） ---
      if (action == 1) {
        // 部屋進入時
        if (!hasSound(filename)) {
          // 【重要】ルームBGMファイルが無い場合はフロアBGMを止めずにそのまま継続再生
          return;
        }

        if (_currentRoomBgm == filename && _roomBgmPlayer?.state == PlayerState.playing) {
          return;
        }

        try {
          // フロアBGMをフェードアウトして一時停止（pause）
          if (_floorBgmPlayer?.state == PlayerState.playing) {
            await _fadeOut(_floorBgmPlayer, _bgmVolume, pauseInsteadOfStop: true, isRoomPlayer: false);
          }

          _currentRoomBgm = filename;
          await _roomBgmPlayer?.setReleaseMode(ReleaseMode.loop);
          await _roomBgmPlayer?.setVolume(0.0);
          await _roomBgmPlayer?.play(AssetSource('sounds/$filename'));
          unawaited(_fadeIn(_roomBgmPlayer, _bgmVolume, isRoomPlayer: true));
        } catch (_) {}
      } else if (action == 2) {
        // 部屋退出時
        if (_currentRoomBgm == filename) {
          // 実際にルームBGMが再生されていた場合のみフェードアウト停止し、フロアBGMへ復帰
          _currentRoomBgm = null;
          try {
            await _fadeOut(_roomBgmPlayer, _bgmVolume, isRoomPlayer: true);

            if (_currentFloorBgm != null && hasSound(_currentFloorBgm!)) {
              await _floorBgmPlayer?.resume();
              unawaited(_fadeIn(_floorBgmPlayer, _bgmVolume, isRoomPlayer: false));
            }
          } catch (_) {}
        } else {
          // ファイルが無くて再生されていなかった場合はフロアBGMを継続（何もしない）
        }
      }
    }
  }

  Future<void> stopBgm() async {
    _currentRoomBgm = null;
    _currentFloorBgm = null;
    try {
      if (_roomBgmPlayer != null && _roomBgmPlayer!.state == PlayerState.playing) {
        await _fadeOut(_roomBgmPlayer, _bgmVolume, isRoomPlayer: true);
      }
      if (_floorBgmPlayer != null && _floorBgmPlayer!.state == PlayerState.playing) {
        await _fadeOut(_floorBgmPlayer, _bgmVolume, isRoomPlayer: false);
      }
    } catch (_) {}
  }

  /// 環境音（アンビエンス）の再生制御
  Future<void> _playAmbience(String filename, int proximity, int action) async {
    if (action == 2 || filename.isEmpty) {
      await stopAmbience();
      return;
    }

    if (!hasSound(filename)) {
      if (_currentAmbience != null && action == 1) {
        await stopAmbience();
      }
      return;
    }

    // 距離に応じた音量スケーリング (proximity == 0 は減衰なし)
    double distanceFactor = 1.0;
    if (proximity > 0) {
      distanceFactor = (1.0 - (proximity * 0.08)).clamp(0.1, 1.0);
    }
    final finalVolume = (_ambienceVolume * distanceFactor).clamp(0.0, 1.0);

    if (action == 3) {
      // ambience_update: 音量更新
      try {
        await _ambiencePlayer?.setVolume(finalVolume);
      } catch (_) {}
      return;
    }

    // ambience_begin: 同一環境音が既に再生中の場合は音量更新のみ
    if (_currentAmbience == filename && _ambiencePlayer?.state == PlayerState.playing) {
      await _ambiencePlayer?.setVolume(finalVolume);
      return;
    }

    try {
      _currentAmbience = filename;
      _lastAmbience = filename;
      await _ambiencePlayer?.setVolume(finalVolume);
      await _ambiencePlayer?.setReleaseMode(ReleaseMode.loop);
      await _ambiencePlayer?.play(AssetSource('sounds/$filename'));
    } catch (_) {}
  }

  Future<void> stopAmbience() async {
    try {
      await _ambiencePlayer?.stop();
      _currentAmbience = null;
    } catch (_) {}
  }

  /// 声音・TTS
  Future<void> _playVoice(String filename, String text, int cVolume) async {
    if (filename.isNotEmpty && hasSound(filename)) {
      final finalVolume = (_voiceVolume * (cVolume / 100.0)).clamp(0.0, 1.0);
      await _playSe(filename, (finalVolume * 100).round());
    }
  }

  // 設定変更
  Future<void> setMuted(bool mute) async {
    _muted = mute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_muted', mute);
    if (mute) {
      await stopAll();
    } else {
      // ミュート解除時、直前のフロアBGM・環境音を自動復帰
      if (_bgmEnabled && _currentFloorBgm == null && _lastFloorBgm != null) {
        unawaited(_playBgm(_lastFloorBgm!, 0, 1));
      }
      if (_ambienceEnabled && _currentAmbience == null && _lastAmbience != null) {
        unawaited(_playAmbience(_lastAmbience!, 0, 1));
      }
    }
  }

  /// スライダー操作中のリアルタイム音量反映（ディスクI/Oなし）
  void updateSeVolume(double vol) {
    _seVolume = vol.clamp(0.0, 1.0);
  }

  /// スライダー操作完了時等の永続化付きSE音量設定
  Future<void> setSeVolume(double vol) async {
    updateSeVolume(vol);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_se_volume', _seVolume);
  }

  /// スライダー操作中のリアルタイム音量反映（ディスクI/Oなし）
  void updateBgmVolume(double vol) {
    _bgmVolume = vol.clamp(0.0, 1.0);
    if (_floorBgmPlayer != null && _floorBgmPlayer!.state == PlayerState.playing) {
      _floorBgmPlayer!.setVolume(_bgmVolume);
    }
    if (_roomBgmPlayer != null && _roomBgmPlayer!.state == PlayerState.playing) {
      _roomBgmPlayer!.setVolume(_bgmVolume);
    }
  }

  /// スライダー操作完了時等の永続化付きBGM音量設定
  Future<void> setBgmVolume(double vol) async {
    updateBgmVolume(vol);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_bgm_volume', _bgmVolume);
  }

  /// スライダー操作中のリアルタイム音量反映（ディスクI/Oなし）
  void updateAmbienceVolume(double vol) {
    _ambienceVolume = vol.clamp(0.0, 1.0);
    if (_ambiencePlayer != null && _ambiencePlayer!.state == PlayerState.playing) {
      _ambiencePlayer!.setVolume(_ambienceVolume);
    }
  }

  /// スライダー操作完了時等の永続化付き環境音量設定
  Future<void> setAmbienceVolume(double vol) async {
    updateAmbienceVolume(vol);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_ambience_volume', _ambienceVolume);
  }

  Future<void> setBgmEnabled(bool enabled) async {
    _bgmEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_bgm_enabled', enabled);
    if (!enabled) {
      await stopBgm();
    } else if (!_muted && _currentFloorBgm == null && _lastFloorBgm != null) {
      // BGM再有効化時、直前のフロアBGMを自動再開
      unawaited(_playBgm(_lastFloorBgm!, 0, 1));
    }
  }

  Future<void> setSeEnabled(bool enabled) async {
    _seEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_se_enabled', enabled);
  }

  Future<void> setAmbienceEnabled(bool enabled) async {
    _ambienceEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_ambience_enabled', enabled);
    if (!enabled) {
      await stopAmbience();
    } else if (!_muted && _currentAmbience == null && _lastAmbience != null) {
      // 環境音再有効化時、直前の環境音を自動再開
      unawaited(_playAmbience(_lastAmbience!, 0, 1));
    }
  }

  /// SharedPreferences から設定を一括同期
  Future<void> syncFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final muted = prefs.getBool('sound_muted') ?? false;
    final bgmEnabled = prefs.getBool('sound_bgm_enabled') ?? true;
    final seEnabled = prefs.getBool('sound_se_enabled') ?? true;
    final ambEnabled = prefs.getBool('sound_ambience_enabled') ?? true;
    final bgmVol = prefs.getDouble('sound_bgm_volume') ?? 0.5;
    final seVol = prefs.getDouble('sound_se_volume') ?? 0.8;
    final ambVol = prefs.getDouble('sound_ambience_volume') ?? 0.6;

    await setMuted(muted);
    await setBgmEnabled(bgmEnabled);
    await setSeEnabled(seEnabled);
    await setAmbienceEnabled(ambEnabled);
    await setBgmVolume(bgmVol);
    await setSeVolume(seVol);
    await setAmbienceVolume(ambVol);
  }

  /// 設定画面等でのSEプレビュー再生（seEnabledがONの時、または設定テスト用）
  Future<void> playPreviewSe() async {
    if (_muted || !_seEnabled || _seVolume <= 0.0) return;
    // 存在する代表的なSEをプレビュー再生（優先順位順）
    final candidateFiles = [
      'se_pickup.ogg',
      'se_bell.ogg',
      'click.ogg',
      'se_coin.ogg',
      'se_door_open.ogg',
    ];
    for (final filename in candidateFiles) {
      if (hasSound(filename)) {
        await _playSe(filename, 100);
        return;
      }
    }
  }

  /// アプリバックグラウンド移行時の一時停止
  Future<void> pauseForBackground() async {
    try {
      _floorWasPlayingBeforeBackground = (_floorBgmPlayer?.state == PlayerState.playing);
      if (_floorWasPlayingBeforeBackground) {
        await _floorBgmPlayer?.pause();
      }

      _roomWasPlayingBeforeBackground = (_roomBgmPlayer?.state == PlayerState.playing);
      if (_roomWasPlayingBeforeBackground) {
        await _roomBgmPlayer?.pause();
      }

      _ambienceWasPlayingBeforeBackground = (_ambiencePlayer?.state == PlayerState.playing);
      if (_ambienceWasPlayingBeforeBackground) {
        await _ambiencePlayer?.pause();
      }
    } catch (_) {}
  }

  /// アプリフォアグラウンド復帰時の再開
  Future<void> resumeFromBackground() async {
    try {
      // ミュート中やカテゴリ無効化中は再開しない
      if (!_muted && _bgmEnabled) {
        if (_floorWasPlayingBeforeBackground && _floorBgmPlayer != null) {
          await _floorBgmPlayer?.resume();
        }
        if (_roomWasPlayingBeforeBackground && _roomBgmPlayer != null) {
          await _roomBgmPlayer?.resume();
        }
      }
      if (!_muted && _ambienceEnabled) {
        if (_ambienceWasPlayingBeforeBackground && _ambiencePlayer != null) {
          await _ambiencePlayer?.resume();
        }
      }
    } catch (_) {} finally {
      _floorWasPlayingBeforeBackground = false;
      _roomWasPlayingBeforeBackground = false;
      _ambienceWasPlayingBeforeBackground = false;
    }
  }

  Future<void> stopAll() async {
    for (final entry in _pool) {
      try {
        await entry.player.stop();
        entry.isPlaying = false;
        entry.currentSound = null;
      } catch (_) {}
    }
    await stopBgm();
    await stopAmbience();
  }

  void dispose() {
    for (final entry in _pool) {
      entry.player.dispose();
    }
    _pool.clear();
    _floorBgmPlayer?.dispose();
    _floorBgmPlayer = null;
    _roomBgmPlayer?.dispose();
    _roomBgmPlayer = null;
    _ambiencePlayer?.dispose();
    _ambiencePlayer = null;
    _lastPlayTimeBySound.clear();
    _pendingDoubleStrikes.clear();
    _ambientCombatSePlayTimes.clear();
    _isInitialized = false;
  }

  /// テスト用: サウンド利用可能状態の登録
  @visibleForTesting
  void registerAvailableSound(String filename) {
    _availableSounds.add(filename);
  }

  /// テスト用: 初期化状態の設定
  @visibleForTesting
  void setInitializedForTest(bool value) {
    _isInitialized = value;
  }

  /// テスト用: 各カテゴリ有効状態の設定
  @visibleForTesting
  void setEnabledForTest({bool? bgm, bool? se, bool? ambience}) {
    if (bgm != null) _bgmEnabled = bgm;
    if (se != null) _seEnabled = se;
    if (ambience != null) _ambienceEnabled = ambience;
  }
}

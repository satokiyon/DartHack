import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Androidのキャッシュディレクトリにおける権限エラー（errno=13, EACCES）を回避するための安全なAudioCache
///
/// 【技術的背景】
/// Android OSでは、アプリの再インストール、Scoped Storageの適用、OSによる一時ディレクトリの自動クリーンアップ、
/// またはネイティブコード（Cコア）による umask や環境変更などによって、
/// `getTemporaryDirectory()`（`/data/user/0/<pkg>/cache`）配下のサブディレクトリ生成時に
/// `Permission denied (errno = 13)` が発生する場合があります。
/// これを防ぐため、常にアプリ専有の書き込み権限が保証されている内部ストレージ
/// `getApplicationSupportDirectory()` 配下に固定のキャッシュ先（`darthack_sound_cache`）を配置し、
/// 一時ファイルが起動ごとに無制限に増殖する問題も同時に抑止します。
class SafeAudioCache extends AudioCache {
  final String _safeDirPath;

  SafeAudioCache(this._safeDirPath, {super.prefix = 'assets/', String? cacheId})
      : super(cacheId: cacheId ?? 'darthack_sound_cache');

  @override
  Future<String> getTempDir() async => _safeDirPath;
}

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
    'se_glass_shattering.ogg',
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

  /// 効果音・環境音用オーディオコンテキスト（完全ミキシング・消音スイッチ尊重）
  static final AudioContext _defaultAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {},
    ),
  );

  /// BGM用オーディオコンテキスト（完全ミキシング・消音スイッチ尊重）
  static final AudioContext _bgmAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {},
    ),
  );

  final List<_PlayerEntry> _pool = [];
  AudioPlayer? _bgmPlayerA;
  AudioPlayer? _bgmPlayerB;
  int _activeBgmIndex = 0; // 0: A, 1: B
  String? _currentFloorBgm;
  String? _lastFloorBgm;
  String? _pendingFloorBgm;
  bool _isMainGameStarted = false;
  final List<Map<dynamic, dynamic>> _pendingEvents = [];

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
  bool _isPausedForBackground = false;
  bool _floorWasPlayingBeforeBackground = false;
  bool _roomWasPlayingBeforeBackground = false;
  bool _ambienceWasPlayingBeforeBackground = false;

  @visibleForTesting
  bool get isPausedForBackground => _isPausedForBackground;

  @visibleForTesting
  bool get floorWasPlayingBeforeBackground => _floorWasPlayingBeforeBackground;

  @visibleForTesting
  bool get roomWasPlayingBeforeBackground => _roomWasPlayingBeforeBackground;

  @visibleForTesting
  bool get ambienceWasPlayingBeforeBackground => _ambienceWasPlayingBeforeBackground;

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

  /// デュアルフロアBGMプレイヤーのゲッター
  AudioPlayer? get _activeFloorPlayer => _activeBgmIndex == 0 ? _bgmPlayerA : _bgmPlayerB;
  AudioPlayer? get _inactiveFloorPlayer => _activeBgmIndex == 0 ? _bgmPlayerB : _bgmPlayerA;

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

      // 一時キャッシュディレクトリのパーミッション拒否（errno=13）を回避するため、
      // 確実に書き込み権限のある applicationSupportDirectory 配下に安全な音声キャッシュを設定
      if (!kIsWeb) {
        try {
          final supportDir = await getApplicationSupportDirectory();
          final safeCacheDir = Directory('${supportDir.path}/audio_cache');
          // 過去の破損パーミッション（Cコアの旧umask問題でx権限なし等）を自己修復
          if (await safeCacheDir.exists()) {
            try {
              // 疎通確認（配下の探索・アクセス権限テスト）
              final testDir = Directory('${safeCacheDir.path}/darthack_sound_cache');
              if (await testDir.exists()) {
                await testDir.list().drain();
              }
            } catch (_) {
              // 壊れたパーミッションの旧ディレクトリを安全に破棄
              try {
                await safeCacheDir.delete(recursive: true);
              } catch (_) {}
            }
          }
          if (!await safeCacheDir.exists()) {
            await safeCacheDir.create(recursive: true);
          }
          AudioCache.instance = SafeAudioCache(safeCacheDir.path);
        } catch (e, st) {
          debugPrint('[SoundMgr] Failed to configure SafeAudioCache: $e\n$st');
        }
      }

      // アプリ全体のグローバルAudioContextを設定（新規プレイヤーのデフォルト）
      try {
        await AudioPlayer.global.setAudioContext(_defaultAudioContext);
      } catch (e, st) {
        debugPrint('[SoundMgr] Failed to set global AudioContext: $e\n$st');
      }

      // SEプレイヤープールを初期化 (最大12個)
      for (int i = 0; i < _maxConcurrentPlayers; i++) {
        final player = AudioPlayer();
        player.audioCache = AudioCache.instance;
        await player.setReleaseMode(ReleaseMode.stop);
        try {
          await player.setAudioContext(_defaultAudioContext);
        } catch (e, st) {
          debugPrint('[SoundMgr] Failed to set AudioContext on pool player $i: $e\n$st');
        }
        final entry = _PlayerEntry(player);
        player.onPlayerComplete.listen((_) {
          entry.isPlaying = false;
          entry.currentSound = null;
        });
        _pool.add(entry);
      }

      // デュアルフロアBGMプレイヤー (A/B)
      _bgmPlayerA = AudioPlayer();
      _bgmPlayerA!.audioCache = AudioCache.instance;
      await _bgmPlayerA!.setReleaseMode(ReleaseMode.loop);
      try {
        await _bgmPlayerA!.setAudioContext(_bgmAudioContext);
      } catch (e, st) {
        debugPrint('[SoundMgr] Failed to set AudioContext on _bgmPlayerA: $e\n$st');
      }
      _bgmPlayerA!.onPlayerStateChanged.listen((state) {
        debugPrint('[SoundMgr] BGM Player A state changed: $state (current: $_currentFloorBgm, activeIndex: $_activeBgmIndex)');
      });

      _bgmPlayerB = AudioPlayer();
      _bgmPlayerB!.audioCache = AudioCache.instance;
      await _bgmPlayerB!.setReleaseMode(ReleaseMode.loop);
      try {
        await _bgmPlayerB!.setAudioContext(_bgmAudioContext);
      } catch (e, st) {
        debugPrint('[SoundMgr] Failed to set AudioContext on _bgmPlayerB: $e\n$st');
      }
      _bgmPlayerB!.onPlayerStateChanged.listen((state) {
        debugPrint('[SoundMgr] BGM Player B state changed: $state (current: $_currentFloorBgm, activeIndex: $_activeBgmIndex)');
      });
      _activeBgmIndex = 0;

      // ルームBGMプレイヤー
      _roomBgmPlayer = AudioPlayer();
      _roomBgmPlayer!.audioCache = AudioCache.instance;
      await _roomBgmPlayer!.setReleaseMode(ReleaseMode.loop);
      try {
        await _roomBgmPlayer!.setAudioContext(_bgmAudioContext);
      } catch (e, st) {
        debugPrint('[SoundMgr] Failed to set AudioContext on _roomBgmPlayer: $e\n$st');
      }
      _roomBgmPlayer!.onPlayerStateChanged.listen((state) {
        debugPrint('[SoundMgr] Room BGM Player state changed: $state (current: $_currentRoomBgm)');
      });

      // 環境音（アンビエンス）プレイヤー
      _ambiencePlayer = AudioPlayer();
      _ambiencePlayer!.audioCache = AudioCache.instance;
      await _ambiencePlayer!.setReleaseMode(ReleaseMode.loop);
      try {
        await _ambiencePlayer!.setAudioContext(_defaultAudioContext);
      } catch (e, st) {
        debugPrint('[SoundMgr] Failed to set AudioContext on _ambiencePlayer: $e\n$st');
      }

      _isInitialized = true;

      // 初期化前に届いていたサウンドイベントをディスパッチ
      if (_pendingEvents.isNotEmpty) {
        debugPrint('[SoundMgr] Processing ${_pendingEvents.length} pending events after initialization');
        final queued = List<Map<dynamic, dynamic>>.from(_pendingEvents);
        _pendingEvents.clear();
        for (final ev in queued) {
          handleSoundEvent(ev);
        }
      }

      // ゲーム未開始かつBGM有効時はタイトルBGMを自動再生
      if (!_isMainGameStarted && _bgmEnabled && !_muted && _currentFloorBgm == null) {
        debugPrint('[SoundMgr] Auto-playing title BGM on init: amb_title.ogg');
        unawaited(_playFloorBgmDirect('amb_title.ogg', _bgmVolume));
      }
    } catch (e, st) {
      debugPrint('[SoundMgr] Error in initialize(): $e\n$st');
      _isInitialized = true;
    }
  }

  /// ゲーム本編開始（マップ画面初回表示）通知
  Future<void> notifyMainGameStarted() async {
    debugPrint('[SoundMgr] notifyMainGameStarted called (pending: $_pendingFloorBgm, current: $_currentFloorBgm)');
    _isMainGameStarted = true;
    final targetBgm = _pendingFloorBgm ?? 'amb_dungeon.ogg';
    _pendingFloorBgm = null;

    if (_bgmEnabled && !_muted && hasSound(targetBgm)) {
      if (_currentFloorBgm != targetBgm) {
        debugPrint('[SoundMgr] Crossfading to floor BGM on game start: $targetBgm');
        unawaited(_crossfadeFloorBgm(targetBgm));
      }
    }
  }

  /// 新しいゲームセッション開始時のリセット
  void resetForNewGameSession() {
    debugPrint('[SoundMgr] resetForNewGameSession called');
    _isMainGameStarted = false;
    _pendingFloorBgm = null;
  }

  /// サウンドファイルがアセットに存在するか確認
  bool hasSound(String filename) {
    return _availableSounds.contains(filename);
  }

  /// Cコアからのサウンドイベントをディスパッチ
  void handleSoundEvent(Map<dynamic, dynamic> event) {
    if (!_isInitialized) {
      debugPrint('[SoundMgr] Not initialized yet, queuing event: $event');
      _pendingEvents.add(event);
      return;
    }

    if (_muted) {
      return;
    }

    final catVal = event['category'] as int? ?? 1;
    final filename = event['filename'] as String? ?? '';
    final text = event['text'] as String? ?? '';
    final volume = (event['volume'] as int? ?? 100).clamp(0, 100);
    final loopOrFlag = event['loopOrFlag'] as int? ?? 0;

    final category = SoundCategory.fromValue(catVal);

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
    final has = hasSound(filename);

    if (!_seEnabled || filename.isEmpty || !has || _pool.isEmpty) {
      return;
    }

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
    if (!_seEnabled || _pool.isEmpty) {
      return;
    }

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
      } catch (e, st) {
        debugPrint('[SoundMgr] Failed to stop preempted player: $e\n$st');
      }
    }

    targetEntry.isPlaying = true;
    targetEntry.currentSound = filename;
    targetEntry.lastPlayTime = now;

    final finalVolume = (_seVolume * (cVolume / 100.0)).clamp(0.0, 1.0);
    debugPrint('[SoundMgr] Play SE: $filename (vol: $cVolume, finalVol: $finalVolume)');
    try {
      await targetEntry.player.setVolume(finalVolume);
      await targetEntry.player.play(AssetSource('sounds/$filename'));
    } catch (e, st) {
      debugPrint('[SoundMgr] ERROR playing sound \'$filename\': $e\n$st');
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
        final currentBase = (_muted || !_bgmEnabled) ? 0.0 : _bgmVolume;
        await player.setVolume(currentBase * (i / 6.0));
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if ((isRoomPlayer ? _roomFadeGen : _floorFadeGen) != gen) return;
      if (pauseInsteadOfStop) {
        await player.pause();
      } else {
        await player.stop();
        await player.setVolume(0.0);
      }
    } catch (e, st) {
      debugPrint('[SoundMgr] Error during fadeOut: $e\n$st');
    }
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
        final currentBase = (_muted || !_bgmEnabled) ? 0.0 : _bgmVolume;
        await player.setVolume(currentBase * (i / 6.0));
      }
    } catch (e, st) {
      debugPrint('[SoundMgr] Error during fadeIn: $e\n$st');
    }
  }

  /// フロアBGMの直接・即時再生（初期起動時など）
  Future<void> _playFloorBgmDirect(String filename, double targetVolume) async {
    if (!hasSound(filename)) return;
    _currentFloorBgm = filename;
    _lastFloorBgm = filename;
    final player = _activeFloorPlayer;
    if (player == null) return;

    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume((_muted || !_bgmEnabled) ? 0.0 : targetVolume);
      await player.play(AssetSource('sounds/$filename'));
    } catch (e, st) {
      debugPrint('[SoundMgr] Error direct playing floor BGM \'$filename\': $e\n$st');
    }
  }

  /// 約1.0秒（50ms × 20ステップ）のクロスフェード処理
  Future<void> _crossfadeFloorBgm(String newFilename) async {
    if (!hasSound(newFilename)) return;

    final oldPlayer = _activeFloorPlayer;
    final newPlayer = _inactiveFloorPlayer;
    final int newIndex = 1 - _activeBgmIndex;
    final int gen = ++_floorFadeGen;

    try {
      if (newPlayer != null) {
        await newPlayer.stop();
        await newPlayer.setReleaseMode(ReleaseMode.loop);
        await newPlayer.setVolume(0.0);
        await newPlayer.play(AssetSource('sounds/$newFilename'));
      }

      _currentFloorBgm = newFilename;
      _lastFloorBgm = newFilename;
      _activeBgmIndex = newIndex;

      const int steps = 20;
      const int stepIntervalMs = 50;

      for (int i = 1; i <= steps; i++) {
        if (_floorFadeGen != gen) {
          // 別のフェード処理が割り込んだため中断
          return;
        }
        await Future.delayed(const Duration(milliseconds: stepIntervalMs));
        if (_floorFadeGen != gen) return;

        final progress = i / steps;
        // 動的ベース音量参照
        final currentBaseVol = (_muted || !_bgmEnabled) ? 0.0 : _bgmVolume;
        final newVol = (currentBaseVol * progress).clamp(0.0, 1.0);
        final oldVol = (currentBaseVol * (1.0 - progress)).clamp(0.0, 1.0);

        if (newPlayer != null) {
          unawaited(newPlayer.setVolume(newVol));
        }
        if (oldPlayer != null) {
          unawaited(oldPlayer.setVolume(oldVol));
        }
      }

      // フェードアウト完了後に旧プレイヤーを完全停止
      if (oldPlayer != null && _floorFadeGen == gen) {
        await oldPlayer.stop();
        await oldPlayer.setVolume(0.0);
      }
    } catch (e, st) {
      debugPrint('[SoundMgr] Error during crossfade to \'$newFilename\': $e\n$st');
    }
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

      // ゲーム本編（マップ画面）がまだ始まっていない場合
      if (!_isMainGameStarted) {
        if (filename == 'amb_title.ogg') {
          // タイトルBGMの要求
          if (_currentFloorBgm == 'amb_title.ogg' &&
              _activeFloorPlayer?.state == PlayerState.playing) {
            // すでにタイトルBGMが鳴っていればそのまま継続
            return;
          }
          await _playFloorBgmDirect('amb_title.ogg', _bgmVolume);
          return;
        } else {
          // ダンジョンBGM等の要求は保留（Pending）し、タイトルBGMを継続
          debugPrint('[SoundMgr] Main game not started yet. Holding pending floor BGM: $filename');
          _pendingFloorBgm = filename;
          return;
        }
      }

      // 同一フロアBGMが既にアクティブプレイヤーで再生中の場合は継続再生
      if (_currentFloorBgm == filename && _activeFloorPlayer?.state == PlayerState.playing) {
        return;
      }

      try {
        // ルームBGMが鳴っていれば停止
        if (_roomBgmPlayer?.state == PlayerState.playing) {
          await _fadeOut(_roomBgmPlayer, _bgmVolume, isRoomPlayer: true);
          _currentRoomBgm = null;
        }

        // デュアルプレイヤーで安全にクロスフェード
        await _crossfadeFloorBgm(filename);
      } catch (e, st) {
        debugPrint('[SoundMgr] ERROR playing floor BGM \'$filename\': $e\n$st');
      }
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
          // フロアBGMをフェードアウト停止（resume依存を排除するため安全にstop）
          if (_activeFloorPlayer?.state == PlayerState.playing) {
            await _fadeOut(_activeFloorPlayer, _bgmVolume, pauseInsteadOfStop: false, isRoomPlayer: false);
          }

          _currentRoomBgm = filename;
          await _roomBgmPlayer?.setReleaseMode(ReleaseMode.loop);
          await _roomBgmPlayer?.setVolume(0.0);
          await _roomBgmPlayer?.play(AssetSource('sounds/$filename'));
          unawaited(_fadeIn(_roomBgmPlayer, _bgmVolume, isRoomPlayer: true));
        } catch (e, st) {
          debugPrint('[SoundMgr] ERROR playing room BGM \'$filename\': $e\n$st');
        }
      } else if (action == 2) {
        // 部屋退出時
        if (_currentRoomBgm == filename) {
          // 実際にルームBGMが再生されていた場合のみフェードアウト停止し、フロアBGMへ復帰
          _currentRoomBgm = null;
          try {
            await _fadeOut(_roomBgmPlayer, _bgmVolume, isRoomPlayer: true);

            // resume() は使わず、play(AssetSource) で音量0から安全にフェードイン復帰
            if (_currentFloorBgm != null && hasSound(_currentFloorBgm!)) {
              final player = _activeFloorPlayer;
              if (player != null) {
                await player.setReleaseMode(ReleaseMode.loop);
                await player.setVolume(0.0);
                await player.play(AssetSource('sounds/$_currentFloorBgm'));
                unawaited(_fadeIn(player, _bgmVolume, isRoomPlayer: false));
              }
            }
          } catch (e, st) {
            debugPrint('[SoundMgr] Error restoring floor BGM: $e\n$st');
          }
        } else {
          // ファイルが無くて再生されていなかった場合はフロアBGMを継続（何もしない）
        }
      }
    }
  }

  Future<void> stopBgm() async {
    _currentRoomBgm = null;
    _currentFloorBgm = null;
    _pendingFloorBgm = null;
    _floorFadeGen++;
    try {
      if (_roomBgmPlayer != null && _roomBgmPlayer!.state == PlayerState.playing) {
        await _fadeOut(_roomBgmPlayer, _bgmVolume, isRoomPlayer: true);
      }
      if (_bgmPlayerA != null && _bgmPlayerA!.state == PlayerState.playing) {
        await _fadeOut(_bgmPlayerA, _bgmVolume, isRoomPlayer: false);
      }
      if (_bgmPlayerB != null && _bgmPlayerB!.state == PlayerState.playing) {
        await _fadeOut(_bgmPlayerB, _bgmVolume, isRoomPlayer: false);
      }
    } catch (e, st) {
      debugPrint('[SoundMgr] Error in stopBgm: $e\n$st');
    }
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
      } catch (e, st) {
        debugPrint('[SoundMgr] Error updating ambience volume: $e\n$st');
      }
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
    } catch (e, st) {
      debugPrint('[SoundMgr] Error playing ambience \'$filename\': $e\n$st');
    }
  }

  Future<void> stopAmbience() async {
    try {
      await _ambiencePlayer?.stop();
      _currentAmbience = null;
    } catch (e, st) {
      debugPrint('[SoundMgr] Error stopping ambience: $e\n$st');
    }
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
    if (_bgmPlayerA != null && _bgmPlayerA!.state == PlayerState.playing) {
      _bgmPlayerA!.setVolume(_bgmVolume);
    }
    if (_bgmPlayerB != null && _bgmPlayerB!.state == PlayerState.playing) {
      _bgmPlayerB!.setVolume(_bgmVolume);
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
      // 既にバックグラウンド一時停止処理済みの場合は、後続のライフサイクル遷移（inactive -> paused 等）で
      // 再生中フラグが false で上書きされるのを防ぐため早期リターン
      if (_isPausedForBackground) {
        debugPrint(
            '[SoundMgr] pauseForBackground: already paused for background, ignoring duplicate call');
        return;
      }
      _isPausedForBackground = true;

      // PlayerState.playing のほか、OSの省電力制御等で先行して一時停止されていた場合
      // （明示的に stopBgm / stopAmbience されておらず有効なサウンド名が存在する場合）も再開対象とする
      _floorWasPlayingBeforeBackground =
          (_activeFloorPlayer?.state == PlayerState.playing) ||
              (_currentFloorBgm != null && hasSound(_currentFloorBgm!));
      if (_activeFloorPlayer?.state == PlayerState.playing) {
        await _activeFloorPlayer?.pause();
      }

      _roomWasPlayingBeforeBackground =
          (_roomBgmPlayer?.state == PlayerState.playing) ||
              (_currentRoomBgm != null && hasSound(_currentRoomBgm!));
      if (_roomBgmPlayer?.state == PlayerState.playing) {
        await _roomBgmPlayer?.pause();
      }

      _ambienceWasPlayingBeforeBackground =
          (_ambiencePlayer?.state == PlayerState.playing) ||
              (_currentAmbience != null && hasSound(_currentAmbience!));
      if (_ambiencePlayer?.state == PlayerState.playing) {
        await _ambiencePlayer?.pause();
      }

      debugPrint(
          '[SoundMgr] pauseForBackground executed (floor: $_floorWasPlayingBeforeBackground, room: $_roomWasPlayingBeforeBackground, amb: $_ambienceWasPlayingBeforeBackground)');
    } catch (e, st) {
      debugPrint('[SoundMgr] Error during pauseForBackground: $e\n$st');
    }
  }

  /// アプリフォアグラウンド復帰時の再開
  Future<void> resumeFromBackground() async {
    try {
      if (!_isPausedForBackground) {
        debugPrint(
            '[SoundMgr] resumeFromBackground: not paused for background, ignoring call');
        return;
      }
      debugPrint(
          '[SoundMgr] resumeFromBackground executing (floor: $_floorWasPlayingBeforeBackground, room: $_roomWasPlayingBeforeBackground, amb: $_ambienceWasPlayingBeforeBackground)');

      // ミュート中やカテゴリ無効化中は再開しない
      if (!_muted && _bgmEnabled) {
        // ルームBGM再生中だった場合はルームBGMを優先再開
        if (_roomWasPlayingBeforeBackground &&
            _currentRoomBgm != null &&
            hasSound(_currentRoomBgm!)) {
          final player = _roomBgmPlayer;
          if (player != null) {
            await player.setReleaseMode(ReleaseMode.loop);
            await player.setVolume(_bgmVolume);
            await player.play(AssetSource('sounds/$_currentRoomBgm'));
          }
        } else if (_floorWasPlayingBeforeBackground &&
            _currentFloorBgm != null &&
            hasSound(_currentFloorBgm!)) {
          // フロアBGM再生中だった場合はフロアBGMを直接再開（resume()は完全排除）
          await _playFloorBgmDirect(_currentFloorBgm!, _bgmVolume);
        }
      }
      if (!_muted && _ambienceEnabled) {
        if (_ambienceWasPlayingBeforeBackground &&
            _currentAmbience != null &&
            hasSound(_currentAmbience!)) {
          final player = _ambiencePlayer;
          if (player != null) {
            await player.setReleaseMode(ReleaseMode.loop);
            await player.setVolume(_ambienceVolume);
            await player.play(AssetSource('sounds/$_currentAmbience'));
          }
        }
      }
    } catch (e, st) {
      debugPrint('[SoundMgr] Error during resumeFromBackground: $e\n$st');
    } finally {
      _isPausedForBackground = false;
      _floorWasPlayingBeforeBackground = false;
      _roomWasPlayingBeforeBackground = false;
      _ambienceWasPlayingBeforeBackground = false;
    }
  }

  Future<void> stopAll() async {
    _isPausedForBackground = false;
    for (final entry in _pool) {
      try {
        await entry.player.stop();
        entry.isPlaying = false;
        entry.currentSound = null;
      } catch (e, st) {
        debugPrint('[SoundMgr] Error stopping pool player: $e\n$st');
      }
    }
    await stopBgm();
    await stopAmbience();
  }

  void dispose() {
    for (final entry in _pool) {
      entry.player.dispose();
    }
    _pool.clear();
    _bgmPlayerA?.dispose();
    _bgmPlayerA = null;
    _bgmPlayerB?.dispose();
    _bgmPlayerB = null;
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
  void setInitializedForTest(bool value, {bool isMainGameStarted = true}) {
    _isInitialized = value;
    _isMainGameStarted = isMainGameStarted;
  }

  /// テスト用: 保留中のフロアBGMの取得
  @visibleForTesting
  String? get pendingFloorBgmForTest => _pendingFloorBgm;

  /// テスト用: プレイヤープール情報の取得
  @visibleForTesting
  int get poolSize => _pool.length;

  /// テスト用: 現在再生中としてマークされているエントリ数
  @visibleForTesting
  int get playingEntryCount => _pool.where((e) => e.isPlaying).length;

  /// テスト用: プレイヤープールのモック・ダミー初期化
  @visibleForTesting
  void initPoolForTest(List<AudioPlayer> players) {
    for (final entry in _pool) {
      try {
        entry.player.dispose();
      } catch (_) {}
    }
    _pool.clear();
    for (final player in players) {
      final entry = _PlayerEntry(player);
      player.onPlayerComplete.listen((_) {
        entry.isPlaying = false;
        entry.currentSound = null;
      });
      _pool.add(entry);
    }
  }

  /// テスト用: クールダウンおよびスロットル状態のリセット
  @visibleForTesting
  void clearCooldownsForTest() {
    _lastPlayTimeBySound.clear();
    _pendingDoubleStrikes.clear();
    _ambientCombatSePlayTimes.clear();
  }

  /// テスト用: 各カテゴリ有効状態の設定
  @visibleForTesting
  void setEnabledForTest({bool? bgm, bool? se, bool? ambience}) {
    if (bgm != null) _bgmEnabled = bgm;
    if (se != null) _seEnabled = se;
    if (ambience != null) _ambienceEnabled = ambience;
  }
}

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
  static const String _soundAssetPrefix = 'assets/sounds/';

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
  AudioPlayer? _roomBgmPlayer;
  String? _currentRoomBgm;
  AudioPlayer? _ambiencePlayer;
  String? _currentAmbience;

  final Set<String> _availableSounds = {};
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

  double get seVolume => _seVolume;
  double get bgmVolume => _bgmVolume;
  double get ambienceVolume => _ambienceVolume;
  double get voiceVolume => _voiceVolume;
  bool get isMuted => _muted;

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
      case SoundCategory.achievement:
        _playSe(filename, volume);
        break;
      case SoundCategory.heroMusic:
        _playInstrument(filename, text, volume, loopOrFlag != 0);
        break;
      case SoundCategory.bgm:
        _playBgm(filename, volume, loopOrFlag);
        break;
      case SoundCategory.ambience:
        if (_terrainAmbienceFiles.contains(filename)) {
          // 2.2 地形・天候環境音（フロアBGMと同時に再生・距離減衰あり）
          _playAmbience(filename, volume, loopOrFlag);
        } else {
          // 2.3 特別な部屋・施設・テーマ部屋（フロアBGMとクロスフェードするルームBGM）
          _playBgm(filename, volume, loopOrFlag);
        }
        break;
      case SoundCategory.voice:
        _playVoice(filename, text, volume);
        break;
    }
  }

  /// 効果音の再生
  Future<void> _playSe(String filename, int cVolume) async {
    if (filename.isEmpty || !hasSound(filename)) return;

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

    // 空きプレイヤーの取得（無ければ最も古いプレイヤーを再利用）
    _PlayerEntry? targetEntry;
    for (final entry in _pool) {
      if (!entry.isPlaying) {
        targetEntry = entry;
        break;
      }
    }

    if (targetEntry == null) {
      targetEntry = _pool.reduce((a, b) => a.lastPlayTime.isBefore(b.lastPlayTime) ? a : b);
      try {
        await targetEntry.player.stop();
      } catch (_) {}
    }

    targetEntry.isPlaying = true;
    targetEntry.currentSound = filename;
    targetEntry.lastPlayTime = DateTime.now();

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
    }
  }

  Future<void> setSeVolume(double vol) async {
    _seVolume = vol.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_se_volume', _seVolume);
  }

  Future<void> setBgmVolume(double vol) async {
    _bgmVolume = vol.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_bgm_volume', _bgmVolume);
    if (_floorBgmPlayer != null && _floorBgmPlayer!.state == PlayerState.playing) {
      await _floorBgmPlayer!.setVolume(_bgmVolume);
    }
    if (_roomBgmPlayer != null && _roomBgmPlayer!.state == PlayerState.playing) {
      await _roomBgmPlayer!.setVolume(_bgmVolume);
    }
  }

  Future<void> setAmbienceVolume(double vol) async {
    _ambienceVolume = vol.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_ambience_volume', _ambienceVolume);
    if (_ambiencePlayer != null && _ambiencePlayer!.state == PlayerState.playing) {
      await _ambiencePlayer!.setVolume(_ambienceVolume);
    }
  }

  Future<void> setVoiceVolume(double vol) async {
    _voiceVolume = vol.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_voice_volume', _voiceVolume);
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
      if (_floorWasPlayingBeforeBackground && _floorBgmPlayer != null) {
        await _floorBgmPlayer?.resume();
      }
      if (_roomWasPlayingBeforeBackground && _roomBgmPlayer != null) {
        await _roomBgmPlayer?.resume();
      }
      if (_ambienceWasPlayingBeforeBackground && _ambiencePlayer != null) {
        await _ambiencePlayer?.resume();
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
}

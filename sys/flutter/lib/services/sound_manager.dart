import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// サウンドカテゴリ（Cコアの sound_category と完全同期）
enum SoundCategory {
  se(1),
  heroMusic(2),
  achievement(3),
  bgm(4),
  voice(5);

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

  final List<_PlayerEntry> _pool = [];
  AudioPlayer? _bgmPlayer;
  String? _currentBgm;

  final Set<String> _availableSounds = {};
  bool _isInitialized = false;

  double _seVolume = 0.8;
  double _bgmVolume = 0.5;
  double _voiceVolume = 0.8;
  bool _muted = false;

  double get seVolume => _seVolume;
  double get bgmVolume => _bgmVolume;
  double get voiceVolume => _voiceVolume;
  bool get isMuted => _muted;

  /// 初期化: アセット一覧のスキャンとプレイヤーのプール生成
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _seVolume = prefs.getDouble('sound_se_volume') ?? 0.8;
      _bgmVolume = prefs.getDouble('sound_bgm_volume') ?? 0.5;
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

      // BGMプレイヤー
      _bgmPlayer = AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);

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
        _playBgm(filename, volume, loopOrFlag != 0);
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

  /// BGMの再生
  Future<void> _playBgm(String filename, int cVolume, bool loop) async {
    if (filename.isEmpty || !hasSound(filename)) {
      if (filename.isEmpty) {
        await stopBgm();
      }
      return;
    }

    if (_currentBgm == filename && _bgmPlayer?.state == PlayerState.playing) {
      return;
    }

    try {
      _currentBgm = filename;
      final finalVolume = (_bgmVolume * (cVolume / 100.0)).clamp(0.0, 1.0);
      await _bgmPlayer?.setVolume(finalVolume);
      await _bgmPlayer?.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _bgmPlayer?.play(AssetSource('sounds/$filename'));
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer?.stop();
      _currentBgm = null;
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
    if (_bgmPlayer != null && _bgmPlayer!.state == PlayerState.playing) {
      await _bgmPlayer!.setVolume(_bgmVolume);
    }
  }

  Future<void> setVoiceVolume(double vol) async {
    _voiceVolume = vol.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_voice_volume', _voiceVolume);
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
  }

  void dispose() {
    for (final entry in _pool) {
      entry.player.dispose();
    }
    _pool.clear();
    _bgmPlayer?.dispose();
    _bgmPlayer = null;
    _isInitialized = false;
  }
}

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// 工业级自然实录采样白噪音引擎 (基于 just_audio & Google ExoPlayer / Apple AVPlayer)
/// 核心特性：
/// 1. 100% 硬件级 Gapless 零间隙无缝循环 (LoopMode.one)
/// 2. 真实自然声波切片 (窗台夜雨、深海潮汐、夜色篝火)，经过等功率 (Equal-Power) 交叉淡化处理，首尾连续无爆音
/// 3. 1.0 秒平滑淡入 (Fade-in) 与 0.5 秒平滑淡出 (Fade-out)，消除声音突兀截断
class WhiteNoiseService {
  static final WhiteNoiseService instance = WhiteNoiseService._internal();
  WhiteNoiseService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _currentPlayingSound;
  double _targetVolume = 0.8;

  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  String? get currentPlayingSound => _currentPlayingSound;

  static const Map<String, String> _soundAssets = {
    '🌧️ 窗台夜雨': 'assets/audio/rain.m4a',
    '🌊 深海潮汐': 'assets/audio/waves.m4a',
    '🌲 夜色篝火': 'assets/audio/campfire.m4a',
  };

  /// 别名解析器 (兼容无 emoji 或旧键名)
  static String? _resolveAsset(String name) {
    if (_soundAssets.containsKey(name)) return _soundAssets[name];
    if (name.contains('雨')) return _soundAssets['🌧️ 窗台夜雨'];
    if (name.contains('海') || name.contains('潮') || name.contains('浪') || name.contains('布朗')) {
      return _soundAssets['🌊 深海潮汐'];
    }
    if (name.contains('火') || name.contains('篝')) return _soundAssets['🌲 夜色篝火'];
    return null;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _player.setLoopMode(LoopMode.one);
      _isInitialized = true;
    } catch (e) {
      debugPrint('WhiteNoiseService init error: $e');
    }
  }

  /// 播放指定环境音（带 1.0s 平滑淡入）
  Future<void> play(String soundName, {double volume = 0.8}) async {
    if (soundName == '🔇 静音模式' || soundName.contains('静音')) {
      await stop();
      return;
    }

    final assetPath = _resolveAsset(soundName);
    if (assetPath == null) {
      debugPrint('No audio asset found for: $soundName');
      await stop();
      return;
    }

    try {
      if (!_isInitialized) {
        await init();
      }

      _targetVolume = volume.clamp(0.0, 1.0);
      _currentPlayingSound = soundName;

      // 切换资源并设置单曲硬件级无限循环
      await _player.setAsset(assetPath);
      await _player.setLoopMode(LoopMode.one);

      _isPlaying = true;
      // 从 0 音量启动播放，随后进行 10 步平滑线性淡入 (1 秒)
      await _player.setVolume(0.0);
      _player.play();

      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!_isPlaying || _currentPlayingSound != soundName) break;
        await _player.setVolume((_targetVolume * i) / 10);
      }
    } catch (e) {
      debugPrint('WhiteNoiseService play error: $e');
    }
  }

  /// 暂停（带 0.4s 平滑淡出）
  Future<void> pause() async {
    if (!_isPlaying) return;
    _isPlaying = false;

    try {
      for (int i = 4; i >= 0; i--) {
        await Future.delayed(const Duration(milliseconds: 80));
        await _player.setVolume((_targetVolume * i) / 4);
      }
      await _player.pause();
    } catch (e) {
      debugPrint('WhiteNoiseService pause error: $e');
    }
  }

  /// 继续播放
  Future<void> resume() async {
    if (_currentPlayingSound != null) {
      await play(_currentPlayingSound!, volume: _targetVolume);
    }
  }

  /// 停止播放（带 0.4s 平滑淡出）
  Future<void> stop() async {
    if (!_isPlaying) {
      _currentPlayingSound = null;
      return;
    }
    _isPlaying = false;
    _currentPlayingSound = null;

    try {
      for (int i = 4; i >= 0; i--) {
        await Future.delayed(const Duration(milliseconds: 80));
        await _player.setVolume((_targetVolume * i) / 4);
      }
      await _player.stop();
    } catch (e) {
      debugPrint('WhiteNoiseService stop error: $e');
    }
  }

  /// 动态调节音量
  Future<void> setVolume(double volume) async {
    _targetVolume = volume.clamp(0.0, 1.0);
    if (_isPlaying) {
      try {
        await _player.setVolume(_targetVolume);
      } catch (e) {
        debugPrint('WhiteNoiseService setVolume error: $e');
      }
    }
  }

  /// 释放资源
  void dispose() {
    _player.dispose();
  }
}

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 100% 离线自持、基于算法数学合成的白噪音与环境音引擎
/// 零网络依赖、零版权风险，在本地生成舒缓的高品质无缝循环音效
class WhiteNoiseService {
  static final WhiteNoiseService instance = WhiteNoiseService._internal();
  WhiteNoiseService._internal();

  static const MethodChannel _channel = MethodChannel('com.pomodo.app/audio');

  bool _isInitialized = false;
  String? _currentPlayingSound;
  final Map<String, String> _soundFiles = {};

  bool get isInitialized => _isInitialized;
  String? get currentPlayingSound => _currentPlayingSound;

  /// 初始化并预备离线白噪音音频文件
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final soundDir = Directory('${docDir.path}/white_noise');
      if (!await soundDir.exists()) {
        await soundDir.create(recursive: true);
      }

      final rainFile = File('${soundDir.path}/rain.wav');
      final typewriterFile = File('${soundDir.path}/typewriter.wav');
      final campfireFile = File('${soundDir.path}/campfire.wav');

      // 仅在文件不存在或为空时生成，避免每次启动重复计算
      if (!await rainFile.exists() || await rainFile.length() < 1000) {
        final rainBytes = _synthesizeRainWav(sampleRate: 22050, durationSec: 7.0);
        await rainFile.writeAsBytes(rainBytes, flush: true);
      }

      if (!await typewriterFile.exists() || await typewriterFile.length() < 1000) {
        final typewriterBytes = _synthesizeTypewriterWav(sampleRate: 22050, durationSec: 6.0);
        await typewriterFile.writeAsBytes(typewriterBytes, flush: true);
      }

      if (!await campfireFile.exists() || await campfireFile.length() < 1000) {
        final campfireBytes = _synthesizeCampfireWav(sampleRate: 22050, durationSec: 7.0);
        await campfireFile.writeAsBytes(campfireBytes, flush: true);
      }

      _soundFiles['雨落窗台'] = rainFile.path;
      _soundFiles['机械打字'] = typewriterFile.path;
      _soundFiles['夜色篝火'] = campfireFile.path;

      _isInitialized = true;
    } catch (e) {
      debugPrint('WhiteNoiseService init error: $e');
    }
  }

  /// 播放指定环境音
  Future<void> play(String soundName, {double volume = 0.65}) async {
    if (soundName == '静音模式') {
      await stop();
      return;
    }

    if (!_isInitialized) {
      await init();
    }

    final filePath = _soundFiles[soundName];
    if (filePath == null) {
      debugPrint('No audio file found for sound: $soundName');
      return;
    }

    try {
      await _channel.invokeMethod('play', {
        'path': filePath,
        'volume': volume,
      });
      _currentPlayingSound = soundName;
    } catch (e) {
      debugPrint('WhiteNoiseService play error: $e');
    }
  }

  /// 暂停
  Future<void> pause() async {
    try {
      await _channel.invokeMethod('pause');
    } catch (e) {
      debugPrint('WhiteNoiseService pause error: $e');
    }
  }

  /// 继续播放
  Future<void> resume() async {
    try {
      await _channel.invokeMethod('resume');
    } catch (e) {
      debugPrint('WhiteNoiseService resume error: $e');
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
      _currentPlayingSound = null;
    } catch (e) {
      debugPrint('WhiteNoiseService stop error: $e');
    }
  }

  /// 设置音量 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (e) {
      debugPrint('WhiteNoiseService setVolume error: $e');
    }
  }

  // =========================================================================
  // 数学过程式音频合成器 (Procedural Audio Synthesizers)
  // =========================================================================

  /// 1. 雨落窗台 (Rain on Window): 温暖粉红噪音 + 随机轻柔雨滴拍击
  Uint8List _synthesizeRainWav({required int sampleRate, required double durationSec}) {
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = Float32List(totalSamples);
    final random = Random(42);

    // Paul Kellet's 粉红噪音滤波器状态
    double b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0, b6 = 0.0;
    double lpFilter = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final white = (random.nextDouble() * 2.0 - 1.0);

      // 粉红噪音滤波器
      b0 = 0.99886 * b0 + white * 0.0555179;
      b1 = 0.99332 * b1 + white * 0.0750759;
      b2 = 0.96900 * b2 + white * 0.1538520;
      b3 = 0.86650 * b3 + white * 0.3104856;
      b4 = 0.55000 * b4 + white * 0.5329522;
      b5 = -0.7616 * b5 - white * 0.0168980;
      final pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.09;
      b6 = white * 0.115926;

      // 柔和低通滤波 (模拟隔着玻璃窗的沉闷雨声，消除刺耳毛刺)
      lpFilter = lpFilter + 0.18 * (pink - lpFilter);
      samples[i] = lpFilter;
    }

    // 叠加随机雨滴敲击 (Droplet Patter)
    int dropletIdx = 0;
    while (dropletIdx < totalSamples - 1000) {
      // 平均每 400~1200 个样本出现一次雨滴
      dropletIdx += (400 + random.nextInt(800));
      if (dropletIdx >= totalSamples - 1000) break;

      final dropFreq = 1400.0 + random.nextDouble() * 800.0;
      final dropAmp = 0.15 + random.nextDouble() * 0.25;
      final dropLen = (sampleRate * 0.018).toInt(); // 约 18ms

      for (int j = 0; j < dropLen && (dropletIdx + j) < totalSamples; j++) {
        final t = j / sampleRate;
        final decay = exp(-t * 180.0);
        final val = sin(2.0 * pi * dropFreq * t) * decay * dropAmp;
        samples[dropletIdx + j] += val;
      }
    }

    // 循环无缝交叉淡化 (避免首尾循环播放时出现噼啪跳音)
    _applyCrossfade(samples, crossfadeSamples: (sampleRate * 0.3).toInt());

    return _encodePcmWav(samples, sampleRate: sampleRate);
  }

  /// 2. 机械打字 / 机械时钟 (Mechanical Ticking & Typing)
  Uint8List _synthesizeTypewriterWav({required int sampleRate, required double durationSec}) {
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = Float32List(totalSamples);
    final random = Random(128);

    // 极轻微的录音室环境空气底噪
    double lpAir = 0.0;
    for (int i = 0; i < totalSamples; i++) {
      final white = (random.nextDouble() * 2.0 - 1.0) * 0.012;
      lpAir = lpAir + 0.05 * (white - lpAir);
      samples[i] = lpAir;
    }

    // 节奏规律的博朗机械表盘微秒针滴答与机械击键节奏
    final intervalSamples = (sampleRate * 0.75).toInt(); // 每 0.75 秒一次击键/滴答
    int tickPos = (sampleRate * 0.1).toInt();

    while (tickPos < totalSamples - 1500) {
      final isMajorTick = (tickPos ~/ intervalSamples) % 2 == 0;
      final clickLen = (sampleRate * 0.045).toInt(); // 45ms 机械击键衰减
      final resonanceFreq = isMajorTick ? 2400.0 : 1800.0;
      final clickAmp = isMajorTick ? 0.65 : 0.45;

      for (int j = 0; j < clickLen && (tickPos + j) < totalSamples; j++) {
        final t = j / sampleRate;
        final decay = exp(-t * 90.0);
        // 瞬态高频冲击波 + 机械空腔共鸣
        final impulse = (random.nextDouble() * 2.0 - 1.0) * exp(-t * 220.0) * 0.4;
        final resonance = sin(2.0 * pi * resonanceFreq * t) * decay * clickAmp;
        samples[tickPos + j] += (impulse + resonance);
      }

      tickPos += intervalSamples + (random.nextInt(200) - 100);
    }

    _applyCrossfade(samples, crossfadeSamples: (sampleRate * 0.25).toInt());
    return _encodePcmWav(samples, sampleRate: sampleRate);
  }

  /// 3. 夜色篝火 (Cozy Campfire): 暖色低频风浪 + 随机树枝爆裂脆响
  Uint8List _synthesizeCampfireWav({required int sampleRate, required double durationSec}) {
    final totalSamples = (sampleRate * durationSec).toInt();
    final samples = Float32List(totalSamples);
    final random = Random(256);

    // 极暖的低频热气流风吟 (Low-frequency Brownian rumble)
    double brown = 0.0;
    double lpRumble = 0.0;
    for (int i = 0; i < totalSamples; i++) {
      final white = (random.nextDouble() * 2.0 - 1.0);
      brown = (brown + 0.02 * white) / 1.02;
      lpRumble = lpRumble + 0.1 * (brown - lpRumble);
      samples[i] = lpRumble * 0.45;
    }

    // 随机噼啪爆裂声 (Wood Crackles & Sharp Sparks)
    int cracklePos = 0;
    while (cracklePos < totalSamples - 2000) {
      // 随机间隔 100ms ~ 350ms
      cracklePos += (sampleRate * (0.1 + random.nextDouble() * 0.25)).toInt();
      if (cracklePos >= totalSamples - 2000) break;

      // 产生 1~3 声连续脆爆
      final numBursts = 1 + random.nextInt(3);
      for (int b = 0; b < numBursts; b++) {
        final burstOffset = cracklePos + (b * (200 + random.nextInt(300)));
        if (burstOffset >= totalSamples - 500) break;

        final burstAmp = 0.35 + random.nextDouble() * 0.45;
        final burstFreq = 2200.0 + random.nextDouble() * 2800.0;
        final burstLen = (sampleRate * 0.02).toInt();

        for (int j = 0; j < burstLen && (burstOffset + j) < totalSamples; j++) {
          final t = j / sampleRate;
          final decay = exp(-t * 240.0);
          final snap = (random.nextDouble() * 2.0 - 1.0) * exp(-t * 400.0) * 0.5;
          final spark = sin(2.0 * pi * burstFreq * t) * decay * burstAmp;
          samples[burstOffset + j] += (snap + spark);
        }
      }
    }

    _applyCrossfade(samples, crossfadeSamples: (sampleRate * 0.3).toInt());
    return _encodePcmWav(samples, sampleRate: sampleRate);
  }

  /// 边界平滑交叉淡化 (防止首尾循环时因振幅不连续产生喀嗒跳音)
  void _applyCrossfade(Float32List samples, {required int crossfadeSamples}) {
    final len = samples.length;
    if (crossfadeSamples <= 0 || crossfadeSamples >= len ~/ 2) return;

    for (int i = 0; i < crossfadeSamples; i++) {
      final ratio = i / crossfadeSamples; // 0.0 -> 1.0
      // 头部样本淡入，尾部样本淡出并加权混合
      final tailVal = samples[len - crossfadeSamples + i];
      final headVal = samples[i];
      samples[i] = (1.0 - ratio) * tailVal + ratio * headVal;
      samples[len - crossfadeSamples + i] = samples[i];
    }
  }

  /// 将标准浮点音频采样序列编码为标准 16-Bit Mono RIFF WAV 字节流
  Uint8List _encodePcmWav(Float32List samples, {required int sampleRate}) {
    final numChannels = 1;
    final bitsPerSample = 16;
    final bytesPerSample = bitsPerSample ~/ 8;
    final dataSize = samples.length * bytesPerSample;
    final fileSize = 36 + dataSize;

    final byteData = ByteData(44 + dataSize);

    // 1. RIFF 标识头
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, fileSize, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // 2. fmt 子块
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // 子块大小 (PCM 为 16)
    byteData.setUint16(20, 1, Endian.little);  // 格式 (1 = PCM)
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * numChannels * bytesPerSample, Endian.little); // ByteRate
    byteData.setUint16(32, numChannels * bytesPerSample, Endian.little); // BlockAlign
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // 3. data 子块
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, dataSize, Endian.little);

    // 4. 写入 16-Bit PCM 采样数据 (带峰值限幅保护)
    int offset = 44;
    for (int i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final intSample = (clamped * 32767.0).toInt();
      byteData.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}

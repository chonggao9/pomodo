// 基于 Web Audio API 的零依赖高品质离线白噪音与环境音合成引擎

export type NoiseType = 'none' | 'rain' | 'ocean' | 'pink';

export class ProceduralAudioEngine {
  private static instance: ProceduralAudioEngine | null = null;
  private ctx: AudioContext | null = null;
  private currentNoiseType: NoiseType = 'none';
  private noiseSourceNode: AudioNode | null = null;
  private masterGain: GainNode | null = null;
  private lfoOsc: OscillatorNode | null = null;
  private currentVolume = 0.5;

  private constructor() {}

  public static getInstance(): ProceduralAudioEngine {
    if (!ProceduralAudioEngine.instance) {
      ProceduralAudioEngine.instance = new ProceduralAudioEngine();
    }
    return ProceduralAudioEngine.instance;
  }

  private initContext(): AudioContext {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      this.ctx = new AudioCtx();
      this.masterGain = this.ctx.createGain();
      this.masterGain.gain.setValueAtTime(this.currentVolume, this.ctx.currentTime);
      this.masterGain.connect(this.ctx.destination);
    }
    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
    return this.ctx;
  }

  /** 设置主音量 (0.0 ~ 1.0) */
  public setVolume(vol: number): void {
    this.currentVolume = Math.max(0, Math.min(1, vol));
    if (this.masterGain && this.ctx) {
      this.masterGain.gain.setTargetAtTime(this.currentVolume, this.ctx.currentTime, 0.05);
    }
  }

  public getVolume(): number {
    return this.currentVolume;
  }

  public getCurrentType(): NoiseType {
    return this.currentNoiseType;
  }

  /** 停止当前播放的环境音 */
  public stop(): void {
    if (this.noiseSourceNode) {
      try {
        if ('stop' in this.noiseSourceNode && typeof (this.noiseSourceNode as AudioBufferSourceNode).stop === 'function') {
          (this.noiseSourceNode as AudioBufferSourceNode).stop();
        }
        this.noiseSourceNode.disconnect();
      } catch {
        // ignore
      }
      this.noiseSourceNode = null;
    }
    if (this.lfoOsc) {
      try {
        this.lfoOsc.stop();
        this.lfoOsc.disconnect();
      } catch {
        // ignore
      }
      this.lfoOsc = null;
    }
    this.currentNoiseType = 'none';
  }

  /** 播放指定类型的离线白噪音 */
  public play(type: NoiseType): void {
    const ctx = this.initContext();
    this.stop();

    if (type === 'none') {
      return;
    }

    this.currentNoiseType = type;

    // 5秒循环白噪音缓冲
    const bufferSize = ctx.sampleRate * 5;
    const noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const output = noiseBuffer.getChannelData(0);

    if (type === 'pink') {
      // Paul Kellet's 经典滤波粉红噪音算法 (舒适暖色调)
      let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        output[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.08;
        b6 = white * 0.115926;
      }
      const source = ctx.createBufferSource();
      source.buffer = noiseBuffer;
      source.loop = true;
      source.connect(this.masterGain!);
      source.start();
      this.noiseSourceNode = source;

    } else if (type === 'rain') {
      // 雨声模式：带通与低通滤波粉红噪音，呈现清脆舒缓的雨幕感
      let lastOut = 0.0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        output[i] = (lastOut + (0.02 * white)) / 1.02;
        lastOut = output[i];
        output[i] *= 1.8;
      }

      const source = ctx.createBufferSource();
      source.buffer = noiseBuffer;
      source.loop = true;

      // 滤波塑造雨声声学特征
      const filter = ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(1200, ctx.currentTime);

      const highpass = ctx.createBiquadFilter();
      highpass.type = 'highpass';
      highpass.frequency.setValueAtTime(300, ctx.currentTime);

      source.connect(filter);
      filter.connect(highpass);
      highpass.connect(this.masterGain!);
      source.start();
      this.noiseSourceNode = source;

    } else if (type === 'ocean') {
      // 潮汐海浪模式：深褐色噪音 + LFO 周期性潮起潮落
      let lastOut = 0.0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        output[i] = (lastOut + (0.015 * white)) / 1.015;
        lastOut = output[i];
        output[i] *= 2.2;
      }

      const source = ctx.createBufferSource();
      source.buffer = noiseBuffer;
      source.loop = true;

      const waveGain = ctx.createGain();
      waveGain.gain.setValueAtTime(0.2, ctx.currentTime);

      // 0.12Hz 低频震荡器 (大约 8.3 秒一次海浪起伏)
      const lfo = ctx.createOscillator();
      lfo.frequency.setValueAtTime(0.12, ctx.currentTime);

      const lfoGain = ctx.createGain();
      lfoGain.gain.setValueAtTime(0.35, ctx.currentTime);

      lfo.connect(lfoGain);
      lfoGain.connect(waveGain.gain);
      lfo.start();
      this.lfoOsc = lfo;

      const filter = ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(600, ctx.currentTime);

      source.connect(filter);
      filter.connect(waveGain);
      waveGain.connect(this.masterGain!);
      source.start();
      this.noiseSourceNode = source;
    }
  }

  /** 专注达成清脆敲钟提示音 (Solfeggio 528Hz 禅意和弦音) */
  public playCompletionChime(): void {
    const ctx = this.initContext();
    const now = ctx.currentTime;

    // 主音 (528 Hz 治愈频率)
    const osc1 = ctx.createOscillator();
    const gain1 = ctx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(528, now);

    // 泛音 (1056 Hz 高八度)
    const osc2 = ctx.createOscillator();
    const gain2 = ctx.createGain();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(1056, now);

    // 敲击音包络 (瞬间起振，自然平缓衰减)
    gain1.gain.setValueAtTime(0.001, now);
    gain1.gain.exponentialRampToValueAtTime(0.35, now + 0.04);
    gain1.gain.exponentialRampToValueAtTime(0.0001, now + 2.4);

    gain2.gain.setValueAtTime(0.001, now);
    gain2.gain.exponentialRampToValueAtTime(0.15, now + 0.03);
    gain2.gain.exponentialRampToValueAtTime(0.0001, now + 1.6);

    osc1.connect(gain1);
    gain1.connect(this.masterGain!);
    osc2.connect(gain2);
    gain2.connect(this.masterGain!);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 2.5);
    osc2.stop(now + 2.5);
  }
}

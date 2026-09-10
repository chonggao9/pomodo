import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/pomodoro_dial.dart';

class PomodoroPage extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const PomodoroPage({super.key, this.onNavigateTab});

  void _handleEarlyComplete(BuildContext context, PomodoroProvider pomo) async {
    final taskId = pomo.selectedTaskId;
    final taskTitle = pomo.selectedTaskTitle ?? '自由专注';
    final actualMinutes = await pomo.completeEarly();

    if (taskId != null && context.mounted) {
      // 在待办清单中就地划线归档
      await context.read<TaskProvider>().toggleTask(taskId);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '专注达成（已记录 $actualMinutes 分钟）！任务「$taskTitle」已就地划线归档！',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 2200),
        ),
      );

      // 700ms 自动平滑切回今日待办页 Tab 0
      Future.delayed(const Duration(milliseconds: 700), () {
        onNavigateTab?.call(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<PomodoroProvider>(
          builder: (context, pomo, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. 顶部标题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEEP FOCUS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: AppTheme.marsGreen,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '沉浸专注',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: pomo.isRunning
                              ? AppTheme.marsGreen.withOpacity(0.1)
                              : (pomo.isPaused
                                  ? Colors.amber.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.04)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: pomo.isRunning
                                  ? AppTheme.marsGreen
                                  : (pomo.isPaused ? Colors.amber[800] : Colors.black26),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pomo.isRunning
                                  ? '专注进行中'
                                  : (pomo.isPaused ? '已暂停' : '待命就绪'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: pomo.isRunning
                                    ? AppTheme.marsGreen
                                    : (pomo.isPaused ? Colors.amber[800] : AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. 关联的任务胶囊 (可解绑)
                  if (pomo.selectedTaskTitle != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.marsGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.marsGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.radio_button_checked, size: 15, color: AppTheme.marsGreen),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              pomo.selectedTaskTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.marsGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => pomo.selectTask(null, null),
                            child: const Icon(Icons.close, size: 15, color: AppTheme.marsGreen),
                          ),
                        ],
                      ),
                    ),

                  // 3. 博朗拟物 60 刻度精密机械表盘
                  PomodoroDial(
                    progress: pomo.progress,
                    formattedTime: pomo.formattedTime,
                    isRunning: pomo.isRunning,
                    onTap: () {
                      if (pomo.isRunning) {
                        pomo.pause();
                      } else {
                        pomo.start();
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // 4. 预设时长选择 (15 / 25 / 35 / 45m)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: pomo.presetMinutes.map((m) {
                      final isSelected = pomo.targetMinutes == m;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text('${m}m'),
                          selected: isSelected,
                          selectedColor: AppTheme.marsGreen,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppTheme.marsGreen : AppTheme.borderLight,
                            ),
                          ),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) pomo.setTargetMinutes(m);
                          },
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // 5. 核心控制按钮栏 (1:1 像素还原设计稿三态分支)
                  _buildActionsRow(context, pomo),

                  const SizedBox(height: 32),

                  // 6. 离线白噪音声学微仓 (pomo-ambient-dock)
                  _buildAmbientDock(pomo),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 专注三态控制栏 (空闲单大键 / 运行态双键 / 暂停态三键)
  Widget _buildActionsRow(BuildContext context, PomodoroProvider pomo) {
    // 态 A: 正在运行中 (暂停专注 + 提前完成并划线)
    if (pomo.isRunning) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => pomo.pause(),
              icon: const Icon(Icons.pause_rounded, size: 20),
              label: const Text('暂停专注', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.marsGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleEarlyComplete(context, pomo),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppTheme.marsGreen),
              label: const Text('提前完成并划线', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.marsGreen)),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFE8F5F4),
                side: const BorderSide(color: Color(0x33008779)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      );
    }

    // 态 B: 已暂停 (继续专注 + 达成划线 + 放弃重置)
    if (pomo.isPaused) {
      return Row(
        children: [
          Expanded(
            flex: 12,
            child: ElevatedButton.icon(
              onPressed: () => pomo.resume(),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('继续专注', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.marsGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: ElevatedButton.icon(
              onPressed: () => _handleEarlyComplete(context, pomo),
              icon: const Icon(Icons.check_rounded, size: 16, color: AppTheme.marsGreen),
              label: const Text('达成划线', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.marsGreen)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8F5F4),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0x33008779)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 9,
            child: OutlinedButton(
              onPressed: () => pomo.reset(),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                '放弃重置',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
              ),
            ),
          ),
        ],
      );
    }

    // 态 C: 空闲准备态 (单个沉浸大按钮)
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => pomo.start(),
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: Text(
          '开始专注 (${pomo.targetMinutes}m)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.marsGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          elevation: 4,
          shadowColor: AppTheme.marsGreen.withOpacity(0.4),
        ),
      ),
    );
  }

  /// 离线白噪音声学微仓 (pomo-ambient-dock)
  Widget _buildAmbientDock(PomodoroProvider pomo) {
    const ambientOptions = [
      {'name': '雨落窗台', 'icon': '🌧️', 'key': '雨落窗台'},
      {'name': '机械打字', 'icon': '☕', 'key': '机械打字'},
      {'name': '夜色篝火', 'icon': '🌲', 'key': '夜色篝火'},
      {'name': '静音模式', 'icon': '🔇', 'key': '静音模式'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.graphic_eq_rounded, size: 16, color: AppTheme.marsGreen),
                  SizedBox(width: 6),
                  Text(
                    '离线白噪音声学微仓',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (pomo.selectedSound != '静音模式')
                GestureDetector(
                  onTap: () => pomo.toggleSoundPreview(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (pomo.isRunning || pomo.isPreviewPlaying)
                          ? AppTheme.marsGreen.withOpacity(0.12)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (pomo.isRunning || pomo.isPreviewPlaying)
                              ? Icons.volume_up_rounded
                              : Icons.volume_mute_rounded,
                          size: 13,
                          color: (pomo.isRunning || pomo.isPreviewPlaying)
                              ? AppTheme.marsGreen
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pomo.isRunning
                              ? '播放中'
                              : (pomo.isPreviewPlaying ? '试听中' : '试听'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (pomo.isRunning || pomo.isPreviewPlaying)
                                ? AppTheme.marsGreen
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 颗环境声微药丸
          Row(
            children: ambientOptions.map((opt) {
              final isSelected = pomo.selectedSound == opt['key'];
              final isPlayingThis = isSelected && (pomo.isRunning || pomo.isPreviewPlaying);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () {
                      pomo.setSelectedSound(opt['key']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F5F4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.marsGreen : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPlayingThis && opt['key'] != '静音模式') ...[
                            // 动态跳跃波形指示
                            const _SoundWaveBars(),
                            const SizedBox(height: 4),
                          ] else ...[
                            Text(opt['icon']!, style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            opt['name']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppTheme.marsGreen : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 正在播放时微动效声波条
class _SoundWaveBars extends StatefulWidget {
  const _SoundWaveBars();

  @override
  State<_SoundWaveBars> createState() => _SoundWaveBarsState();
}

class _SoundWaveBarsState extends State<_SoundWaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final val = _anim.value;
        return SizedBox(
          height: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 2.5,
                height: 6 + 6 * val,
                decoration: BoxDecoration(
                  color: AppTheme.marsGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 2.5,
                height: 12 - 6 * val,
                decoration: BoxDecoration(
                  color: AppTheme.marsGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 2.5,
                height: 7 + 5 * val,
                decoration: BoxDecoration(
                  color: AppTheme.marsGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

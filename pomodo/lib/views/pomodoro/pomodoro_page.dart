import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/pomodoro_provider.dart';
import '../../widgets/pomodoro_dial.dart';

class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key});

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
                  // 顶部标题
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
                          color: pomo.isRunning ? AppTheme.marsGreen.withOpacity(0.1) : Colors.black.withOpacity(0.04),
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
                                color: pomo.isRunning ? AppTheme.marsGreen : Colors.black26,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pomo.isRunning ? '专注进行中' : '待命就绪',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: pomo.isRunning ? AppTheme.marsGreen : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 关联的任务胶囊
                  if (pomo.selectedTaskTitle != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.marsGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.marsGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.radio_button_checked, size: 16, color: AppTheme.marsGreen),
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
                            child: const Icon(Icons.close, size: 16, color: AppTheme.marsGreen),
                          ),
                        ],
                      ),
                    ),

                  // 博朗拟物 60 刻度精密机械表盘
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

                  const SizedBox(height: 36),

                  // 预设时长选择 (15 / 25 / 35 / 45m)
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

                  const SizedBox(height: 32),

                  // 控制按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (pomo.isRunning || pomo.isPaused)
                        IconButton.filled(
                          onPressed: () => pomo.reset(),
                          icon: const Icon(Icons.refresh, size: 22),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.06),
                            foregroundColor: AppTheme.textPrimary,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      if (pomo.isRunning || pomo.isPaused) const SizedBox(width: 20),

                      // 主操作按钮
                      ElevatedButton.icon(
                        onPressed: () {
                          if (pomo.isRunning) {
                            pomo.pause();
                          } else {
                            pomo.start();
                          }
                        },
                        icon: Icon(
                          pomo.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 26,
                        ),
                        label: Text(
                          pomo.isRunning ? '暂停专注' : (pomo.isPaused ? '继续计时' : '开始专注'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.marsGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                          shadowColor: AppTheme.marsGreen.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 白噪音选择器
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.graphic_eq, size: 18, color: AppTheme.marsGreen),
                            const SizedBox(width: 8),
                            const Text(
                              '环境白噪音',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                            if (pomo.selectedSound != '静音模式') ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => pomo.toggleSoundPreview(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (pomo.isRunning || pomo.isPreviewPlaying)
                                        ? AppTheme.marsGreen.withOpacity(0.15)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (pomo.isRunning || pomo.isPreviewPlaying)
                                            ? Icons.volume_up
                                            : Icons.volume_mute,
                                        size: 13,
                                        color: (pomo.isRunning || pomo.isPreviewPlaying)
                                            ? AppTheme.marsGreen
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        pomo.isRunning
                                            ? '播放中'
                                            : (pomo.isPreviewPlaying ? '试听中' : '试听'),
                                        style: TextStyle(
                                          fontSize: 10,
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
                          ],
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: pomo.selectedSound,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                            items: pomo.soundPresets.map((sound) {
                              return DropdownMenuItem(
                                value: sound,
                                child: Text(sound),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) pomo.setSelectedSound(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database_helper.dart';
import '../../models/pomodoro_session.dart';
import '../../providers/task_provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<PomodoroSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    setState(() => _isLoading = true);
    final sessions = await DatabaseHelper.instance.getAllSessions();
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.marsGreen,
          onRefresh: () async {
            await context.read<TaskProvider>().loadTasks();
            await _loadStatsData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Consumer<TaskProvider>(
              builder: (context, taskProv, child) {
                final totalFocusMinutes = _sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
                final totalHours = (totalFocusMinutes / 60).toStringAsFixed(1);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 页面标题
                    const Text(
                      'PERFORMANCE & REVIEW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppTheme.marsGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '复盘看板',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 核心指标卡片 2x2
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: '任务完成率',
                            value: '${(taskProv.completionRate * 100).toInt()}%',
                            subtitle: '${taskProv.completedCount} / ${taskProv.totalCount} 项',
                            icon: Icons.pie_chart_outline,
                            accentColor: AppTheme.marsGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            title: '专注总时长',
                            value: '${totalHours}h',
                            subtitle: '$totalFocusMinutes 分钟累计',
                            icon: Icons.timer_outlined,
                            accentColor: AppTheme.priorityP2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: '番茄时段',
                            value: '${_sessions.length}',
                            subtitle: '有效专注周期',
                            icon: Icons.check_circle_outline,
                            accentColor: AppTheme.priorityP3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            title: '待办存量',
                            value: '${taskProv.pendingCount}',
                            subtitle: '今日进行中',
                            icon: Icons.pending_actions_outlined,
                            accentColor: AppTheme.priorityP1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // 艾利法则完成分布
                    _buildIvyDistributionCard(taskProv),

                    const SizedBox(height: 28),

                    // 最近专注记录列表
                    const Text(
                      '最近专注流水 (SQLite 自持)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.marsGreen),
                        ),
                      )
                    else if (_sessions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty, size: 40, color: Colors.black.withOpacity(0.15)),
                            const SizedBox(height: 8),
                            const Text(
                              '暂无专注流水记录',
                              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sessions.take(10).length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final timeStr = session.startedAt.length >= 16
                              ? session.startedAt.substring(5, 16).replaceAll('T', ' ')
                              : session.startedAt;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.marsGreen.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.flash_on, size: 18, color: AppTheme.marsGreen),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.notes ?? '专注时段',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.marsGreen.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${session.durationMinutes}m',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.marsGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildIvyDistributionCard(TaskProvider taskProv) {
    final tasks = taskProv.tasks;
    final p1Total = tasks.where((t) => t.priority == 'P1').length;
    final p1Done = tasks.where((t) => t.priority == 'P1' && t.isCompleted).length;

    final p2Total = tasks.where((t) => t.priority == 'P2').length;
    final p2Done = tasks.where((t) => t.priority == 'P2' && t.isCompleted).length;

    final p3Total = tasks.where((t) => t.priority == 'P3').length;
    final p3Done = tasks.where((t) => t.priority == 'P3' && t.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '艾利优先级完成分布',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Text(
                'Ivy Lee 1~5 法则',
                style: TextStyle(fontSize: 12, color: AppTheme.marsGreen, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPriorityBar('P1 最高优先 (要率先击破)', p1Done, p1Total, AppTheme.priorityP1),
          const SizedBox(height: 12),
          _buildPriorityBar('P2 核心要务 (保持专注心流)', p2Done, p2Total, AppTheme.priorityP2),
          const SizedBox(height: 12),
          _buildPriorityBar('P3 次要跟进 (稳健推进完成)', p3Done, p3Total, AppTheme.priorityP3),
        ],
      ),
    );
  }

  Widget _buildPriorityBar(String label, int done, int total, Color color) {
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Text('$done/$total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

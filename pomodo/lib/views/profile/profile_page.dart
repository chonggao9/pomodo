import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/task_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().initProfile();
    });
  }

  void _showEditProfileDialog(BuildContext context, ProfileProvider profile) {
    final nameController = TextEditingController(text: profile.userName);
    final mottoController = TextEditingController(text: profile.motto);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('编辑本地名片', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '昵称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mottoController,
              decoration: const InputDecoration(labelText: '座右铭 / 专注心声'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              profile.updateProfile(
                name: nameController.text.trim(),
                motto: mottoController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.marsGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, profile, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标题
                  const Text(
                    'SYSTEM & SETTINGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppTheme.marsGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '我的与数据中心',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 个人本地卡片
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.marsGreen.withOpacity(0.12),
                          ),
                          child: const Icon(Icons.person_rounded, size: 32, color: AppTheme.marsGreen),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.motto,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textMuted),
                          onPressed: () => _showEditProfileDialog(context, profile),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 专属应用图标外观选择
                  const Text(
                    '专属应用图标设计 (双模内置)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildAppIconSelector(context, profile),

                  const SizedBox(height: 24),

                  // SQLite 本地数据中心看板
                  const Text(
                    'SQLite 本地数据中心 (纯单机自持)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storage_rounded, size: 20, color: AppTheme.marsGreen),
                            const SizedBox(width: 8),
                            const Text(
                              '底层引擎：SQLite 驱动',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: profile.integrityOk
                                    ? AppTheme.priorityP3.withOpacity(0.15)
                                    : Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                profile.integrityOk ? '完整性正常' : '检查异常',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: profile.integrityOk ? AppTheme.priorityP3 : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        _buildInfoRow('数据库物理大小', profile.formattedFileSize),
                        const SizedBox(height: 8),
                        _buildInfoRow('总任务记录行数', '${profile.dbStats['total_tasks']} 行'),
                        const SizedBox(height: 8),
                        _buildInfoRow('专注时段流水数', '${profile.dbStats['total_sessions']} 条'),
                        const SizedBox(height: 8),
                        _buildInfoRow('本地存储路径', profile.dbPath, isSubtle: true),

                        const SizedBox(height: 16),

                        // 操作按钮组
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final exportPath = await profile.exportDatabaseToDownload();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(exportPath != null
                                            ? '已安全备份至: $exportPath'
                                            : '备份生成完毕 (自持目录)'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text('备份导出 .db'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.marsGreen,
                                  side: const BorderSide(color: AppTheme.marsGreen),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('重置数据库？'),
                                      content: const Text('将清空所有数据并重新载入初始艾利种子任务。此操作不可逆。'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('确定重置', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await profile.resetAllData();
                                    if (context.mounted) {
                                      final messenger = ScaffoldMessenger.of(context);
                                      await context.read<TaskProvider>().loadTasks();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('已重置数据库并载入初始种子数据'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('清空重置'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textSecondary,
                                  side: const BorderSide(color: AppTheme.borderLight),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 关于与支持
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '关于与官方支持',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('架构设计', 'Flutter 3.47.2 原生 Android 纯单机'),
                        const SizedBox(height: 8),
                        _buildInfoRow('版本号', 'v1.0.0 (Native Release)'),
                        const SizedBox(height: 8),
                        _buildInfoRow('设计哲学', 'Dieter Rams 拟物 × Things 3 极简白'),
                        const SizedBox(height: 8),
                        _buildInfoRow('支持邮箱', 'chonggao9@gmail.com'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSubtle = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSubtle ? 11 : 13,
              fontWeight: isSubtle ? FontWeight.w400 : FontWeight.w600,
              color: isSubtle ? AppTheme.textMuted : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppIconSelector(BuildContext context, ProfileProvider profile) {
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
          const Text(
            '点击可切换应用在端内的主题图标风格：',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // 方案 A：极简白瓷版
              Expanded(
                child: _buildIconOptionCard(
                  title: '极简白瓷款',
                  subtitle: 'Things 3 纯白空气感',
                  imagePath: 'assets/icons/pomodo_icon_light_ceramic.jpg',
                  isSelected: profile.appIconTheme == 'light',
                  onTap: () {
                    profile.setAppIconTheme('light');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已激活【极简白瓷版】图标风格'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // 方案 B：深邃马尔斯绿暗雅版
              Expanded(
                child: _buildIconOptionCard(
                  title: '深邃暗雅款',
                  subtitle: 'Dieter Rams 沉浸绿',
                  imagePath: 'assets/icons/pomodo_icon_dark_marrs.jpg',
                  isSelected: profile.appIconTheme == 'dark',
                  onTap: () {
                    profile.setAppIconTheme('dark');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已激活【深邃暗雅款】图标风格'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconOptionCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.marsGreen.withOpacity(0.06) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.marsGreen : AppTheme.borderLight,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.marsGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppTheme.marsGreen : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

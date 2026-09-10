import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _badgesExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().initProfile();
    });
  }

  // 1. 本地个人档案编辑弹窗
  void _showEditProfileSheet(BuildContext context, ProfileProvider profile) {
    final nameController = TextEditingController(text: profile.userName);
    final mottoController = TextEditingController(text: profile.motto);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '编辑本地名片',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '昵称',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: mottoController,
              decoration: InputDecoration(
                labelText: '座右铭 / 专注心声',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('保存修改', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. SQLite 本地数据库中心底部抽屉
  void _showDatabaseCenterSheet(BuildContext context, ProfileProvider profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.storage_rounded, color: AppTheme.marsGreen, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'SQLite 3 本地数据中心',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: profile.integrityOk ? AppTheme.priorityP3.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    profile.integrityOk ? '完整性正常' : '校验异常',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: profile.integrityOk ? AppTheme.priorityP3 : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '100% 离线单机自持 · 零网络请求 · 数据私有安全',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const Divider(height: 24),

            _buildDetailRow('数据库物理大小', profile.formattedFileSize),
            const SizedBox(height: 8),
            _buildDetailRow('待办任务行数', '${profile.dbStats['total_tasks']} 行'),
            const SizedBox(height: 8),
            _buildDetailRow('专注时段流水', '${profile.dbStats['total_sessions']} 条'),
            const SizedBox(height: 8),
            _buildDetailRow('存储绝对路径', profile.dbPath, isSubtle: true),

            const SizedBox(height: 24),

            // 操作按钮组
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final exportPath = await profile.exportDatabaseToDownload();
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(exportPath != null ? '已安全备份至: $exportPath' : '备份完成'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('导出 .db 备份'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.marsGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final taskProv = context.read<TaskProvider>();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('重置数据库？'),
                        content: const Text('将清空所有任务与专注记录，并恢复初始艾利种子数据。此操作不可逆。'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('取消')),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            child: const Text('确定重置', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      nav.pop();
                      await profile.resetAllData();
                      await taskProv.loadTasks();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('已成功重置数据库并载入种子数据'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('清空重置'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. 主题色与风格切换抽屉 (包含双模图标选择)
  void _showThemeAndIconSheet(BuildContext context, ProfileProvider profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '主题色与风格',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  '正统官方马尔斯绿 · 双模专属应用图标',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                // 双模图标卡片
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          profile.setAppIconTheme('light');
                          setSheetState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: profile.appIconTheme == 'light'
                                ? AppTheme.marsGreen.withOpacity(0.08)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: profile.appIconTheme == 'light' ? AppTheme.marsGreen : AppTheme.borderLight,
                              width: profile.appIconTheme == 'light' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/icons/pomodo_icon_light_ceramic.jpg',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('极简白瓷版', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              const Text('Things 3 纯白通透', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          profile.setAppIconTheme('dark');
                          setSheetState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: profile.appIconTheme == 'dark'
                                ? AppTheme.marsGreen.withOpacity(0.08)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: profile.appIconTheme == 'dark' ? AppTheme.marsGreen : AppTheme.borderLight,
                              width: profile.appIconTheme == 'dark' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/icons/pomodo_icon_dark_marrs.jpg',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('深邃暗雅版', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              const Text('Dieter Rams 沉浸绿', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 4. 徽章详情弹窗
  void _showBadgeDetail(BuildContext context, String title, String desc, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
              color: isUnlocked ? AppTheme.marsGreen : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          desc,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('了解')),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 顶部居中头像与昵称区 (1:1 严格对齐设计稿)
                  _buildProfileHero(context, profile),

                  const SizedBox(height: 20),

                  // 卡片：我的徽章 (1:1 对齐设计稿)
                  _buildBadgesCard(context),

                  const SizedBox(height: 18),

                  // 分组 1：数据与自持档案
                  _buildCardGroup([
                    _buildListRow(
                      icon: Icons.person_outline_rounded,
                      title: '本地个人档案',
                      meta: '${profile.userName} · 专注模式',
                      onTap: () => _showEditProfileSheet(context, profile),
                    ),
                    const Divider(height: 1, indent: 46, endIndent: 14, color: AppTheme.borderLight),
                    _buildListRow(
                      icon: Icons.storage_rounded,
                      title: 'SQLite 本地数据库中心',
                      meta: 'SQLite 3 · 导出/备份',
                      onTap: () => _showDatabaseCenterSheet(context, profile),
                    ),
                  ]),

                  const SizedBox(height: 18),

                  // 分组标题：个性化
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        '个性化',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                    ),
                  ),

                  // 分组 2：个性化设置
                  _buildCardGroup([
                    _buildListRow(
                      icon: Icons.settings_outlined,
                      title: '基本设置',
                      meta: '外观：浅色模式',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('当前为正统 Things 3 极简浅色模式'), behavior: SnackBarBehavior.floating),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 46, endIndent: 14, color: AppTheme.borderLight),
                    _buildListRow(
                      icon: Icons.palette_outlined,
                      title: '主题色与风格',
                      meta: profile.appIconTheme == 'light' ? '马尔斯绿 (白瓷)' : '深邃暗雅 (墨绿)',
                      onTap: () => _showThemeAndIconSheet(context, profile),
                    ),
                    const Divider(height: 1, indent: 46, endIndent: 14, color: AppTheme.borderLight),
                    _buildListRow(
                      icon: Icons.checklist_rounded,
                      title: '待办与清单设置',
                      meta: '艾利 1~5 排序 · 就地划线',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('艾利 Lee 黄金法则：每日聚焦 5 件最核心要务'), behavior: SnackBarBehavior.floating),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 46, endIndent: 14, color: AppTheme.borderLight),
                    _buildListRow(
                      icon: Icons.timer_outlined,
                      title: '专注与番茄设置',
                      meta: '25m 专注 · 5m 短休',
                      onTap: () {
                        context.read<PomodoroProvider>().setTargetMinutes(25);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已设定为经典 25 分钟番茄专注周期'), behavior: SnackBarBehavior.floating),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 46, endIndent: 14, color: AppTheme.borderLight),
                    _buildListRow(
                      icon: Icons.language_rounded,
                      title: '语言 / Language',
                      meta: '简体中文 (默认)',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('原生默认简体中文'), behavior: SnackBarBehavior.floating),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 头部居中头像与昵称区
  Widget _buildProfileHero(BuildContext context, ProfileProvider profile) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // 圆形彩霞渐变头像
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF60A5FA), // 晨空蓝
                Color(0xFFF472B6), // 暮霞粉
                Color(0xFFFB923C), // 落日橙
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF472B6).withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 剪影人像轮廓
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 50,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 昵称与性别徽章行 (设计稿: Vy ♂)
        GestureDetector(
          onTap: () => _showEditProfileSheet(context, profile),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.userName == 'PomoDo 探索者' ? 'Vy' : profile.userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '♂',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 卡片：我的徽章
  Widget _buildBadgesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏
          GestureDetector(
            onTap: () => setState(() => _badgesExpanded = !_badgesExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.military_tech_outlined, size: 18, color: AppTheme.marsGreen),
                    SizedBox(width: 6),
                    Text(
                      '我的徽章',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Icon(
                  _badgesExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),

          if (_badgesExpanded) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 徽章 1：时间掌控者 (已点亮)
                _buildBadgeItem(
                  icon: Icons.self_improvement_rounded,
                  title: '时间掌控者',
                  isUnlocked: true,
                  onTap: () => _showBadgeDetail(context, '时间掌控者', '已达成：连续 7 天完成每日艾利核心待办！', true),
                ),
                // 徽章 2：专注魔王 (未解锁)
                _buildBadgeItem(
                  icon: Icons.track_changes_rounded,
                  title: '专注魔王',
                  isUnlocked: false,
                  onTap: () => _showBadgeDetail(context, '专注魔王', '未解锁：累计专注满 50 小时点亮 (当前进度 18/50h)', false),
                ),
                // 徽章 3：番茄富翁 (未解锁)
                _buildBadgeItem(
                  icon: Icons.emoji_events_outlined,
                  title: '番茄富翁',
                  isUnlocked: false,
                  onTap: () => _showBadgeDetail(context, '番茄富翁', '未解锁：单日完成 10 个有效番茄钟即可点亮', false),
                ),
                // 徽章 4：夜行侠 (未解锁)
                _buildBadgeItem(
                  icon: Icons.nightlight_round,
                  title: '夜行侠',
                  isUnlocked: false,
                  onTap: () => _showBadgeDetail(context, '夜行侠', '未解锁：夜晚 22:00 之后完成 1 次有效专注即可点亮', false),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeItem({
    required IconData icon,
    required String title,
    required bool isUnlocked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUnlocked ? const Color(0xFF00E6CC).withOpacity(0.18) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? const Color(0xFF00E6CC) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E6CC).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: 22,
              color: isUnlocked ? AppTheme.marsGreen : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
              color: isUnlocked ? AppTheme.textPrimary : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // 纯白圆角分组卡片容器
  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // 纯白列表行
  Widget _buildListRow({
    required IconData icon,
    required String title,
    required String meta,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.marsGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ),
            Text(
              meta,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isSubtle = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
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
}

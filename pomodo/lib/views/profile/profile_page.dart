import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/update_service.dart';
import '../../core/i18n/app_strings.dart';
import '../../providers/profile_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/category.dart';

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
      context.read<ProfileProvider>().refreshDiagnostics();
    });
  }

  // ================= 1. 本地个人档案编辑弹窗 =================
  void _showEditProfileSheet(BuildContext context, ProfileProvider profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);
    final nameController = TextEditingController(text: profile.userName);
    final mottoController = TextEditingController(text: profile.motto);
    String selectedGender = profile.gender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBgSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.isZh ? '编辑本地名片' : 'Edit Local Card',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: strings.isZh ? '昵称' : 'Nickname',
                  labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: mottoController,
                style: TextStyle(color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: strings.isZh ? '座右铭 / 专注心声' : 'Motto / Focus Statement',
                  labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.isZh ? '性别与名片标识' : 'Gender Identity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGenderChip(
                    context: context,
                    label: strings.isZh ? '♂ 男' : '♂ Male',
                    isSelected: selectedGender == 'male',
                    onTap: () => setSheetState(() => selectedGender = 'male'),
                  ),
                  const SizedBox(width: 10),
                  _buildGenderChip(
                    context: context,
                    label: strings.isZh ? '♀ 女' : '♀ Female',
                    isSelected: selectedGender == 'female',
                    onTap: () => setSheetState(() => selectedGender = 'female'),
                  ),
                  const SizedBox(width: 10),
                  _buildGenderChip(
                    context: context,
                    label: strings.isZh ? '👤 保密' : '👤 Private',
                    isSelected: selectedGender == 'secret',
                    onTap: () => setSheetState(() => selectedGender = 'secret'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final motto = mottoController.text.trim();
                    profile.updateProfile(
                      name: name.isNotEmpty ? name : 'Vy',
                      motto: motto.isNotEmpty ? motto : null,
                      gender: selectedGender,
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(strings.save, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.12)
                : (isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryColor : (isDark ? AppTheme.darkBorder : AppTheme.borderLight),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? primaryColor : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  // ================= 2. 工作清单与分类管理抽屉 =================
  void _showCategoryManagementSheet(BuildContext context, TaskProvider taskProv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer<TaskProvider>(
        builder: (context, prov, _) {
          final categories = prov.categories;
          final counts = prov.categoryTaskCounts;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBgSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_special_rounded, color: Theme.of(context).primaryColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          strings.listCategories,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateCategoryDialog(context, prov),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(strings.isZh ? '新建分类' : 'New', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  strings.isZh ? '管理本地清单标签与色彩，任务卡片自动关联显示。' : 'Manage local list labels & colors.',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (c, idx) {
                      final cat = categories[idx];
                      final pendingCount = counts[cat.id] ?? 0;
                      final isSystemDefault = cat.id == 'cat_work' || cat.id == 'cat_life';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cat.uiColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    strings.isZh ? '$pendingCount 个未完成待办事项' : '$pendingCount pending tasks',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showEditCategoryDialog(context, prov, cat),
                              icon: Icon(Icons.edit_outlined, size: 18, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                              tooltip: strings.isZh ? '编辑分类' : 'Edit Category',
                            ),
                            if (!isSystemDefault)
                              IconButton(
                                onPressed: () => _confirmDeleteCategory(context, prov, cat),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                tooltip: strings.isZh ? '删除分类' : 'Delete',
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  strings.isZh ? '默认' : 'Default',
                                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static const List<String> _categoryColors = [
    '#008779', // 马尔斯绿
    '#0EA5E9', // 晴空蓝
    '#8B5CF6', // 丁香紫
    '#F59E0B', // 琥珀橙
    '#10B981', // 青提绿
    '#EF4444', // 珊瑚红
  ];

  void _confirmDeleteCategory(BuildContext context, TaskProvider prov, Category cat) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('${strings.isZh ? '删除' : 'Delete'}「${cat.name}」？', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(strings.isZh ? '删除后，原属于该清单的任务不会被删除，将自动转为未分类。' : 'Tasks in this list will be unassigned, not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await prov.deleteCategory(cat.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, TaskProvider prov, Category cat) {
    final strings = AppStrings.of(context);
    final nameController = TextEditingController(text: cat.name);
    String selectedColor = cat.color;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(strings.isZh ? '编辑清单分类' : 'Edit List', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: strings.isZh ? '分类名称' : 'List Name',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Text(strings.isZh ? '选择色彩' : 'Select Color', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _categoryColors.map((c) {
                  final isCurrent = selectedColor.toUpperCase() == c.toUpperCase();
                  final colorObj = Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16));
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorObj,
                        border: Border.all(
                          color: isCurrent ? const Color(0xFF0F172A) : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isCurrent ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(strings.cancel)),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final nav = Navigator.of(dialogCtx);
                await prov.updateCategory(cat.copyWith(name: name, color: selectedColor));
                nav.pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(dialogCtx).primaryColor, foregroundColor: Colors.white),
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCategoryDialog(BuildContext context, TaskProvider prov) {
    final strings = AppStrings.of(context);
    final nameController = TextEditingController();
    String selectedColor = _categoryColors.first;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(strings.isZh ? '新建清单分类' : 'New List Category', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: strings.isZh ? '分类名称' : 'Category Name',
                  hintText: strings.isZh ? '如：阅读、考证、生活' : 'e.g. Work, Reading',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Text(strings.isZh ? '选择色彩' : 'Select Color', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _categoryColors.map((c) {
                  final isCurrent = selectedColor.toUpperCase() == c.toUpperCase();
                  final colorObj = Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16));
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorObj,
                        border: Border.all(
                          color: isCurrent ? const Color(0xFF0F172A) : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isCurrent ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(strings.cancel)),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final nav = Navigator.of(dialogCtx);
                await prov.addCategory(name: name, color: selectedColor);
                nav.pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(dialogCtx).primaryColor, foregroundColor: Colors.white),
              child: Text(strings.confirm),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 3. SQLite 本地数据中心抽屉 =================
  void _showDatabaseCenterSheet(BuildContext context, ProfileProvider profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBgSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.storage_rounded, color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  strings.dbCenter,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: profile.integrityOk ? AppTheme.priorityP3.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    profile.integrityOk ? (strings.isZh ? '完整性正常' : 'Healthy') : (strings.isZh ? '校验异常' : 'Corrupt'),
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
            Text(
              strings.isZh ? '100% 离线单机自持 · 零网络请求 · 数据私有安全' : '100% Offline Local Storage · Zero Network Requests',
              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
            ),
            Divider(height: 24, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),

            _buildDetailRow(context, strings.isZh ? '数据库物理大小' : 'Physical Size', profile.formattedFileSize),
            const SizedBox(height: 8),
            _buildDetailRow(context, strings.isZh ? '待办任务行数' : 'Total Tasks', '${profile.dbStats['total_tasks']}'),
            const SizedBox(height: 8),
            _buildDetailRow(context, strings.isZh ? '专注时段流水' : 'Focus Sessions', '${profile.dbStats['total_sessions']}'),
            const SizedBox(height: 8),
            _buildDetailRow(context, strings.isZh ? '存储绝对路径' : 'DB Path', profile.dbPath, isSubtle: true),

            const SizedBox(height: 24),

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
                    label: Text(strings.isZh ? '导出 .db 备份' : 'Export .db'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
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
                        title: Text(strings.isZh ? '重置数据库？' : 'Reset Database?'),
                        content: Text(strings.isZh ? '将清空所有任务与专注记录，并恢复初始艾利种子数据。此操作不可逆。' : 'All data will be reset to defaults.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text(strings.cancel)),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            child: Text(strings.isZh ? '确定重置' : 'Reset', style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      nav.pop();
                      await profile.resetAllData();
                      await taskProv.loadTasks();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(strings.isZh ? '已成功重置数据库并载入种子数据' : 'Database reset successfully'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(strings.isZh ? '清空重置' : 'Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
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

  // ================= 4. 基本设置：外观模式切换抽屉 =================
  void _showAppearanceSettingsSheet(BuildContext context, ProfileProvider profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final currentMode = profile.themeMode;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBgSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.basicSettings,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.isZh ? '界面外观模式 (即切即生效)' : 'Appearance Theme Mode',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                // 3 个模式单选卡片
                _buildModeOption(
                  context: context,
                  title: strings.modeLight,
                  desc: strings.isZh ? 'Things 3 纯白通透 · 优雅留白' : 'Things 3 Ceramic White & Clean',
                  icon: Icons.wb_sunny_rounded,
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () {
                    profile.setThemeMode(ThemeMode.light);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _buildModeOption(
                  context: context,
                  title: strings.modeDark,
                  desc: strings.isZh ? '深邃暗雅 · 墨绿黑曜沉浸心流' : 'Obsidian Marrs Green & Deep Dark',
                  icon: Icons.nightlight_round,
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () {
                    profile.setThemeMode(ThemeMode.dark);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _buildModeOption(
                  context: context,
                  title: strings.modeSystem,
                  desc: strings.isZh ? '随设备系统深浅色自动切换' : 'Follow system dark/light theme',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () {
                    profile.setThemeMode(ThemeMode.system);
                    setSheetState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String title,
    required String desc,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.09)
              : (isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? AppTheme.darkBorder : AppTheme.borderLight),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? primaryColor : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? primaryColor : (isDark ? AppTheme.darkTextMain : AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 20)
            else
              Icon(Icons.radio_button_unchecked_rounded, color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  // ================= 5. 主题色与风格切换抽屉 (做实方案 A 五套色彩体系) =================
  void _showThemeAndIconSheet(BuildContext context, ProfileProvider profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);
    final isZh = strings.isZh;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final curKey = profile.themeColorKey;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBgSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.themeAndStyle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isZh
                      ? '正统设计系统 · 五套精心调校的包豪斯强调色 (即选即生效)'
                      : 'Curated 5 Bauhaus accent theme palettes (Active instantly)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 18),

                // 5 套主题强调色列表
                ...AppTheme.accentThemes.map((opt) {
                  final isSelected = curKey == opt.key;
                  final optColor = opt.color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        profile.setThemeColor(opt.key);
                        setSheetState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? optColor.withOpacity(isDark ? 0.18 : 0.08)
                              : (isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? optColor
                                : (isDark ? AppTheme.darkBorder : AppTheme.borderLight),
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: optColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: optColor.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isZh ? opt.nameZh : opt.nameEn,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? (isDark ? Colors.white : optColor)
                                          : (isDark ? AppTheme.darkTextMain : AppTheme.textPrimary),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isZh ? opt.descZh : opt.descEn,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.radio_button_checked, color: optColor, size: 20)
                            else
                              Icon(
                                Icons.radio_button_unchecked,
                                color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= 6. 待办与清单设置抽屉 (彻底做实) =================
  void _showTodoSettingsSheet(BuildContext context, ProfileProvider profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBgSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.taskSettings,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.isZh ? '艾利 Lee 时间法则 · 聚焦核心要务与清单偏好' : 'Ivy Lee Method & Task Preferences',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                // 1. 每日艾利核心容量限制
                Text(
                  strings.dailyFocusLimit,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPillChoice(
                      context: context,
                      label: strings.isZh ? '3 项 (极简)' : '3 Tasks',
                      isSelected: profile.dailyTaskLimit == 3,
                      onTap: () {
                        profile.setDailyTaskLimit(3);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildPillChoice(
                      context: context,
                      label: strings.isZh ? '5 项 (黄金推荐)' : '5 Tasks (Ivy)',
                      isSelected: profile.dailyTaskLimit == 5,
                      onTap: () {
                        profile.setDailyTaskLimit(5);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildPillChoice(
                      context: context,
                      label: strings.isZh ? '6 项' : '6 Tasks',
                      isSelected: profile.dailyTaskLimit == 6,
                      onTap: () {
                        profile.setDailyTaskLimit(6);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildPillChoice(
                      context: context,
                      label: strings.isZh ? '不限制' : 'Unlimited',
                      isSelected: profile.dailyTaskLimit == 0,
                      onTap: () {
                        profile.setDailyTaskLimit(0);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. 任务完成行为
                Text(
                  strings.completionBehavior,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                _buildModeOption(
                  context: context,
                  title: strings.keepInPlace,
                  desc: strings.isZh ? '完成项保留在原顺位，墨水划线保留今日战报排布' : 'Strike through and keep in place for daily report',
                  icon: Icons.border_color_rounded,
                  isSelected: profile.completionBehavior == 'keep_in_place',
                  onTap: () {
                    profile.setCompletionBehavior('keep_in_place');
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _buildModeOption(
                  context: context,
                  title: strings.moveToBottom,
                  desc: strings.isZh ? '划线并自动移至未完成任务之后' : 'Move completed tasks to the bottom',
                  icon: Icons.vertical_align_bottom_rounded,
                  isSelected: profile.completionBehavior == 'move_to_bottom',
                  onTap: () {
                    profile.setCompletionBehavior('move_to_bottom');
                    setSheetState(() {});
                  },
                ),

                const SizedBox(height: 20),

                // 3. 次日自动顺延
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.rolloverStrategy,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.isZh ? '昨日未完成的高优要务自动保留在今日待办' : 'Incomplete tasks carry forward to tomorrow',
                              style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: profile.autoRollover,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (val) {
                          profile.setAutoRollover(val);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= 7. 专注与番茄设置抽屉 (彻底做实) =================
  void _showPomodoroSettingsSheet(BuildContext context, PomodoroProvider pomo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBgSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.focusSettings,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.isZh ? '设定适合你的专注节律与沉浸音景' : 'Customize focus duration & ambient sounds',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                // 1. 默认专注时长
                Text(
                  strings.focusDuration,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: pomo.presetMinutes.map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildPillChoice(
                          context: context,
                          label: '$m ${strings.minutesUnit}',
                          isSelected: pomo.targetMinutes == m,
                          onTap: () {
                            pomo.setTargetMinutes(m);
                            setSheetState(() {});
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. 短休时长
                Text(
                  strings.breakDuration,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: pomo.presetBreakMinutes.map((b) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildPillChoice(
                          context: context,
                          label: '$b ${strings.minutesUnit}',
                          isSelected: pomo.breakMinutes == b,
                          onTap: () {
                            pomo.setBreakMinutes(b);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 3. 默认环境白噪音
                Text(
                  strings.defaultWhiteNoise,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: pomo.soundPresets.map((snd) {
                      final isSelected = pomo.selectedSound == snd;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildPillChoice(
                          context: context,
                          label: snd,
                          isSelected: isSelected,
                          onTap: () {
                            pomo.setSelectedSound(snd);
                            setSheetState(() {});
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= 8. 语言切换抽屉 (彻底做实) =================
  void _showLanguageSettingsSheet(BuildContext context, LocaleProvider localeProv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final cur = localeProv.language;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBgSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.language,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.isZh ? '选择应用界面语言 (非中文字系默认 Fallback 英文)' : 'Choose App Display Language',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                _buildModeOption(
                  context: context,
                  title: strings.isZh ? '跟随系统 (System Default)' : 'System Default',
                  desc: strings.isZh ? '随设备系统语言自动识别，非中文一律使用英文' : 'Auto detect system locale (Fallback to English)',
                  icon: Icons.language_rounded,
                  isSelected: cur == AppLanguage.system,
                  onTap: () {
                    localeProv.setLanguage(AppLanguage.system);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _buildModeOption(
                  context: context,
                  title: '简体中文 (Simplified Chinese)',
                  desc: '完全使用正统中文排版与术语',
                  icon: Icons.translate_rounded,
                  isSelected: cur == AppLanguage.zh,
                  onTap: () {
                    localeProv.setLanguage(AppLanguage.zh);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _buildModeOption(
                  context: context,
                  title: 'English (US)',
                  desc: 'Full English UI strings and terminology',
                  icon: Icons.public_rounded,
                  isSelected: cur == AppLanguage.en,
                  onTap: () {
                    localeProv.setLanguage(AppLanguage.en);
                    setSheetState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPillChoice({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.12)
              : (isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? AppTheme.darkBorder : AppTheme.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primaryColor : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  // ================= 9. 真实徽章详情弹窗 (SQLite 驱动) =================
  void _showBadgeDetail(BuildContext context, String title, String desc, bool isUnlocked, String progressText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkBgSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
              color: isUnlocked ? Theme.of(context).primaryColor : (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              desc,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Theme.of(context).primaryColor.withOpacity(0.08)
                    : (isDark ? AppTheme.darkBgPage : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUnlocked ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.transparent,
                ),
              ),
              child: Text(
                progressText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? Theme.of(context).primaryColor : (isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.confirm, style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  // ================= 10. 检查版本更新 =================
  Future<void> _handleCheckUpdate() async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(strings.isZh ? '正在连接 GitHub 检查最新发布版...' : 'Checking GitHub for updates...'),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final info = await UpdateService.checkUpdate();
    if (!mounted) return;

    if (info == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(strings.isZh ? '更新检测' : 'Check Updates', style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Text(strings.isZh ? '暂未获取到 GitHub 更新信息，您可直接前往 Releases 页面查看与下载最新安装包。' : 'Unable to reach GitHub. You can visit Releases directly.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.cancel)),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                UpdateService.openUrl('https://github.com/${UpdateService.githubRepo}/releases');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              child: Text(strings.isZh ? '前往 Releases 网页' : 'Open Releases'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              info.hasNewVersion ? Icons.system_update_rounded : Icons.check_circle_outline_rounded,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              info.hasNewVersion
                  ? (strings.isZh ? '发现新版本 ${info.tagName}' : 'New Version ${info.tagName}')
                  : (strings.isZh ? '已是最新版本' : 'Already Up to Date'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前版本: v${UpdateService.currentVersion} | GitHub: ${info.tagName}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Text(
                info.changelog,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(info.hasNewVersion ? (strings.isZh ? '暂不更新' : 'Later') : (strings.isZh ? '好的' : 'OK')),
          ),
          if (info.apkDownloadUrl != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                UpdateService.openUrl(info.apkDownloadUrl!);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              child: Text(strings.isZh ? '下载最新 APK' : 'Download APK'),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                UpdateService.openUrl(info.releaseUrl);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              child: Text(strings.isZh ? '查看 GitHub 发布' : 'View on GitHub'),
            ),
        ],
      ),
    );
  }

  // ================= 主视图构建 =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgPage : AppTheme.bgPage,
      body: SafeArea(
        child: Consumer3<ProfileProvider, PomodoroProvider, LocaleProvider>(
          builder: (context, profile, pomo, localeProv, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. 顶部居中头像与昵称区
                  _buildProfileHero(context, profile),

                  const SizedBox(height: 20),

                  // 2. 卡片：我的徽章 (SQLite 驱动真实数据)
                  _buildBadgesCard(context, profile),

                  const SizedBox(height: 18),

                  // 3. 分组 1：数据与自持档案
                  _buildCardGroup(
                    context: context,
                    children: [
                      _buildListRow(
                        context: context,
                        icon: Icons.person_outline_rounded,
                        title: strings.localProfile,
                        meta: '${profile.userName} · ${strings.isZh ? '专注模式' : 'Focus'}',
                        onTap: () => _showEditProfileSheet(context, profile),
                      ),
                      Divider(height: 1, indent: 46, endIndent: 14, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
                      _buildListRow(
                        context: context,
                        icon: Icons.storage_rounded,
                        title: strings.dbCenter,
                        meta: strings.isZh ? 'SQLite 3 · 导出/备份' : 'SQLite 3 · Backup',
                        onTap: () => _showDatabaseCenterSheet(context, profile),
                      ),
                      Divider(height: 1, indent: 46, endIndent: 14, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
                      Consumer<TaskProvider>(
                        builder: (context, taskProv, _) {
                          return _buildListRow(
                            context: context,
                            icon: Icons.folder_special_outlined,
                            title: strings.listCategories,
                            meta: strings.isZh
                                ? '${taskProv.categories.length} 个分类 · 标签与色彩'
                                : '${taskProv.categories.length} Lists & Tags',
                            onTap: () => _showCategoryManagementSheet(context, taskProv),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 分组标题：个性化
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        strings.personalization,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),

                  // 4. 分组 2：个性化设置 (全真实抽屉)
                  _buildCardGroup(
                    context: context,
                    children: [
                      // 4.1 基本设置 (外观深浅)
                      _buildListRow(
                        context: context,
                        icon: Icons.settings_outlined,
                        title: strings.basicSettings,
                        meta: '${strings.appearance}: ${profile.themeMode == ThemeMode.dark ? strings.modeDark : (profile.themeMode == ThemeMode.light ? strings.modeLight : strings.modeSystem)}',
                        onTap: () => _showAppearanceSettingsSheet(context, profile),
                      ),
                      Divider(height: 1, indent: 46, endIndent: 14, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),

                      // 4.2 主题色与风格 (真实五套强调色体系)
                      Builder(
                        builder: (ctx) {
                          final activeTheme = AppTheme.accentThemes.firstWhere(
                            (e) => e.key == profile.themeColorKey,
                            orElse: () => AppTheme.accentThemes.first,
                          );
                          return _buildListRow(
                            context: context,
                            icon: Icons.palette_outlined,
                            title: strings.themeAndStyle,
                            meta: strings.isZh ? activeTheme.nameZh : activeTheme.nameEn,
                            onTap: () => _showThemeAndIconSheet(context, profile),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 46, endIndent: 14, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),

                      // 4.3 待办与清单设置 (彻底做实)
                      _buildListRow(
                        context: context,
                        icon: Icons.checklist_rounded,
                        title: strings.taskSettings,
                        meta: strings.isZh
                            ? '艾利 ${profile.dailyTaskLimit == 0 ? '不限' : '${profile.dailyTaskLimit}件'} · ${profile.completionBehavior == 'keep_in_place' ? '就地划线' : '下沉'}'
                            : '${profile.dailyTaskLimit == 0 ? 'Unlimited' : '${profile.dailyTaskLimit} tasks'} · Strike',
                        onTap: () => _showTodoSettingsSheet(context, profile),
                      ),
                      Divider(height: 1, indent: 46, endIndent: 14, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),

                      // 4.4 专注与番茄设置 (彻底做实)
                      _buildListRow(
                        context: context,
                        icon: Icons.timer_outlined,
                        title: strings.focusSettings,
                        meta: '${pomo.targetMinutes}m ${strings.isZh ? '专注' : 'focus'} · ${pomo.breakMinutes}m ${strings.isZh ? '短休' : 'break'}',
                        onTap: () => _showPomodoroSettingsSheet(context, pomo),
                      ),
                      Divider(height: 1, indent: 46, endIndent: 14, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),

                      // 4.5 语言 / Language (彻底做实)
                      _buildListRow(
                        context: context,
                        icon: Icons.language_rounded,
                        title: strings.language,
                        meta: localeProv.language == AppLanguage.system
                            ? strings.modeSystem
                            : (localeProv.isZh ? '简体中文' : 'English'),
                        onTap: () => _showLanguageSettingsSheet(context, localeProv),
                      ),
                      Divider(height: 1, indent: 46, endIndent: 14, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),

                      // 4.6 检查版本更新 (动态真实版本号)
                      _buildListRow(
                        context: context,
                        icon: Icons.system_update_alt_rounded,
                        title: strings.checkUpdate,
                        meta: 'v${UpdateService.currentVersion} (GitHub) ›',
                        onTap: _handleCheckUpdate,
                      ),
                    ],
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

  // 头部居中头像与昵称区
  Widget _buildProfileHero(BuildContext context, ProfileProvider profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final genderSymbol = profile.gender == 'female' ? '♀' : (profile.gender == 'male' ? '♂' : '👤');
    final genderColor = profile.gender == 'female' ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF60A5FA),
                Color(0xFFF472B6),
                Color(0xFFFB923C),
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

        // 昵称与性别标签
        GestureDetector(
          onTap: () => _showEditProfileSheet(context, profile),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.userName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: genderColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  genderSymbol,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: genderColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.motto,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // 卡片：我的徽章 (SQLite 真实数据驱动)
  Widget _buildBadgesCard(BuildContext context, ProfileProvider profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);
    final badges = profile.badgeAchievements;

    final timeMaster = badges['time_master'] as Map<String, dynamic>? ?? {};
    final focusKing = badges['focus_king'] as Map<String, dynamic>? ?? {};
    final pomoTycoon = badges['pomo_tycoon'] as Map<String, dynamic>? ?? {};
    final nightOwl = badges['night_owl'] as Map<String, dynamic>? ?? {};

    final tmUnlocked = (timeMaster['unlocked'] as bool?) ?? false;
    final fkUnlocked = (focusKing['unlocked'] as bool?) ?? false;
    final ptUnlocked = (pomoTycoon['unlocked'] as bool?) ?? false;
    final noUnlocked = (nightOwl['unlocked'] as bool?) ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _badgesExpanded = !_badgesExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.military_tech_outlined, size: 18, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      strings.myBadges,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _badgesExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
              ],
            ),
          ),

          if (_badgesExpanded) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. 时间掌控者
                _buildBadgeItem(
                  context: context,
                  icon: Icons.self_improvement_rounded,
                  title: strings.badgeTimeMaster,
                  isUnlocked: tmUnlocked,
                  onTap: () {
                    final cur = timeMaster['current'] ?? 0;
                    _showBadgeDetail(
                      context,
                      strings.badgeTimeMaster,
                      strings.isZh ? '达成条件：累计完成 7 项艾利核心待办任务。' : 'Requirement: Complete 7 core tasks.',
                      tmUnlocked,
                      tmUnlocked
                          ? (strings.isZh ? '已达成：已完成 $cur/7 项要务' : 'Achieved: $cur/7 completed')
                          : (strings.isZh ? '当前进度：$cur / 7 项要务' : 'Progress: $cur / 7 tasks'),
                    );
                  },
                ),
                // 2. 专注魔王
                _buildBadgeItem(
                  context: context,
                  icon: Icons.track_changes_rounded,
                  title: strings.badgeFocusKing,
                  isUnlocked: fkUnlocked,
                  onTap: () {
                    final curMin = (focusKing['current'] as int?) ?? 0;
                    final curHours = (curMin / 60).toStringAsFixed(1);
                    _showBadgeDetail(
                      context,
                      strings.badgeFocusKing,
                      strings.isZh ? '达成条件：累计专注总时长达到 50 小时。' : 'Requirement: Accumulate 50 hours of focus.',
                      fkUnlocked,
                      fkUnlocked
                          ? (strings.isZh ? '已达成：已累计专注 $curHours 小时' : 'Achieved: $curHours hours')
                          : (strings.isZh ? '当前进度：$curHours / 50 小时' : 'Progress: $curHours / 50 hrs'),
                    );
                  },
                ),
                // 3. 番茄富翁
                _buildBadgeItem(
                  context: context,
                  icon: Icons.emoji_events_outlined,
                  title: strings.badgePomoTycoon,
                  isUnlocked: ptUnlocked,
                  onTap: () {
                    final cur = pomoTycoon['current'] ?? 0;
                    _showBadgeDetail(
                      context,
                      strings.badgePomoTycoon,
                      strings.isZh ? '达成条件：历史单日完成有效番茄钟达到 8 个。' : 'Requirement: Complete 8 pomodoros in a single day.',
                      ptUnlocked,
                      ptUnlocked
                          ? (strings.isZh ? '已达成：单日最高完成 $cur 个番茄钟' : 'Achieved: $cur completed in one day')
                          : (strings.isZh ? '当前最高单日：$cur / 8 个' : 'Daily high: $cur / 8'),
                    );
                  },
                ),
                // 4. 夜行侠
                _buildBadgeItem(
                  context: context,
                  icon: Icons.nightlight_round,
                  title: strings.badgeNightOwl,
                  isUnlocked: noUnlocked,
                  onTap: () {
                    final cur = nightOwl['current'] ?? 0;
                    _showBadgeDetail(
                      context,
                      strings.badgeNightOwl,
                      strings.isZh ? '达成条件：在夜晚 22:00 ~ 04:00 之间完成过至少 1 次有效专注。' : 'Requirement: Complete a focus session between 22:00 and 04:00.',
                      noUnlocked,
                      noUnlocked
                          ? (strings.isZh ? '已达成：夜间自律专注 $cur 次' : 'Achieved: $cur night sessions')
                          : (strings.isZh ? '未解锁：夜间 22:00 后完成 1 次专注即可点亮' : 'Locked: Focus once after 22:00'),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isUnlocked,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF00E6CC).withOpacity(0.18)
                  : (isDark ? AppTheme.darkBgPage : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? const Color(0xFF00E6CC) : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
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
              color: isUnlocked ? Theme.of(context).primaryColor : (isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
              color: isUnlocked
                  ? (isDark ? AppTheme.darkTextMain : AppTheme.textPrimary)
                  : (isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  // 纯白圆角分组卡片容器
  Widget _buildCardGroup({required BuildContext context, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.015),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String meta,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextMain : AppTheme.textPrimary,
                ),
              ),
            ),
            Text(
              meta,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isSubtle = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          ),
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
              color: isSubtle
                  ? (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)
                  : (isDark ? AppTheme.darkTextMain : AppTheme.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

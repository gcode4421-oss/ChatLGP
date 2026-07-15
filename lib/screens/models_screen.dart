/// شاشة إدارة النماذج — عرض النماذج المثبتة وتحميل نماذج جديدة وحذفها

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, double> _pullProgress = {};
  final Map<String, String> _pullStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshModels();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final colors = AppColorsExtension.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة النماذج'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المثبتة', icon: Icon(Icons.download_done)),
            Tab(text: 'متاحة للتحميل', icon: Icon(Icons.cloud_download)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.refreshModels,
          ),
        ],
      ),
      body: provider.connectionState != ConnectionState.connected
          ? _buildNotConnected(context, provider)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInstalledTab(provider, colors),
                _buildAvailableTab(provider, colors),
              ],
            ),
    );
  }

  Widget _buildNotConnected(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'غير متصل بـ Ollama',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'يجب الاتصال بخادم Ollama لإدارة النماذج.\n'
              'العنوان الحالي: ${provider.aiService.config.baseUrl}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.testConnection,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: const Icon(Icons.settings),
              label: const Text('تعديل الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstalledTab(AppProvider provider, AppColorsExtension colors) {
    if (provider.models.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('لا توجد نماذج مثبتة'),
            const SizedBox(height: 8),
            const Text('انتقل إلى تبويب "متاحة للتحميل" لتثبيت أول نموذج'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('تصفح النماذج'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.models.length,
      itemBuilder: (ctx, i) {
        final model = provider.models[i];
        final isActive = model.name == provider.currentModel;
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? colors.success.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isActive ? Icons.check_circle : Icons.memory,
                color: isActive ? colors.success : Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              model.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? colors.success : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الحجم: ${model.sizeFormatted}'),
                if (model.digest != null)
                  Text(
                    'ID: ${model.digest!.substring(0, 12)}...',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'use') {
                  provider.setModel(model.name);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم اختيار ${model.displayName}')),
                    );
                  }
                } else if (v == 'delete') {
                  _confirmDelete(provider, model);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'use', child: Text('استخدم كافتراضي')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        ).animate().fadeIn(delay: (i * 50).ms);
      },
    );
  }

  Widget _buildAvailableTab(AppProvider provider, AppColorsExtension colors) {
    return DefaultTabController(
      length: RecommendedModels.categories.length,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardTheme.color,
            child: TabBar(
              isScrollable: true,
              tabs: RecommendedModels.categories
                  .map((c) => Tab(text: c))
                  .toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: RecommendedModels.categories.map((category) {
                final models = RecommendedModels.all
                    .where((m) => m.category == category)
                    .toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: models.length,
                  itemBuilder: (ctx, i) {
                    final model = models[i];
                    final installed = provider.models.any(
                      (m) => m.name == model.name || m.model == model.name,
                    );
                    final progress = _pullProgress[model.name];
                    final status = _pullStatus[model.name];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        model.recommended
                                            ? Icons.star
                                            : Icons.memory,
                                        size: 18,
                                        color: model.recommended
                                            ? colors.warning
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          model.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (installed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'مثبّت',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                else if (progress != null)
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: progress > 0 ? progress : null,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () =>
                                        _pullModel(provider, model.name),
                                    tooltip: 'تحميل',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              model.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.storage, size: 12, color: Theme.of(context).hintColor),
                                const SizedBox(width: 4),
                                Text(
                                  model.sizeHint,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.category, size: 12, color: Theme.of(context).hintColor),
                                const SizedBox(width: 4),
                                Text(
                                  model.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                            if (progress != null && progress < 1.0) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progress > 0 ? progress : null,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                status ?? 'جارٍ التحميل...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (i * 80).ms);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pullModel(AppProvider provider, String modelName) async {
    setState(() {
      _pullProgress[modelName] = 0;
      _pullStatus[modelName] = 'بدء التحميل...';
    });

    try {
      await provider.pullModel(
        modelName,
        onProgress: (completed, total, status) {
          if (mounted) {
            setState(() {
              _pullStatus[modelName] = status;
              if (completed != null && total != null && total > 0) {
                _pullProgress[modelName] = completed / total;
              }
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _pullProgress[modelName] = 1.0;
          _pullStatus[modelName] = 'اكتمل التحميل';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحميل $modelName بنجاح'),
            backgroundColor: AppColorsExtension.of(context).success,
          ),
        );
        // تنظيف بعد ثانيتين
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _pullProgress.remove(modelName);
              _pullStatus.remove(modelName);
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pullProgress.remove(modelName);
          _pullStatus[modelName] = 'فشل: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل النموذج: $e')),
        );
      }
    }
  }

  void _confirmDelete(AppProvider provider, AiModel model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف النموذج'),
        content: Text('سيتم حذف "${model.displayName}" (${model.sizeFormatted}). '
            'هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteModel(model.name);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حذف ${model.displayName}')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل الحذف: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

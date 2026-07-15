/// شاشة الإعدادات — الاتصال، النموذج الافتراضي، السلوك، المظهر

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _systemPromptCtrl;
  late TextEditingController _maxTokensCtrl;
  late double _temperature;
  late bool _useHttps;
  late bool _agentMode;
  late String _themeMode;
  late String _language;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final cfg = provider.aiService.config;
    _hostCtrl = TextEditingController(text: cfg.host);
    _portCtrl = TextEditingController(text: cfg.port.toString());
    _systemPromptCtrl = TextEditingController(text: StorageService.systemPrompt);
    _maxTokensCtrl = TextEditingController(
        text: StorageService.maxTokens?.toString() ?? '');
    _temperature = StorageService.temperature;
    _useHttps = cfg.useHttps;
    _agentMode = StorageService.agentMode;
    _themeMode = StorageService.themeMode;
    _language = StorageService.language;
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _systemPromptCtrl.dispose();
    _maxTokensCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final colors = AppColorsExtension.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─────────────── قسم الاتصال
          _buildSection(
            context,
            title: 'الاتصال',
            icon: Icons.wifi,
            children: [
              TextField(
                controller: _hostCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الخادم',
                  hintText: '127.0.0.1',
                  prefixIcon: Icon(Icons.dns),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المنفذ',
                  hintText: '11434',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('استخدام HTTPS'),
                subtitle: const Text('فعّله إذا كان الخادم يستخدم شهادة SSL'),
                value: _useHttps,
                onChanged: (v) => setState(() => _useHttps = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final cfg = OllamaConfig(
                          host: _hostCtrl.text.trim().isNotEmpty
                              ? _hostCtrl.text.trim()
                              : '127.0.0.1',
                          port: int.tryParse(_portCtrl.text) ?? 11434,
                          useHttps: _useHttps,
                        );
                        await provider.updateOllamaConfig(cfg);
                      },
                      icon: const Icon(Icons.wifi_protected_setup),
                      label: const Text('اختبار الاتصال'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final cfg = OllamaConfig(
                          host: _hostCtrl.text.trim().isNotEmpty
                              ? _hostCtrl.text.trim()
                              : '127.0.0.1',
                          port: int.tryParse(_portCtrl.text) ?? 11434,
                          useHttps: _useHttps,
                        );
                        await provider.updateOllamaConfig(cfg);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حفظ الإعدادات')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // معلومات إضافية
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.thinkingColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: colors.thinkingColor),
                        const SizedBox(width: 8),
                        Text(
                          'كيف تشغّل Ollama على هاتفك؟',
                          style: TextStyle(
                            color: colors.thinkingColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. ثبّت Termux من F-Droid\n'
                      '2. نفّذ: pkg install ollama\n'
                      '3. شغّل: ollama serve\n'
                      '4. اضبط العنوان على 127.0.0.1 والمنفذ 11434\n\n'
                      'أو: شغّل Ollama على الكمبيوتر وأدخل عنوان IP المحلي '
                      '(مثل 192.168.1.100) مع التأكد من إعداد OLLAMA_HOST=0.0.0.0',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─────────────── قسم السلوك
          _buildSection(
            context,
            title: 'السلوك',
            icon: Icons.tune,
            children: [
              SwitchListTile(
                title: const Text('وضع Agent'),
                subtitle: const Text(
                    'يسمح للمساعد باستخدام أدوات (حاسبة، تاريخ، تلخيص، ترجمة)'),
                value: _agentMode,
                onChanged: (v) {
                  setState(() => _agentMode = v);
                  provider.setAgentMode(v);
                },
                secondary: Icon(Icons.psychology, color: colors.thinkingColor),
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text('درجة الحرارة (الإبداع): ${_temperature.toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: _temperature,
                min: 0.0,
                max: 1.5,
                divisions: 15,
                label: _temperature.toStringAsFixed(1),
                onChanged: (v) => setState(() => _temperature = v),
                onChangeEnd: (v) {
                  StorageService.setTemperature(v);
                },
              ),
              Row(
                children: [
                  const Text('دقيقة', style: TextStyle(fontSize: 11)),
                  const Spacer(),
                  const Text('متوازن', style: TextStyle(fontSize: 11)),
                  const Spacer(),
                  const Text('إبداعي', style: TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxTokensCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'أقصى عدد للرموز (اختياري)',
                  hintText: 'اتركه فارغاً بلا حد',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  StorageService.setMaxTokens(v.isEmpty ? null : n);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _systemPromptCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'System Prompt مخصص',
                  hintText: 'اتركه فارغاً لاستخدام الافتراضي',
                  prefixIcon: Icon(Icons.edit_note),
                  alignLabelWithHint: true,
                ),
                onChanged: (v) => StorageService.setSystemPrompt(v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─────────────── قسم المظهر
          _buildSection(
            context,
            title: 'المظهر',
            icon: Icons.palette,
            children: [
              ListTile(
                title: const Text('السمة'),
                leading: const Icon(Icons.brightness_6),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'light', icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: 'system', icon: Icon(Icons.settings_brightness)),
                    ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode)),
                  ],
                  selected: {_themeMode},
                  onSelectionChanged: (s) {
                    setState(() => _themeMode = s.first);
                    StorageService.setThemeMode(s.first);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('اللغة'),
                leading: const Icon(Icons.language),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {_language},
                  onSelectionChanged: (s) {
                    setState(() => _language = s.first);
                    provider.setLanguage(s.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─────────────── قسم النموذج الافتراضي
          _buildSection(
            context,
            title: 'النموذج الافتراضي',
            icon: Icons.memory,
            children: [
              if (provider.models.isEmpty)
                ListTile(
                  leading: Icon(Icons.warning, color: colors.warning),
                  title: const Text('لا توجد نماذج مثبتة'),
                  subtitle: const Text('انتقل إلى إدارة النماذج لتثبيت نموذج'),
                  trailing: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/models'),
                    child: const Text('فتح'),
                  ),
                )
              else
                Column(
                  children: provider.models.map((m) {
                    final isActive = m.name == provider.currentModel;
                    return RadioListTile<String>(
                      value: m.name,
                      groupValue: provider.currentModel,
                      title: Text(m.displayName),
                      subtitle: Text(m.sizeFormatted),
                      onChanged: (v) {
                        if (v != null) provider.setModel(v);
                      },
                      selected: isActive,
                    );
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ─────────────── معلومات التطبيق
          Center(
            child: Column(
              children: [
                Text(
                  'LocalAI Assistant v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'مبني على Flutter + Ollama\nمفتوح المصدر ومجاني',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// الشاشة الرئيسية للمحادثة

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'models_screen.dart';
import 'conversations_screen.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      provider.testConnection();
      provider.loadConversations();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final colors = AppColorsExtension.of(context);

    // التمرير لأسفل عند إضافة رسائل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.messages.isNotEmpty) _scrollToBottom();
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.currentConversation?.title ?? 'محادثة جديدة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17),
            ),
            Row(
              children: [
                _buildConnectionDot(provider.connectionState, colors),
                const SizedBox(width: 6),
                Text(
                  provider.currentModel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (provider.agentMode) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.thinkingColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Agent',
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.thinkingColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'محادثة جديدة',
            onPressed: () => provider.startNewConversation(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'models':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ModelsScreen()));
                  break;
                case 'settings':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  break;
                case 'history':
                  _scaffoldKey.currentState?.openDrawer();
                  break;
                case 'agent':
                  provider.setAgentMode(!provider.agentMode);
                  break;
                case 'delete':
                  _confirmDeleteConversation(provider);
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'agent',
                child: Row(children: [
                  Icon(provider.agentMode
                      ? Icons.toggle_on
                      : Icons.toggle_off_outlined),
                  const SizedBox(width: 8),
                  Text(provider.agentMode ? 'إيقاف وضع Agent' : 'تشغيل وضع Agent'),
                ]),
              ),
              const PopupMenuItem(
                value: 'models',
                child: Row(children: [
                  Icon(Icons.model_training),
                  SizedBox(width: 8),
                  Text('إدارة النماذج'),
                ]),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 8),
                  Text('الإعدادات'),
                ]),
              ),
              if (provider.currentConversation != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('حذف المحادثة', style: TextStyle(color: Colors.red)),
                  ]),
                ),
            ],
          ),
        ],
      ),
      drawer: const ConversationsDrawer(),
      body: Column(
        children: [
          // شريط الحالة
          if (provider.connectionState != ConnectionState.connected)
            _buildStatusBar(provider, colors),

          // منطقة الرسائل
          Expanded(
            child: provider.messages.isEmpty
                ? _buildEmptyState(context, provider)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: provider.messages.length +
                        (provider.isGenerating &&
                                provider.currentThinking.isNotEmpty
                            ? 1
                            : 0) +
                        (provider.isGenerating && provider.toolEvents.isNotEmpty
                            ? 1
                            : 0),
                    itemBuilder: (ctx, i) {
                      if (i < provider.messages.length) {
                        return MessageBubble(message: provider.messages[i]);
                      }
                      // عرض التفكير والأدوات أثناء التوليد
                      if (provider.currentThinking.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.thinkingColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.psychology,
                                  size: 16, color: colors.thinkingColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.currentThinking,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.thinkingColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 4),
                        padding: const EdgeInsets.all(8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: provider.toolEvents
                              .map((e) => Chip(
                                    label: Text(e, style: const TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),
          ),

          // مؤشر التوليد
          if (provider.isGenerating && provider.messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.agentMode && provider.toolEvents.isNotEmpty
                        ? 'ينفّذ أداة...'
                        : 'يكتب...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),

          // حقل الإدخال
          ChatInput(
            onSend: (text) => provider.sendMessage(text),
            onStop: provider.stopGeneration,
            isGenerating: provider.isGenerating,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionDot(
      ConnectionState state, AppColorsExtension colors) {
    final Color color;
    switch (state) {
      case ConnectionState.connected:
        color = colors.success;
        break;
      case ConnectionState.connecting:
        color = colors.warning;
        break;
      case ConnectionState.error:
        color = colors.error;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3),
            duration: 1.seconds);
  }

  Widget _buildStatusBar(AppProvider provider, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: provider.connectionState == ConnectionState.error
          ? colors.error.withValues(alpha: 0.1)
          : colors.warning.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            provider.connectionState == ConnectionState.error
                ? Icons.error_outline
                : Icons.warning_amber,
            size: 16,
            color: provider.connectionState == ConnectionState.error
                ? colors.error
                : colors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.statusMessage.isNotEmpty
                  ? provider.statusMessage
                  : 'غير متصل — تأكد من تشغيل Ollama على ${provider.aiService.config.baseUrl}',
              style: TextStyle(
                fontSize: 12,
                color: provider.connectionState == ConnectionState.error
                    ? colors.error
                    : colors.warning,
              ),
            ),
          ),
          TextButton(
            onPressed: provider.testConnection,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    final suggestions = provider.language == 'ar'
        ? [
            'اشرح لي مفهوم الذكاء الاصطناعي ببساطة',
            'اكتب لي قصيدة قصيرة عن البحر',
            'ما هي فوائد التأمل اليومي؟',
            'ساعدني في كتابة كود Python لقراءة ملف',
          ]
        : [
            'Explain AI in simple terms',
            'Write a short poem about the sea',
            'What are the benefits of daily meditation?',
            'Help me write Python code to read a file',
          ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    AppColorsExtension.of(context).thinkingColor,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 50),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'LocalAI Assistant',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.language == 'ar'
                  ? 'مساعدك الذكي المحلي — خاص وآمن ومجاني'
                  : 'Your local AI assistant — private, secure, free',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions
                  .map((s) => ActionChip(
                        label: Text(s),
                        labelStyle: const TextStyle(fontSize: 12),
                        onPressed: () => provider.sendMessage(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteConversation(AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المحادثة'),
        content: const Text('هل أنت متأكد من حذف هذه المحادثة؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteCurrentConversation();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

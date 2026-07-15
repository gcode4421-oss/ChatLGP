/// درج جانبي يعرض قائمة المحادثات السابقة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/timeago_ar.dart';

class ConversationsDrawer extends StatefulWidget {
  const ConversationsDrawer({super.key});

  @override
  State<ConversationsDrawer> createState() => _ConversationsDrawerState();
}

class _ConversationsDrawerState extends State<ConversationsDrawer> {
  @override
  void initState() {
    super.initState();
    setLocaleMessages('ar', ArMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final colors = AppColorsExtension.of(context);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            // الرأس
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    colors.thinkingColor,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.smart_toy,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LocalAI Assistant',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${provider.conversations.length} محادثة',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // زر محادثة جديدة
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.startNewConversation();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('محادثة جديدة'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            // قائمة المحادثات
            Expanded(
              child: provider.conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 48,
                              color: Theme.of(context).hintColor),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد محادثات بعد',
                            style: TextStyle(color: Theme.of(context).hintColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: provider.conversations.length,
                      itemBuilder: (ctx, i) {
                        final conv = provider.conversations[i];
                        final isActive =
                            provider.currentConversation?.id == conv.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            leading: Icon(
                              Icons.chat_outlined,
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).hintColor,
                              size: 20,
                            ),
                            title: Text(
                              conv.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (conv.lastMessage != null)
                                  Text(
                                    conv.lastMessage!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).hintColor),
                                  ),
                                Text(
                                  format(conv.updatedAt, locale: 'ar'),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).hintColor),
                                ),
                              ],
                            ),
                            trailing: conv.modelUsed != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      conv.modelUsed!.split(':').first,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              provider.openConversation(conv.id);
                              Navigator.pop(context);
                            },
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (i * 50).ms, duration: 200.ms);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

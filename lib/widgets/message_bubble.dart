/// بطاقة عرض الرسالة في المحادثة

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLast;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final isUser = message.type.isUser;
    final isTool = message.type.isTool;
    final isThinking = message.type.isThinking;
    final isError = message.status == MessageStatus.error;
    final isStreaming = message.status == MessageStatus.streaming;

    if (isTool) {
      return _buildToolMessage(context, colors);
    }

    if (isThinking) {
      return _buildThinkingMessage(context, colors);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser, colors),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? colors.bubbleUser
                    : (isError
                        ? Colors.red.withValues(alpha: 0.1)
                        : colors.bubbleAssistant),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isError
                    ? Border.all(color: Colors.red.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser && message.modelName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_toy_outlined, size: 14,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            message.modelName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.content.isEmpty && isStreaming)
                    _buildTypingIndicator(context)
                  else
                    MarkdownBody(
                      data: message.content,
                      selectable: true,
                      onTapLink: (text, href, title) async {
                        if (href != null) {
                          final uri = Uri.parse(href);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        }
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser
                              ? colors.bubbleUserText
                              : colors.bubbleAssistantText,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        code: TextStyle(
                          backgroundColor: colors.codeBlockBg,
                          color: isUser
                              ? colors.bubbleUserText
                              : colors.bubbleAssistantText,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: colors.codeBlockBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                        h1: TextStyle(
                          color: isUser
                              ? colors.bubbleUserText
                              : colors.bubbleAssistantText,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: TextStyle(
                          color: isUser
                              ? colors.bubbleUserText
                              : colors.bubbleAssistantText,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: TextStyle(
                          color: isUser
                              ? colors.bubbleUserText
                              : colors.bubbleAssistantText,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        listBullet: TextStyle(
                          color: isUser
                              ? colors.bubbleUserText
                              : colors.bubbleAssistantText,
                        ),
                        blockquote: TextStyle(
                          color: isUser
                              ? colors.bubbleUserText.withValues(alpha: 0.85)
                              : colors.bubbleAssistantText.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: (isUser
                                  ? colors.bubbleUserText
                                  : colors.bubbleAssistantText)
                              .withValues(alpha: 0.08),
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isStreaming && message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildCursor(context),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) _buildAvatar(isUser, colors),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildAvatar(bool isUser, AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isUser ? colors.bubbleUser : colors.bubbleAssistant,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: isUser ? Colors.white : colors.thinkingColor,
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2),
                duration: 600.ms, delay: (i * 200).ms);
      }),
    );
  }

  Widget _buildCursor(BuildContext context) {
    return Container(
      width: 8,
      height: 16,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 300.ms).then().fadeOut(duration: 300.ms);
  }

  Widget _buildToolMessage(BuildContext context, AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 50),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.build_circle, size: 16, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أداة: ${message.toolName ?? "?"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingMessage(BuildContext context, AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 50),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.thinkingColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, size: 16, color: colors.thinkingColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.content,
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
}

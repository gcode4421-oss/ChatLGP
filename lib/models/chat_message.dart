/// نماذج البيانات للتطبيق

import 'package:flutter/foundation.dart';

/// نوع الرسالة: من المستخدم، من المساعد، أو رسالة نظام
enum MessageType { user, assistant, system, thinking, tool }

extension MessageTypeX on MessageType {
  bool get isUser => this == MessageType.user;
  bool get isAssistant => this == MessageType.assistant;
  bool get isThinking => this == MessageType.thinking;
  bool get isTool => this == MessageType.tool;
}

/// حالة الرسالة
enum MessageStatus { sending, streaming, done, error }

/// نموذج رسالة محادثة واحدة
@immutable
class ChatMessage {
  final String id;
  final String conversationId;
  final MessageType type;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final String? modelName;
  final String? toolName;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.done,
    this.modelName,
    this.toolName,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    MessageType? type,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
    String? modelName,
    String? toolName,
    Map<String, dynamic>? metadata,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        type: type ?? this.type,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        modelName: modelName ?? this.modelName,
        toolName: toolName ?? this.toolName,
        metadata: metadata ?? this.metadata,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'type': type.name,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
        'status': status.name,
        'model_name': modelName,
        'tool_name': toolName,
        'metadata': metadata != null ? metadata.toString() : null,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        type: MessageType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => MessageType.assistant,
        ),
        content: map['content'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        status: MessageStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => MessageStatus.done,
        ),
        modelName: map['model_name'] as String?,
        toolName: map['tool_name'] as String?,
      );

  /// يحول الرسالة إلى صيغة رسالة OpenAI-compatible لـ Ollama
  Map<String, dynamic> toOllamaFormat() {
    String role;
    switch (type) {
      case MessageType.user:
        role = 'user';
        break;
      case MessageType.assistant:
        role = 'assistant';
        break;
      case MessageType.system:
        role = 'system';
        break;
      default:
        role = 'user';
    }
    return {'role': role, 'content': content};
  }
}

/// نموذج محادثة (Conversation)
@immutable
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final String? modelUsed;
  final int messageCount;

  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.modelUsed,
    this.messageCount = 0,
  });

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    String? modelUsed,
    int? messageCount,
  }) =>
      Conversation(
        id: id ?? this.id,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastMessage: lastMessage ?? this.lastMessage,
        modelUsed: modelUsed ?? this.modelUsed,
        messageCount: messageCount ?? this.messageCount,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'last_message': lastMessage,
        'model_used': modelUsed,
        'message_count': messageCount,
      };

  factory Conversation.fromMap(Map<String, dynamic> map) => Conversation(
        id: map['id'] as String,
        title: map['title'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        lastMessage: map['last_message'] as String?,
        modelUsed: map['model_used'] as String?,
        messageCount: (map['message_count'] as int?) ?? 0,
      );
}

/// نموذج AI قابل للتحميل/الاستخدام (من Ollama أو LM Studio)
@immutable
class AiModel {
  final String name;
  final String? model;
  final int? size;
  final String? digest;
  final DateTime? modifiedAt;
  final bool isInstalled;
  final String? description;
  final String? parameterSize;
  final String? quantizationLevel;

  const AiModel({
    required this.name,
    this.model,
    this.size,
    this.digest,
    this.modifiedAt,
    this.isInstalled = true,
    this.description,
    this.parameterSize,
    this.quantizationLevel,
  });

  factory AiModel.fromOllamaJson(Map<String, dynamic> json) => AiModel(
        name: json['name'] as String,
        model: json['model'] as String?,
        size: json['size'] as int?,
        digest: json['digest'] as String?,
        modifiedAt: json['modified_at'] != null
            ? DateTime.tryParse(json['modified_at'] as String)
            : null,
        isInstalled: true,
      );

  String get sizeFormatted {
    if (size == null) return '—';
    final gb = size! / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    final mb = size! / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  String get displayName => model ?? name;
}

/// نموذج متاح للتحميل من سجل Ollama
@immutable
class AvailableModel {
  final String name;
  final String description;
  final String sizeHint;
  final bool recommended;
  final String category;

  const AvailableModel({
    required this.name,
    required this.description,
    required this.sizeHint,
    this.recommended = false,
    required this.category,
  });
}

/// قائمة النماذج الموصى بها للتحميل (مجانية ومفتوحة المصدر)
class RecommendedModels {
  static const List<AvailableModel> all = [
    AvailableModel(
      name: 'llama3.2:3b',
      description: 'نموذج خفيف وسريع من Meta — مثالي للأجهزة المحمولة',
      sizeHint: '~2.0 GB',
      recommended: true,
      category: 'General',
    ),
    AvailableModel(
      name: 'qwen2.5:3b',
      description: 'نموذج متعدد اللغات من Alibaba — يدعم العربية جيداً',
      sizeHint: '~2.0 GB',
      recommended: true,
      category: 'Multilingual',
    ),
    AvailableModel(
      name: 'phi3:mini',
      description: 'نموذج مدمج من Microsoft — أداء ممتاز بحجم صغير',
      sizeHint: '~2.3 GB',
      recommended: true,
      category: 'General',
    ),
    AvailableModel(
      name: 'gemma2:2b',
      description: 'نموذج خفيف من Google — سريع ودقيق',
      sizeHint: '~1.6 GB',
      recommended: true,
      category: 'General',
    ),
    AvailableModel(
      name: 'mistral:7b',
      description: 'نموذج أكبر وأقوى من Mistral AI — يتطلب جهازاً قوياً',
      sizeHint: '~4.1 GB',
      recommended: false,
      category: 'General',
    ),
    AvailableModel(
      name: 'qwen2.5:7b',
      description: 'إصدار أكبر من Qwen — أفضل للعربية والمهام المعقدة',
      sizeHint: '~4.7 GB',
      recommended: false,
      category: 'Multilingual',
    ),
    AvailableModel(
      name: 'deepseek-r1:1.5b',
      description: 'نموذج استدلالي خفيف من DeepSeek — للتحليل المنطقي',
      sizeHint: '~1.1 GB',
      recommended: true,
      category: 'Reasoning',
    ),
    AvailableModel(
      name: 'codegemma:2b',
      description: 'متخصص في كتابة وتحليل الأكواد البرمجية',
      sizeHint: '~1.6 GB',
      recommended: false,
      category: 'Code',
    ),
  ];

  static List<String> get categories =>
      all.map((m) => m.category).toSet().toList();
}

/// أداة من أدوات الـ Agent
@immutable
class AgentTool {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final bool enabled;

  const AgentTool({
    required this.name,
    required this.description,
    required this.parameters,
    this.enabled = true,
  });

  AgentTool copyWith({bool? enabled}) =>
      AgentTool(
        name: name,
        description: description,
        parameters: parameters,
        enabled: enabled ?? this.enabled,
      );
}

/// الأدوات المتاحة في وضع Agent
class BuiltinTools {
  static List<AgentTool> get all => [
    const AgentTool(
      name: 'calculator',
      description: 'حاسبة علمية لإجراء العمليات الحسابية المعقدة',
      parameters: {'expression': 'string'},
    ),
    const AgentTool(
      name: 'datetime',
      description: 'الحصول على التاريخ والوقت الحاليين',
      parameters: {},
    ),
    const AgentTool(
      name: 'text_summary',
      description: 'تلخيص نص طويل إلى نقاط أساسية',
      parameters: {'text': 'string', 'max_points': 'int'},
    ),
    const AgentTool(
      name: 'translator',
      description: 'ترجمة نص بين اللغات',
      parameters: {'text': 'string', 'from': 'string', 'to': 'string'},
    ),
  ];
}

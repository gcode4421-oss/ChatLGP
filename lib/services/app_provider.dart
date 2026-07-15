/// مزوّد الحالة المركزي للتطبيق
/// يدير: المحادثة الحالية، الرسائل، حالة الـ AI، الإعدادات

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/agent_service.dart';
import '../services/storage_service.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class AppProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  final Uuid _uuid = const Uuid();
  late final AgentService _agentService = AgentService(_aiService);

  // ───────── الحالة
  List<Conversation> _conversations = [];
  List<ChatMessage> _messages = [];
  Conversation? _currentConversation;
  List<AiModel> _models = [];
  bool _isGenerating = false;
  bool _isConnecting = false;
  ConnectionState _connectionState = ConnectionState.disconnected;
  String _statusMessage = '';
  String _currentThinking = '';
  List<String> _toolEvents = [];
  StreamSubscription? _currentStreamSub;

  // ───────── Getters
  List<Conversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  Conversation? get currentConversation => _currentConversation;
  List<AiModel> get models => _models;
  bool get isGenerating => _isGenerating;
  bool get isConnecting => _isConnecting;
  ConnectionState get connectionState => _connectionState;
  String get statusMessage => _statusMessage;
  String get currentThinking => _currentThinking;
  List<String> get toolEvents => _toolEvents;

  AiService get aiService => _aiService;

  String get currentModel => StorageService.defaultModel;
  bool get agentMode => StorageService.agentMode;
  String get language => StorageService.language;
  double get temperature => StorageService.temperature;
  int? get maxTokens => StorageService.maxTokens;
  String get systemPrompt => StorageService.systemPrompt;

  /// تحميل الإعدادات الأولية
  Future<void> loadSettings() async {
    _aiService.updateConfig(StorageService.ollamaConfig);
    notifyListeners();
  }

  /// تحديث إعدادات Ollama
  Future<void> updateOllamaConfig(OllamaConfig config) async {
    _aiService.updateConfig(config);
    await StorageService.setOllamaConfig(config);
    await testConnection();
  }

  /// اختبار الاتصال بالخادم
  Future<void> testConnection() async {
    _connectionState = ConnectionState.connecting;
    _isConnecting = true;
    _statusMessage = 'جارٍ الاتصال بالخادم...';
    notifyListeners();

    try {
      final ok = await _aiService.ping();
      if (ok) {
        _connectionState = ConnectionState.connected;
        _statusMessage = 'متصل';
        await refreshModels();
      } else {
        _connectionState = ConnectionState.disconnected;
        _statusMessage = 'تعذّر الاتصال — تحقق من تشغيل Ollama';
      }
    } catch (e) {
      _connectionState = ConnectionState.error;
      _statusMessage = 'خطأ: $e';
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// تحديث قائمة النماذج المثبتة
  Future<void> refreshModels() async {
    if (_connectionState != ConnectionState.connected) return;
    try {
      _models = await _aiService.listModels();
      notifyListeners();
    } catch (e) {
      _statusMessage = 'فشل جلب النماذج: $e';
      notifyListeners();
    }
  }

  /// تحميل قائمة المحادثات
  Future<void> loadConversations() async {
    _conversations = await StorageService.listConversations();
    notifyListeners();
  }

  /// فتح محادثة محددة
  Future<void> openConversation(String id) async {
    final conv = await StorageService.getConversation(id);
    if (conv == null) return;
    _currentConversation = conv;
    _messages = await StorageService.getMessages(id);
    notifyListeners();
  }

  /// بدء محادثة جديدة
  Future<void> startNewConversation() async {
    _currentConversation = null;
    _messages = [];
    notifyListeners();
  }

  /// تحميل النماذج
  Future<void> pullModel(String modelName,
      {void Function(int?, int?, String)? onProgress}) async {
    try {
      await _aiService.pullModel(modelName, onProgress: onProgress);
      await refreshModels();
    } catch (e) {
      _statusMessage = 'فشل تحميل النموذج: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// حذف نموذج
  Future<void> deleteModel(String modelName) async {
    try {
      await _aiService.deleteModel(modelName);
      await refreshModels();
    } catch (e) {
      _statusMessage = 'فشل حذف النموذج: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// إرسال رسالة
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;

    // إنشاء محادثة جديدة إن لزم
    if (_currentConversation == null) {
      final title = text.length > 40 ? text.substring(0, 40) : text;
      _currentConversation = await StorageService.createConversation(
        title: title,
        modelUsed: currentModel,
      );
      _conversations.insert(0, _currentConversation!);
    }

    // إضافة رسالة المستخدم
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      conversationId: _currentConversation!.id,
      type: MessageType.user,
      content: text.trim(),
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    await StorageService.addMessage(userMsg);
    notifyListeners();

    // إضافة رسالة مساعد فارغة (placeholder)
    final assistantMsg = ChatMessage(
      id: _uuid.v4(),
      conversationId: _currentConversation!.id,
      type: MessageType.assistant,
      content: '',
      createdAt: DateTime.now(),
      status: MessageStatus.streaming,
      modelName: currentModel,
    );
    _messages.add(assistantMsg);
    notifyListeners();

    _isGenerating = true;
    _currentThinking = '';
    _toolEvents = [];
    notifyListeners();

    try {
      final history = _messages
          .where((m) =>
              m.type.isUser ||
              (m.type.isAssistant && m.content.isNotEmpty) ||
              m.type == MessageType.tool)
          .where((m) => m.id != assistantMsg.id)
          .toList();

      if (agentMode) {
        await _agentService.runAgentLoop(
          model: currentModel,
          messages: history,
          language: language,
          onToken: (token) {
            final idx = _messages.indexWhere((m) => m.id == assistantMsg.id);
            if (idx >= 0) {
              _messages[idx] =
                  _messages[idx].copyWith(content: _messages[idx].content + token);
              notifyListeners();
            }
          },
          onThinking: (thinking) {
            _currentThinking = thinking;
            notifyListeners();
          },
          onToolCall: (name, input) {
            _toolEvents.add('استدعاء أداة: $name ($input)');
            notifyListeners();
          },
          onToolResult: (name, result) {
            _toolEvents.add('نتيجة $name: ${result.length > 100 ? '${result.substring(0, 100)}...' : result}');
            notifyListeners();
          },
          onDone: (resp) async {
            final idx = _messages.indexWhere((m) => m.id == assistantMsg.id);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(
                content: resp.isEmpty ? _messages[idx].content : resp,
                status: MessageStatus.done,
              );
              await StorageService.updateMessage(assistantMsg.id,
                  content: _messages[idx].content, status: MessageStatus.done);
            }
          },
          onError: (e) async {
            final idx = _messages.indexWhere((m) => m.id == assistantMsg.id);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(
                content: 'حدث خطأ: $e',
                status: MessageStatus.error,
              );
              await StorageService.updateMessage(assistantMsg.id,
                  content: 'حدث خطأ: $e', status: MessageStatus.error);
            }
          },
        );
      } else {
        final fullResponse = StringBuffer();
        await _aiService.chatStream(
          model: currentModel,
          messages: history,
          system: systemPrompt.isEmpty
              ? (language == 'ar'
                  ? 'أنت مساعد ذكي ومفيد. أجب بالعربية بوضوح وإيجاز.'
                  : 'You are a helpful AI assistant. Reply clearly and concisely.')
              : systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
          onToken: (token) {
            fullResponse.write(token);
            final idx = _messages.indexWhere((m) => m.id == assistantMsg.id);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(
                  content: _messages[idx].content + token);
              notifyListeners();
            }
          },
          onDone: (resp) async {
            final idx = _messages.indexWhere((m) => m.id == assistantMsg.id);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(
                content: resp,
                status: MessageStatus.done,
              );
              await StorageService.updateMessage(assistantMsg.id,
                  content: resp, status: MessageStatus.done);
            }
          },
          onError: (e) async {
            final idx = _messages.indexWhere((m) => m.id == assistantMsg.id);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(
                content: 'حدث خطأ أثناء التوليد: $e',
                status: MessageStatus.error,
              );
              await StorageService.updateMessage(assistantMsg.id,
                  content: 'حدث خطأ: $e', status: MessageStatus.error);
            }
          },
        );
      }

      // تحديث قائمة المحادثات
      await loadConversations();
    } catch (e) {
      final idx = _messages.indexWhere((m) => m.id == assistantMsg.id);
      if (idx >= 0) {
        _messages[idx] = _messages[idx].copyWith(
          content: 'خطأ: $e',
          status: MessageStatus.error,
        );
      }
    } finally {
      _isGenerating = false;
      _currentThinking = '';
      notifyListeners();
    }
  }

  /// إيقاف التوليد
  void stopGeneration() {
    _currentStreamSub?.cancel();
    _isGenerating = false;
    final idx = _messages
        .lastIndexWhere((m) => m.status == MessageStatus.streaming);
    if (idx >= 0) {
      _messages[idx] = _messages[idx].copyWith(status: MessageStatus.done);
      StorageService.updateMessage(_messages[idx].id, status: MessageStatus.done);
    }
    notifyListeners();
  }

  /// حذف المحادثة الحالية
  Future<void> deleteCurrentConversation() async {
    if (_currentConversation == null) return;
    await StorageService.deleteConversation(_currentConversation!.id);
    _conversations.removeWhere((c) => c.id == _currentConversation!.id);
    _currentConversation = null;
    _messages = [];
    notifyListeners();
  }

  /// تبديل وضع Agent
  void setAgentMode(bool enabled) {
    StorageService.setAgentMode(enabled);
    notifyListeners();
  }

  /// تبديل النموذج الحالي
  void setModel(String model) {
    StorageService.setDefaultModel(model);
    notifyListeners();
  }

  /// تبديل اللغة
  void setLanguage(String lang) {
    StorageService.setLanguage(lang);
    notifyListeners();
  }

  @override
  void dispose() {
    _currentStreamSub?.cancel();
    _aiService.dispose();
    super.dispose();
  }
}

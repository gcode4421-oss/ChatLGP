/// خدمة التخزين المحلي — قاعدة بيانات SQLite للمحادثات والرسائل
/// وإعدادات SharedPreferences للتفضيلات

import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import 'ai_service.dart';

class StorageService {
  static Database? _db;
  static SharedPreferences? _prefs;

  /// تهيئة قاعدة البيانات
  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'localai.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE conversations(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            last_message TEXT,
            model_used TEXT,
            message_count INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            type TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            status TEXT NOT NULL,
            model_name TEXT,
            tool_name TEXT,
            metadata TEXT,
            FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at)',
        );
      },
    );
    _prefs = await SharedPreferences.getInstance();
  }

  static Database get db {
    if (_db == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _db!;
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ─────────────────────────────────────────────────────────
  //  Conversations
  // ─────────────────────────────────────────────────────────

  static Future<Conversation> createConversation({
    required String title,
    String? modelUsed,
  }) async {
    final now = DateTime.now();
    final conv = Conversation(
      id: '${now.millisecondsSinceEpoch}_${now.microsecond}',
      title: title,
      createdAt: now,
      updatedAt: now,
      modelUsed: modelUsed,
    );
    await db.insert('conversations', conv.toMap());
    return conv;
  }

  static Future<List<Conversation>> listConversations({int limit = 100}) async {
    final rows = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(Conversation.fromMap).toList();
  }

  static Future<Conversation?> getConversation(String id) async {
    final rows = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Conversation.fromMap(rows.first);
  }

  static Future<void> updateConversation(Conversation conv) async {
    await db.update(
      'conversations',
      conv.toMap(),
      where: 'id = ?',
      whereArgs: [conv.id],
    );
  }

  static Future<void> deleteConversation(String id) async {
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────
  //  Messages
  // ─────────────────────────────────────────────────────────

  static Future<void> addMessage(ChatMessage msg) async {
    await db.insert('messages', msg.toMap());
    final conv = await getConversation(msg.conversationId);
    if (conv != null) {
      await updateConversation(conv.copyWith(
        lastMessage: msg.content.length > 100
            ? '${msg.content.substring(0, 100)}...'
            : msg.content,
        updatedAt: DateTime.now(),
        messageCount: conv.messageCount + 1,
      ));
    }
  }

  static Future<void> updateMessage(
    String id, {
    String? content,
    MessageStatus? status,
  }) async {
    final updates = <String, dynamic>{};
    if (content != null) updates['content'] = content;
    if (status != null) updates['status'] = status.name;
    if (updates.isEmpty) return;
    await db.update('messages', updates, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  static Future<void> deleteMessage(String id) async {
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────
  //  Settings (SharedPreferences)
  // ─────────────────────────────────────────────────────────

  static const kPrefThemeMode = 'theme_mode';
  static const kPrefOllamaConfig = 'ollama_config';
  static const kPrefDefaultModel = 'default_model';
  static const kPrefAgentMode = 'agent_mode';
  static const kPrefLanguage = 'language';
  static const kPrefTemperature = 'temperature';
  static const kPrefMaxTokens = 'max_tokens';
  static const kPrefSystemPrompt = 'system_prompt';

  static String get themeMode => prefs.getString(kPrefThemeMode) ?? 'system';
  static Future<void> setThemeMode(String v) =>
      prefs.setString(kPrefThemeMode, v);

  static OllamaConfig get ollamaConfig {
    final json = prefs.getString(kPrefOllamaConfig);
    if (json == null) return OllamaConfig.defaultConfig;
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return OllamaConfig.fromJson(decoded);
    } catch (_) {
      return OllamaConfig.defaultConfig;
    }
  }

  static Future<void> setOllamaConfig(OllamaConfig cfg) async {
    await prefs.setString(kPrefOllamaConfig, jsonEncode(cfg.toJson()));
  }

  static String get defaultModel =>
      prefs.getString(kPrefDefaultModel) ?? 'llama3.2:3b';
  static Future<void> setDefaultModel(String v) =>
      prefs.setString(kPrefDefaultModel, v);

  static bool get agentMode => prefs.getBool(kPrefAgentMode) ?? false;
  static Future<void> setAgentMode(bool v) =>
      prefs.setBool(kPrefAgentMode, v);

  static String get language => prefs.getString(kPrefLanguage) ?? 'ar';
  static Future<void> setLanguage(String v) =>
      prefs.setString(kPrefLanguage, v);

  static double get temperature =>
      prefs.getDouble(kPrefTemperature) ?? 0.7;
  static Future<void> setTemperature(double v) =>
      prefs.setDouble(kPrefTemperature, v);

  static int? get maxTokens => prefs.getInt(kPrefMaxTokens);
  static Future<void> setMaxTokens(int? v) =>
      v == null ? prefs.remove(kPrefMaxTokens) : prefs.setInt(kPrefMaxTokens, v);

  static String get systemPrompt => prefs.getString(kPrefSystemPrompt) ?? '';
  static Future<void> setSystemPrompt(String v) =>
      prefs.setString(kPrefSystemPrompt, v);
}

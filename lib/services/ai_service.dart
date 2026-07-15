/// خدمة الاتصال بـ Ollama أو أي خادم OpenAI-compatible
/// تدعم: المحادثة، التدفق (streaming)، سرد النماذج، تحميل النماذج، حذفها

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class OllamaConfig {
  final String host;
  final int port;
  final bool useHttps;

  const OllamaConfig({
    this.host = '127.0.0.1',
    this.port = 11434,
    this.useHttps = false,
  });

  String get baseUrl {
    final scheme = useHttps ? 'https' : 'http';
    return '$scheme://$host:$port';
  }

  Map<String, dynamic> toJson() =>
      {'host': host, 'port': port, 'useHttps': useHttps};

  factory OllamaConfig.fromJson(Map<String, dynamic> json) => OllamaConfig(
        host: json['host'] as String? ?? '127.0.0.1',
        port: json['port'] as int? ?? 11434,
        useHttps: json['useHttps'] as bool? ?? false,
      );

  static const OllamaConfig defaultConfig = OllamaConfig();
}

/// استثناء مخصص لأخطاء Ollama
class OllamaException implements Exception {
  final String message;
  final int? statusCode;
  OllamaException(this.message, {this.statusCode});

  @override
  String toString() => 'OllamaException($statusCode): $message';
}

class AiService {
  OllamaConfig config;
  final http.Client _client;

  AiService({
    OllamaConfig? config,
    http.Client? client,
  })  : config = config ?? OllamaConfig.defaultConfig,
        _client = client ?? http.Client();

  void updateConfig(OllamaConfig newConfig) {
    config = newConfig;
  }

  /// التحقق من اتصال الخادم
  Future<bool> ping() async {
    try {
      final res = await _client
          .get(Uri.parse('${config.baseUrl}/api/tags'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// سرد جميع النماذج المثبتة محلياً
  Future<List<AiModel>> listModels() async {
    final res = await _client.get(Uri.parse('${config.baseUrl}/api/tags'));
    if (res.statusCode != 200) {
      throw OllamaException('فشل في جلب النماذج', statusCode: res.statusCode);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final models = (data['models'] as List? ?? [])
        .map((e) => AiModel.fromOllamaJson(e as Map<String, dynamic>))
        .toList();
    return models;
  }

  /// تحميل نموذج جديد
  /// يقوم ببث تقدم التحميل عبر [onProgress]
  Future<void> pullModel(
    String modelName, {
    void Function(int? completed, int? total, String status)? onProgress,
  }) async {
    final req = http.Request(
      'POST',
      Uri.parse('${config.baseUrl}/api/pull'),
    );
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode({'name': modelName, 'stream': true});

    final res = await _client.send(req);
    if (res.statusCode != 200) {
      throw OllamaException('فشل تحميل النموذج', statusCode: res.statusCode);
    }

    await for (final chunk in res.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (chunk.isEmpty) continue;
      try {
        final data = jsonDecode(chunk) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        final completed = data['completed'] as int?;
        final total = data['total'] as int?;
        onProgress?.call(completed, total, status);
        if (status.contains('success')) return;
      } catch (_) {
        continue;
      }
    }
  }

  /// حذف نموذج
  Future<void> deleteModel(String modelName) async {
    final req = http.Request(
      'DELETE',
      Uri.parse('${config.baseUrl}/api/delete'),
    );
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode({'name': modelName});

    final res = await _client.send(req);
    if (res.statusCode != 200 && res.statusCode != 404) {
      throw OllamaException('فشل حذف النموذج', statusCode: res.statusCode);
    }
  }

  /// توليد رد (غير متدفق)
  Future<String> generate({
    required String model,
    required String prompt,
    String? system,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    final res = await _client.post(
      Uri.parse('${config.baseUrl}/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'prompt': prompt,
        'system': system,
        'stream': false,
        'options': {
          'temperature': temperature,
          if (maxTokens != null) 'num_predict': maxTokens,
        },
      }),
    );
    if (res.statusCode != 200) {
      throw OllamaException(
        'فشل التوليد: ${res.body}',
        statusCode: res.statusCode,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['response'] as String? ?? '';
  }

  /// محادثة متدفقة (Streaming Chat)
  /// يستدعي [onToken] مع كل جزء من الرد
  /// يستدعي [onDone] عند اكتمال الرد
  Future<void> chatStream({
    required String model,
    required List<ChatMessage> messages,
    required void Function(String token) onToken,
    void Function(String fullResponse)? onDone,
    void Function(Error error)? onError,
    String? system,
    double temperature = 0.7,
    int? maxTokens,
    Map<String, dynamic>? options,
  }) async {
    try {
      final req = http.Request(
        'POST',
        Uri.parse('${config.baseUrl}/api/chat'),
      );
      req.headers['Content-Type'] = 'application/json';

      final List<Map<String, dynamic>> msgList = [];
      if (system != null && system.isNotEmpty) {
        msgList.add({'role': 'system', 'content': system});
      }
      msgList.addAll(messages.map((m) => m.toOllamaFormat()));

      req.body = jsonEncode({
        'model': model,
        'messages': msgList,
        'stream': true,
        'options': {
          'temperature': temperature,
          if (maxTokens != null) 'num_predict': maxTokens,
          ...?options,
        },
      });

      final res = await _client.send(req);
      if (res.statusCode != 200) {
        final body = await res.stream.bytesToString();
        throw OllamaException(
          'فشل المحادثة: $body',
          statusCode: res.statusCode,
        );
      }

      final buffer = StringBuffer();
      await for (final chunk in res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;
        try {
          final data = jsonDecode(chunk) as Map<String, dynamic>;
          if (data['done'] == true) {
            onDone?.call(buffer.toString());
            return;
          }
          final msg = data['message'] as Map<String, dynamic>?;
          final token = msg?['content'] as String? ?? '';
          if (token.isNotEmpty) {
            buffer.write(token);
            onToken(token);
          }
        } catch (e) {
          continue;
        }
      }
      onDone?.call(buffer.toString());
    } catch (e) {
      onError?.call(e is Error ? e : Exception(e.toString()) as Error);
    }
  }

  /// يوقف أي عملية جارية (يُطبَّق عبر إلغاء الـ stream من caller)
  void dispose() {
    _client.close();
  }
}

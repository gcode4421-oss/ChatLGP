/// خدمة الـ Agent — تعطي النموذج قدرة على استدعاء أدوات
/// يعمل بآلية ReAct: الفكرة → الأداة → الملاحظة → الإجابة

import 'dart:convert';
import 'ai_service.dart';
import '../models/chat_message.dart';

class AgentService {
  final AiService aiService;

  AgentService(this.aiService);

  /// يولّد Prompt يشرح للنموذج الأدوات المتاحة وكيفية استخدامها
  String _buildAgentSystemPrompt({required String language}) {
    final isArabic = language.startsWith('ar');
    if (isArabic) {
      return '''أنت مساعد ذكي قادر على استخدام الأدوات. لديك الأدوات التالية:

1. calculator: لإجراء العمليات الحسابية. استخدم الصيغة:
   <tool>calculator</tool>
   <input>{"expression": "2 + 2 * 3"}</input>

2. datetime: للحصول على التاريخ والوقت الحاليين. استخدم:
   <tool>datetime</tool>
   <input>{}</input>

3. text_summary: لتلخيص نص طويل. استخدم:
   <tool>text_summary</tool>
   <input>{"text": "النص هنا", "max_points": 3}</input>

4. translator: لترجمة نص. استخدم:
   <tool>translator</tool>
   <input>{"text": "النص", "from": "ar", "to": "en"}</input>

قواعد الاستخدام:
- فكّر أولاً خطوة بخطوة بين وسوم <thinking> و </thinking>
- استدعِ الأداة المناسبة فقط عندما تحتاجها فعلاً
- بعد استلام نتيجة الأداة، اكتب إجابتك النهائية للمستخدم
- أجب دائماً بالعربية إذا كان سؤال المستخدم بالعربية''';
    }
    return '''You are a smart assistant capable of using tools. You have the following tools:

1. calculator: for mathematical calculations. Use:
   <tool>calculator</tool>
   <input>{"expression": "2 + 2 * 3"}</input>

2. datetime: to get current date and time. Use:
   <tool>datetime</tool>
   <input>{}</input>

3. text_summary: to summarize long text. Use:
   <tool>text_summary</tool>
   <input>{"text": "the text", "max_points": 3}</input>

4. translator: to translate text. Use:
   <tool>translator</tool>
   <input>{"text": "text", "from": "en", "to": "ar"}</input>

Rules:
- First think step by step inside <thinking></thinking> tags
- Only call a tool when you actually need it
- After receiving the tool result, write your final answer to the user
- Reply in the same language as the user's question''';
  }

  /// يكتشف استدعاء الأداة في نص الرد
  ToolCall? _parseToolCall(String text) {
    final toolRegex = RegExp(r'<tool>(\w+)</tool>\s*<input>(.*?)</input>', dotAll: true);
    final match = toolRegex.firstMatch(text);
    if (match == null) return null;
    final name = match.group(1)!;
    String inputStr = match.group(2)!.trim();
    Map<String, dynamic> input;
    try {
      input = jsonDecode(inputStr) as Map<String, dynamic>;
    } catch (_) {
      input = {'raw': inputStr};
    }
    return ToolCall(name: name, input: input, raw: match.group(0)!);
  }

  /// ينفّذ استدعاء الأداة محلياً
  Future<String> _executeTool(ToolCall call) async {
    switch (call.name) {
      case 'calculator':
        return _calculator(call.input['expression'] as String? ?? '');

      case 'datetime':
        final now = DateTime.now();
        return 'التاريخ: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}\n'
            'الوقت: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      case 'text_summary':
        final text = call.input['text'] as String? ?? '';
        final maxPoints = (call.input['max_points'] as num?)?.toInt() ?? 3;
        return _textSummary(text, maxPoints);

      case 'translator':
        // ترجمة مبسّطة عبر استدعاء النموذج نفسه
        return 'ملاحظة: الترجمة التلقائية تتطلب نموذجاً متخصصاً. '
            'النص: ${call.input['text']}';

      default:
        return 'أداة غير معروفة: ${call.name}';
    }
  }

  String _calculator(String expr) {
    try {
      final cleaned = expr.replaceAll(RegExp(r'[^0-9+\-*/.()\s]'), '');
      final result = _safeEval(cleaned);
      return 'النتيجة: $result';
    } catch (e) {
      return 'خطأ في الحساب: $e';
    }
  }

  /// مقيّم تعبيرات رياضية بسيط وآمن (دون eval)
  double _safeEval(String expr) {
    final tokens = _tokenize(expr);
    final rpn = _toRpn(tokens);
    return _evalRpn(rpn);
  }

  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    for (final ch in expr.split('')) {
      if (RegExp(r'[0-9.]').hasMatch(ch)) {
        buffer.write(ch);
      } else if (RegExp(r'[+\-*/()]').hasMatch(ch)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(ch);
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }

  List<String> _toRpn(List<String> tokens) {
    final output = <String>[];
    final ops = <String>[];
    final precedence = {'+': 1, '-': 1, '*': 2, '/': 2};
    for (final t in tokens) {
      if (RegExp(r'^[0-9.]+$').hasMatch(t)) {
        output.add(t);
      } else if (t == '(') {
        ops.add(t);
      } else if (t == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          output.add(ops.removeLast());
        }
        if (ops.isNotEmpty) ops.removeLast();
      } else {
        while (ops.isNotEmpty &&
            ops.last != '(' &&
            (precedence[ops.last] ?? 0) >= (precedence[t] ?? 0)) {
          output.add(ops.removeLast());
        }
        ops.add(t);
      }
    }
    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }
    return output;
  }

  double _evalRpn(List<String> rpn) {
    final stack = <double>[];
    for (final t in rpn) {
      if (RegExp(r'^[0-9.]+$').hasMatch(t)) {
        stack.add(double.parse(t));
      } else {
        final b = stack.removeLast();
        final a = stack.removeLast();
        switch (t) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            stack.add(a / b);
            break;
        }
      }
    }
    return stack.last;
  }

  String _textSummary(String text, int maxPoints) {
    // تلخيص مبسّط: استخراج الجمل الأطول والأكثر تكراراً للكلمات
    final sentences = text
        .split(RegExp(r'[.!?؟\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (sentences.isEmpty) return 'لا يوجد محتوى للتلخيص';

    final wordFreq = <String, int>{};
    for (final s in sentences) {
      for (final w in s.toLowerCase().split(RegExp(r'\s+'))) {
        if (w.length > 3) wordFreq[w] = (wordFreq[w] ?? 0) + 1;
      }
    }

    final scored = sentences.map((s) {
      var score = 0.0;
      for (final w in s.toLowerCase().split(RegExp(r'\s+'))) {
        score += (wordFreq[w] ?? 0).toDouble();
      }
      return MapEntry(s, score / s.split(' ').length);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = scored.take(maxPoints).map((e) => '• ${e.key}').join('\n');
    return 'الملخص:\n$top';
  }

  /// ينفّذ دورة Agent كاملة
  /// [onThinking]: يُستدعى عندما يكتب النموذج أفكاره
  /// [onToolCall]: يُستدعى عند استدعاء أداة
  /// [onToken]: يُستدعى مع كل قطعة من الرد النهائي
  /// [onDone]: الرد النهائي الكامل
  Future<void> runAgentLoop({
    required String model,
    required List<ChatMessage> messages,
    required String language,
    required void Function(String token) onToken,
    void Function(String fullResponse)? onDone,
    void Function(String thinking)? onThinking,
    void Function(String toolName, String input)? onToolCall,
    void Function(String toolName, String result)? onToolResult,
    void Function(Error error)? onError,
    int maxIterations = 3,
  }) async {
    final systemPrompt = _buildAgentSystemPrompt(language: language);
    var currentMessages = List<ChatMessage>.from(messages);
    final fullResponse = StringBuffer();

    for (var iter = 0; iter < maxIterations; iter++) {
      final iterBuffer = StringBuffer();
      final thinkingBuffer = StringBuffer();
      bool inThinking = false;

      await aiService.chatStream(
        model: model,
        messages: currentMessages,
        system: systemPrompt,
        temperature: 0.4,
        onToken: (token) {
          iterBuffer.write(token);
          // كشف وسوم التفكير
          if (iterBuffer.toString().contains('<thinking>') &&
              !iterBuffer.toString().contains('</thinking>')) {
            inThinking = true;
            final after = iterBuffer.toString().split('<thinking>').last;
            thinkingBuffer.write(after);
            onThinking?.call(after);
          } else if (iterBuffer.toString().contains('</thinking>')) {
            inThinking = false;
          } else if (!inThinking) {
            fullResponse.write(token);
            onToken(token);
          }
        },
        onDone: (resp) {
          iterBuffer.write(resp);
        },
        onError: (e) {
          onError?.call(e);
        },
      );

      final responseText = iterBuffer.toString();
      final toolCall = _parseToolCall(responseText);

      if (toolCall == null) {
        // لا يوجد استدعاء أداة — انتهى الـ Agent
        onDone?.call(fullResponse.toString());
        return;
      }

      // تنفيذ الأداة
      onToolCall?.call(toolCall.name, jsonEncode(toolCall.input));
      final toolResult = await _executeTool(toolCall);
      onToolResult?.call(toolCall.name, toolResult);

      // إضافة رد المساعد + نتيجة الأداة إلى السياق
      currentMessages = [
        ...currentMessages,
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_asst',
          conversationId: messages.last.conversationId,
          type: MessageType.assistant,
          content: responseText,
          createdAt: DateTime.now(),
        ),
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_tool',
          conversationId: messages.last.conversationId,
          type: MessageType.tool,
          content: toolResult,
          createdAt: DateTime.now(),
          toolName: toolCall.name,
        ),
      ];
    }

    onDone?.call(fullResponse.toString());
  }
}

class ToolCall {
  final String name;
  final Map<String, dynamic> input;
  final String raw;
  ToolCall({required this.name, required this.input, required this.raw});
}

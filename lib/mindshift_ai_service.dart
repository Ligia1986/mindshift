import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mindshift_models.dart';

// ─── Chave de armazenamento da API key ───────────────────────────────────────
const _kApiKey = 'openai_api_key';

// ─── MindShiftAIService ───────────────────────────────────────────────────────
class MindShiftAIService {
  MindShiftAIService._();
  static final instance = MindShiftAIService._();

  // ── Lê a API key do SharedPreferences ──────────────────────────────────────
  Future<String> _apiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kApiKey) ?? '';
  }

  // ── Guarda a API key ────────────────────────────────────────────────────────
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKey, key);
  }

  // ── Verifica se a API key está configurada ──────────────────────────────────
  static Future<bool> hasApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_kApiKey) ?? '';
    return key.isNotEmpty;
  }

  // ─── Chamada base à API OpenAI ────────────────────────────────────────────
  Future<String> _chat({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 1000,
  }) async {
    final apiKey = await _apiKey();
    if (apiKey.isEmpty) {
      throw Exception('API key não configurada. Vai às Definições para adicionar.');
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user',   'content': userPrompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final msg  = body['error']?['message'] ?? 'Erro desconhecido';
      throw Exception('OpenAI erro ${response.statusCode}: $msg');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['choices'] as List).first['message']['content']
        ?.toString()
        .trim() ??
        '';
  }

  // ─── Analisa uma reflexão ABC e devolve AIAnalysis ────────────────────────
  Future<AIAnalysis> analyse({
    required String whatHappened,
    required String automaticThought,
    required List<EmotionEntry> emotions,
    required List<BehaviourResponse> behaviours,
  }) async {
    final emotionsStr = emotions.isEmpty
        ? 'nenhuma'
        : emotions.map((e) => '${e.emotion.label} (${e.intensity}/10)').join(', ');

    final behavioursStr = behaviours.isEmpty
        ? 'nenhum'
        : behaviours.map((b) => b.label).join(', ');

    const systemPrompt = '''
És um psicoterapeuta especialista em Terapia Cognitivo-Comportamental (CBT/ABC).
Analisa a reflexão do utilizador e responde APENAS com JSON válido, sem texto adicional, sem blocos de código.

Estrutura do JSON:
{
  "distortions": ["nome_da_distorcao"],
  "alternative_thought": "pensamento alternativo equilibrado",
  "emotional_validation": "validação empática das emoções",
  "reframing_suggestion": "sugestão concreta de reframe",
  "practice_recommendations": ["recomendação 1", "recomendação 2"]
}

Distorções disponíveis (usa o nome exato em inglês):
catastrophizing, mindReading, overgeneralization, allOrNothing,
emotionalReasoning, shouldStatements, labeling, personalization,
filtering, jumpingToConclusions

Responde em português de Portugal.
''';

    final userPrompt = '''
Situação (A): $whatHappened
Pensamento automático (B): $automaticThought
Emoções (C): $emotionsStr
Comportamentos (C): $behavioursStr

Analisa e devolve o JSON.
''';

    final raw = await _chat(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      maxTokens: 800,
    );

    // Remove possíveis blocos de código markdown
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    try {
      final data = jsonDecode(cleaned) as Map<String, dynamic>;
      return AIAnalysis.fromJson(data);
    } catch (_) {
      // Se o JSON falhar, devolve uma análise mínima
      return AIAnalysis(
        distortions: const [],
        alternativeThought: raw,
        emotionalValidation: 'As tuas emoções são válidas e compreensíveis.',
        reframingSuggestion: 'Tenta observar a situação de uma perspectiva diferente.',
        practiceRecommendations: const ['Respiração diafragmática', 'Registo de pensamentos'],
      );
    }
  }

  // ─── Analisa a evolução ao longo de várias reflexões ─────────────────────
  Future<String> analyseEvolution({
    required String summary,
    required int count,
  }) async {
    const systemPrompt = '''
És um psicoterapeuta especializado em CBT e análise de progresso terapêutico.
Analisa as reflexões do utilizador e escreve um relatório de evolução em português de Portugal.
Sê caloroso, específico e motivador.
Máximo 4 parágrafos curtos, sem títulos, sem marcadores, só texto corrido.
Identifica: padrões cognitivos recorrentes, como o pensamento evoluiu, áreas de melhoria notáveis, e termina com uma mensagem de encorajamento personalizada.
''';

    final userPrompt = '''
O utilizador completou $count reflexões. Aqui está o resumo:

$summary

Escreve a análise de evolução personalizada.
''';

    return _chat(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      maxTokens: 600,
    );
  }
}
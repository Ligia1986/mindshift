import 'dart:convert';

import 'package:http/http.dart' as http;

import 'mindshift_models.dart';

class MindShiftAIService {
  MindShiftAIService._();

  static final MindShiftAIService instance = MindShiftAIService._();

  static String? _apiKey;

  static void init(String key) {
    _apiKey = key;
  }

  static const String _model = 'gpt-4o-mini';
  static const String _url = 'https://api.openai.com/v1/chat/completions';

  Future<AIAnalysis> analyse({
    required String whatHappened,
    required String automaticThought,
    required List<EmotionEntry> emotions,
    required List<BehaviourResponse> behaviours,
  }) async {
    if (_apiKey == null || _apiKey!.trim().isEmpty) {
      return _fallback();
    }

    final emotionText = emotions
        .map((e) => '${e.emotion.label} (${e.intensity}/10)')
        .join(', ');
    final behaviourText = behaviours.map((e) => e.label).join(', ');

    final prompt = '''
Situation: $whatHappened
Automatic thought: "$automaticThought"
Emotions: $emotionText
Behaviours: $behaviourText

Analyse this CBT reflection and return ONLY valid JSON.
''';

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'model': _model,
          'temperature': 0.4,
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'system',
              'content': _systemPrompt,
            },
            <String, String>{
              'role': 'user',
              'content': prompt,
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        return _fallback();
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      String content =
          body['choices'][0]['message']['content']?.toString().trim() ?? '';

      if (content.startsWith('```')) {
        content = content
            .replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '')
            .replaceAll(RegExp(r'\n?```$'), '')
            .trim();
      }

      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return AIAnalysis.fromJson(parsed);
    } catch (_) {
      return _fallback();
    }
  }

  AIAnalysis _fallback() {
    return const AIAnalysis(
      distortions: <CognitiveDistortion>[],
      alternativeThought:
      'My first thought may not show the full picture. I can pause and look at this more calmly.',
      emotionalValidation:
      'It makes sense that this situation affected you. Your feelings are real and understandable.',
      reframingSuggestion:
      'Try asking what evidence supports this thought and what evidence does not. A more balanced view is often less extreme and more helpful.',
      practiceRecommendations: <String>[
        'Thought Record',
        'Evidence Testing',
        'Mindful Observation',
      ],
    );
  }

  static const String _systemPrompt = '''
You are an expert CBT therapist. Return JSON only.

JSON format:
{
  "distortions": ["catastrophizing", "mindReading", "overgeneralization", "allOrNothing", "emotionalReasoning", "shouldStatements", "labeling", "personalization", "filtering", "jumpingToConclusions"],
  "alternative_thought": "string",
  "emotional_validation": "string",
  "reframing_suggestion": "string",
  "practice_recommendations": ["string", "string", "string"]
}

Rules:
- Return only JSON
- Be warm and realistic
- No markdown
- Use only the exact distortion keys listed above
''';
}
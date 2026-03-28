import 'package:flutter/material.dart';

// ===============================
// ENUMS
// ===============================

enum CognitiveDistortion {
  catastrophizing,
  mindReading,
  overgeneralization,
}

extension CognitiveDistortionX on CognitiveDistortion {
  String get label {
    switch (this) {
      case CognitiveDistortion.catastrophizing:
        return 'Catastrophizing';
      case CognitiveDistortion.mindReading:
        return 'Mind Reading';
      case CognitiveDistortion.overgeneralization:
        return 'Overgeneralization';
    }
  }

  String get emoji {
    switch (this) {
      case CognitiveDistortion.catastrophizing:
        return '💥';
      case CognitiveDistortion.mindReading:
        return '🔮';
      case CognitiveDistortion.overgeneralization:
        return '🌐';
    }
  }
}

enum Emotion { anxiety, sadness, anger }

extension EmotionX on Emotion {
  String get label {
    switch (this) {
      case Emotion.anxiety:
        return 'Anxiety';
      case Emotion.sadness:
        return 'Sadness';
      case Emotion.anger:
        return 'Anger';
    }
  }

  String get emoji {
    switch (this) {
      case Emotion.anxiety:
        return '😰';
      case Emotion.sadness:
        return '😢';
      case Emotion.anger:
        return '😠';
    }
  }
}

enum BehaviourResponse { avoided, ruminated, reactedImpulsively }

extension BehaviourResponseX on BehaviourResponse {
  String get label {
    switch (this) {
      case BehaviourResponse.avoided:
        return 'Avoided';
      case BehaviourResponse.ruminated:
        return 'Ruminated';
      case BehaviourResponse.reactedImpulsively:
        return 'Impulsive reaction';
    }
  }
}

// ===============================
// MODELS
// ===============================

class EmotionEntry {
  final Emotion emotion;
  final int intensity;

  EmotionEntry({required this.emotion, required this.intensity});

  Map<String, dynamic> toJson() => {
    'emotion': emotion.name,
    'intensity': intensity,
  };

  factory EmotionEntry.fromJson(Map<String, dynamic> json) {
    return EmotionEntry(
      emotion: Emotion.values.firstWhere(
            (e) => e.name == json['emotion'],
        orElse: () => Emotion.anxiety,
      ),
      intensity: json['intensity'],
    );
  }
}

class AIAnalysis {
  final List<CognitiveDistortion> distortions;
  final String alternativeThought;
  final String emotionalValidation;
  final String reframingSuggestion;
  final List<String> practiceRecommendations;

  AIAnalysis({
    required this.distortions,
    required this.alternativeThought,
    required this.emotionalValidation,
    required this.reframingSuggestion,
    required this.practiceRecommendations,
  });

  Map<String, dynamic> toJson() => {
    'distortions': distortions.map((e) => e.name).toList(),
    'alternativeThought': alternativeThought,
    'emotionalValidation': emotionalValidation,
    'reframingSuggestion': reframingSuggestion,
    'practiceRecommendations': practiceRecommendations,
  };

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      distortions: [],
      alternativeThought: json['alternativeThought'],
      emotionalValidation: json['emotionalValidation'],
      reframingSuggestion: json['reframingSuggestion'],
      practiceRecommendations:
      List<String>.from(json['practiceRecommendations']),
    );
  }
}

class ReflectionEntry {
  final String id;
  final DateTime createdAt;
  final String whatHappened;
  final String automaticThought;
  final List<EmotionEntry> emotions;
  final List<BehaviourResponse> behaviours;
  final AIAnalysis? aiAnalysis;

  ReflectionEntry({
    required this.id,
    required this.createdAt,
    required this.whatHappened,
    required this.automaticThought,
    required this.emotions,
    required this.behaviours,
    this.aiAnalysis,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'whatHappened': whatHappened,
    'automaticThought': automaticThought,
    'emotions': emotions.map((e) => e.toJson()).toList(),
    'behaviours': behaviours.map((e) => e.name).toList(),
    'aiAnalysis': aiAnalysis?.toJson(),
  };

  factory ReflectionEntry.fromJson(Map<String, dynamic> json) {
    return ReflectionEntry(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      whatHappened: json['whatHappened'],
      automaticThought: json['automaticThought'],
      emotions: (json['emotions'] as List)
          .map((e) => EmotionEntry.fromJson(e))
          .toList(),
      behaviours: (json['behaviours'] as List)
          .map((e) => BehaviourResponse.values
          .firstWhere((b) => b.name == e))
          .toList(),
      aiAnalysis: json['aiAnalysis'] != null
          ? AIAnalysis.fromJson(json['aiAnalysis'])
          : null,
    );
  }
}
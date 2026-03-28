import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mindshift_models.dart';

class ReflectionStore extends ChangeNotifier {
  List<ReflectionEntry> _entries = [];
  List<ReflectionEntry> get entries => _entries;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('reflections');

    if (data != null) {
      final List decoded = jsonDecode(data);
      _entries = decoded.map((e) => ReflectionEntry.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> addEntry({
    required String trigger,
    required String thought,
  }) async {
    final analysis = AIAnalysis(
      distortions: [],
      alternativeThought:
      "Although I feel '$thought', I can see this more realistically.",
      emotionalValidation:
      "It makes sense you feel this way after $trigger.",
      reframingSuggestion:
      "What evidence supports this thought?",
      practiceRecommendations: ["Breathe", "Challenge the thought"],
    );

    final entry = ReflectionEntry(
      id: DateTime.now().toString(),
      createdAt: DateTime.now(),
      whatHappened: trigger,
      automaticThought: thought,
      emotions: [],
      behaviours: [],
      aiAnalysis: analysis,
    );

    _entries.insert(0, entry);
    await _save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _entries.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reflections');
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'reflections',
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }
}
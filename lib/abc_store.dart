import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===============================
/// MODEL
/// ===============================

class ABCEntry {
  final String trigger;
  final String thought;
  final String behavior;
  final String aiResponse;

  ABCEntry({
    required this.trigger,
    required this.thought,
    required this.behavior,
    required this.aiResponse,
  });

  Map<String, dynamic> toJson() {
    return {
      'trigger': trigger,
      'thought': thought,
      'behavior': behavior,
      'aiResponse': aiResponse,
    };
  }

  factory ABCEntry.fromJson(Map<String, dynamic> json) {
    return ABCEntry(
      trigger: json['trigger'],
      thought: json['thought'],
      behavior: json['behavior'],
      aiResponse: json['aiResponse'],
    );
  }
}

/// ===============================
/// STORE
/// ===============================

class ABCStore extends ChangeNotifier {
  List<ABCEntry> entries = [];

  /// 🔹 Load from local storage
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('abc_entries');

    if (data != null) {
      final List decoded = jsonDecode(data);
      entries = decoded.map((e) => ABCEntry.fromJson(e)).toList();
      notifyListeners();
    }
  }

  /// 🔹 Save to local storage
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString('abc_entries', encoded);
  }

  /// 🔹 Add new ABC entry
  Future<void> addEntry({
    required String trigger,
    required String thought,
    required String behavior,
  }) async {
    final aiResponse = _fakeAIAnalysis(thought, behavior);

    final entry = ABCEntry(
      trigger: trigger,
      thought: thought,
      behavior: behavior,
      aiResponse: aiResponse,
    );

    entries.insert(0, entry);

    await _save();
    notifyListeners();
  }

  /// 🔹 Clear all entries
  Future<void> clear() async {
    entries.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('abc_entries');
    notifyListeners();
  }

  /// ===============================
  /// 🤖 FAKE AI (podes substituir pela OpenAI depois)
  /// ===============================

  String _fakeAIAnalysis(String thought, String behavior) {
    final lower = thought.toLowerCase();

    if (lower.contains("always") || lower.contains("never")) {
      return "You may be engaging in black-and-white thinking. Try to find exceptions to this belief.";
    }

    if (lower.contains("what if") || lower.contains("worst")) {
      return "This looks like catastrophizing. Try to focus on realistic outcomes instead of worst-case scenarios.";
    }

    if (lower.contains("everyone") || lower.contains("they think")) {
      return "This may be mind-reading. You are assuming what others think without evidence.";
    }

    return "Try to challenge this thought: What evidence supports it? What evidence contradicts it?";
  }
}
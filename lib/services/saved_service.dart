import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedItem {
  final String code;
  final String type;
  final String? label;
  final DateTime savedAt;

  SavedItem({
    required this.code,
    required this.type,
    this.label,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'type': type,
    'label': label,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedItem.fromJson(Map<String, dynamic> json) => SavedItem(
    code: json['code'],
    type: json['type'],
    label: json['label'],
    savedAt: DateTime.parse(json['savedAt']),
  );

  // Create a copy with updated label
  SavedItem copyWith({String? label}) => SavedItem(
    code: code,
    type: type,
    label: label ?? this.label,
    savedAt: savedAt,
  );
}

class SavedService {
  static const _savedKey = 'saved_items';

  // Load all saved items
  static Future<List<SavedItem>> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_savedKey);
    
    if (savedJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(savedJson);
    return decoded.map((item) => SavedItem.fromJson(item)).toList();
  }

  // Add a new item to saved
  static Future<void> addToSaved(String code, String type, {String? label}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await loadSaved();
    
    // Check if already saved
    if (saved.any((item) => item.code == code)) {
      return; // Already saved
    }
    
    // Add new item at the beginning
    saved.insert(0, SavedItem(
      code: code,
      type: type,
      label: label,
      savedAt: DateTime.now(),
    ));

    final encoded = jsonEncode(saved.map((e) => e.toJson()).toList());
    await prefs.setString(_savedKey, encoded);
  }

  // Remove an item from saved
  static Future<void> removeFromSaved(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await loadSaved();
    
    saved.removeWhere((item) => item.code == code);

    final encoded = jsonEncode(saved.map((e) => e.toJson()).toList());
    await prefs.setString(_savedKey, encoded);
  }

  // Check if item is saved
  static Future<bool> isSaved(String code) async {
    final saved = await loadSaved();
    return saved.any((item) => item.code == code);
  }

  // Update label for a saved item
  static Future<void> updateLabel(String code, String label) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await loadSaved();
    
    final index = saved.indexWhere((item) => item.code == code);
    if (index != -1) {
      saved[index] = saved[index].copyWith(label: label);
      final encoded = jsonEncode(saved.map((e) => e.toJson()).toList());
      await prefs.setString(_savedKey, encoded);
    }
  }

  // Clear all saved items
  static Future<void> clearSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedKey);
  }

  // Get saved count
  static Future<int> getSavedCount() async {
    final saved = await loadSaved();
    return saved.length;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ScanHistoryItem {
  final String code;
  final String type;
  final DateTime scannedAt;

  ScanHistoryItem({
    required this.code,
    required this.type,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'type': type,
    'scannedAt': scannedAt.toIso8601String(),
  };

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) => ScanHistoryItem(
    code: json['code'],
    type: json['type'],
    scannedAt: DateTime.parse(json['scannedAt']),
  );
}

class HistoryService {
  static const _historyKey = 'scan_history';

  // Load all history items
  static Future<List<ScanHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    
    if (historyJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(historyJson);
    return decoded.map((item) => ScanHistoryItem.fromJson(item)).toList();
  }

  // Add a new scan to history
  static Future<void> addToHistory(String code, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();
    
    // Add new item at the beginning
    history.insert(0, ScanHistoryItem(
      code: code,
      type: type,
      scannedAt: DateTime.now(),
    ));

    // Keep only last 100 items
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }

    final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }

  // Clear all history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // Export history to CSV
  static Future<void> exportToCsv() async {
    final history = await loadHistory();
    
    if (history.isEmpty) {
      throw Exception('No history to export');
    }

    // Create CSV content
    final StringBuffer csv = StringBuffer();
    csv.writeln('Code,Type,Scanned At');
    
    for (final item in history) {
      // Escape quotes in code
      final escapedCode = item.code.replaceAll('"', '""');
      csv.writeln('"$escapedCode","${item.type}","${item.scannedAt.toIso8601String()}"');
    }

    // Get temporary directory
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/scan_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv.toString());

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'QR Scanner History',
    );
  }

  // Get history count
  static Future<int> getHistoryCount() async {
    final history = await loadHistory();
    return history.length;
  }
}

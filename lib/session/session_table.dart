import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kTableId    = 'session_table_id';
const String _kTableCode  = 'session_table_code';
const String _kVisitToken = 'session_visit_token';

/// Table label for the current visit (e.g. `T4`, `12`). Set from QR / deep link.
final ValueNotifier<String?> sessionTableCode = ValueNotifier<String?>(null);

/// Numeric table id when known separately from [sessionTableCode].
final ValueNotifier<int?> sessionTableId = ValueNotifier<int?>(null);

/// Visit/session token from QR (`token=` query param).
final ValueNotifier<String?> sessionVisitToken = ValueNotifier<String?>(null);

Listenable get sessionTableListenables =>
    Listenable.merge(<Listenable>[
      sessionTableCode,
      sessionTableId,
      sessionVisitToken,
    ]);

/// Call once at app startup in main() — restores any previously scanned table
/// so it survives login/signup navigation.
Future<void> restoreSessionTable() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  sessionTableId.value    = prefs.getInt(_kTableId);
  sessionTableCode.value  = prefs.getString(_kTableCode);
  sessionVisitToken.value = prefs.getString(_kVisitToken);
}

void setSessionTableCode(String? code) {
  final String? t = code?.trim();
  sessionTableCode.value = (t == null || t.isEmpty) ? null : t;
  _persist();
}

void setSessionTableId(int? id) {
  sessionTableId.value = id;
  _persist();
}

void setSessionVisitToken(String? token) {
  final String? t = token?.trim();
  sessionVisitToken.value = (t == null || t.isEmpty) ? null : t;
  _persist();
}

/// Call this when the dining session truly ends (e.g. after checkout confirmation).
Future<void> clearSessionTable() async {
  sessionTableId.value    = null;
  sessionTableCode.value  = null;
  sessionVisitToken.value = null;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kTableId);
  await prefs.remove(_kTableCode);
  await prefs.remove(_kVisitToken);
}

Future<void> _persist() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (sessionTableId.value != null) {
    await prefs.setInt(_kTableId, sessionTableId.value!);
  } else {
    await prefs.remove(_kTableId);
  }
  if (sessionTableCode.value != null) {
    await prefs.setString(_kTableCode, sessionTableCode.value!);
  } else {
    await prefs.remove(_kTableCode);
  }
  if (sessionVisitToken.value != null) {
    await prefs.setString(_kVisitToken, sessionVisitToken.value!);
  } else {
    await prefs.remove(_kVisitToken);
  }
}

/// Backend `table` field for `POST /orders/`. Uses [sessionTableId], then digits in
/// [sessionTableCode], then `1` if nothing parses.
int resolveTableIdForOrder() {
  final int? direct = sessionTableId.value;
  if (direct != null && direct > 0) return direct;
  final String? code = sessionTableCode.value?.trim();
  if (code != null && code.isNotEmpty) {
    final String digits = code.replaceAll(RegExp(r'[^\d]'), '');
    final int? parsed = int.tryParse(digits);
    if (parsed != null && parsed > 0) return parsed;
  }
  return 1;
}

/// Short label for UI (chip on checkout, etc.).
String tableDisplayLabelForUi() {
  final String? code = sessionTableCode.value?.trim();
  if (code != null && code.isNotEmpty) return code;
  final int? id = sessionTableId.value;
  if (id != null && id > 0) return 'T$id';
  return 'T${resolveTableIdForOrder()}';
}


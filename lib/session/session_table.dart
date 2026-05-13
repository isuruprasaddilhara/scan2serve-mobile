import 'package:flutter/foundation.dart';

/// Table label for the current visit (e.g. `T4`, `12`). Set from QR / deep link later.
final ValueNotifier<String?> sessionTableCode = ValueNotifier<String?>(null);

/// Optional numeric table id when known separately from [sessionTableCode].
final ValueNotifier<int?> sessionTableId = ValueNotifier<int?>(null);

Listenable get sessionTableListenables =>
    Listenable.merge(<Listenable>[sessionTableCode, sessionTableId]);

void setSessionTableCode(String? code) {
  final String? t = code?.trim();
  sessionTableCode.value = (t == null || t.isEmpty) ? null : t;
}

void setSessionTableId(int? id) {
  sessionTableId.value = id;
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


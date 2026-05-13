import 'package:flutter/services.dart';

/// Local mobile number: exactly 10 digits (no spaces or symbols).
const int kLocalPhoneDigits = 10;

final List<TextInputFormatter> localPhoneInputFormatters =
    <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(kLocalPhoneDigits),
];

bool isValidLocalPhoneNumber(String raw) {
  final String s = raw.trim();
  return s.length == kLocalPhoneDigits &&
      RegExp(r'^\d{10}$').hasMatch(s);
}

String digitsOnlyPhone(String raw) =>
    raw.replaceAll(RegExp(r'\D'), '');

/// For prefilling from APIs that may include country code or punctuation.
String normalizePhoneForTenDigitField(String raw) {
  final String d = digitsOnlyPhone(raw);
  if (d.length > kLocalPhoneDigits) {
    return d.substring(d.length - kLocalPhoneDigits);
  }
  return d;
}

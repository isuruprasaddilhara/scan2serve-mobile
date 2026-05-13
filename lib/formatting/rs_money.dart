/// Parse digits from labels like `Rs 1,200` or `Rs 1200`.
int parseRsAmount(String priceLabel) {
  final String digits = priceLabel.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

/// Display as `Rs 6,128` (thousands separators from the right).
String formatRsDisplay(int amount) {
  if (amount <= 0) return 'Rs 0';
  final String s = amount.toString();
  final List<String> parts = <String>[];
  for (int i = s.length; i > 0; i -= 3) {
    final int start = i - 3 < 0 ? 0 : i - 3;
    parts.add(s.substring(start, i));
  }
  return 'Rs ${parts.reversed.join(',')}';
}

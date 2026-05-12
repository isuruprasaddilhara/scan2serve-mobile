import 'package:scan2serve/api/api_config.dart';

/// Turn a relative or absolute media path from the API into a full URL.
String? absoluteMediaUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final t = url.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  final base = kApiBaseUrl.replaceAll(RegExp(r'/$'), '');
  if (t.startsWith('/')) return '$base$t';
  return '$base/$t';
}

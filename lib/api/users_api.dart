import 'dart:convert';

import 'package:scan2serve/api/api_client.dart';
import 'package:scan2serve/api/auth_token_store.dart';

/// POST /users/auth/login/ — stores access (and refresh when present) via
/// [setAccessToken] / [setRefreshToken]. Tokens may be under `user` or top-level.
Future<void> loginWithEmailPassword({
  required String email,
  required String password,
}) async {
  final res = await apiPost(
    '/users/auth/login/',
    body: {
      'email': email,
      'password': password,
    },
  );
  if (res.statusCode != 200) {
    throw UsersApiException(res.statusCode, res.body);
  }
  final decoded = jsonDecode(res.body) as Map<String, dynamic>;
  final user = decoded['user'] as Map<String, dynamic>?;
  String? access = user?['access'] as String?;
  String? refresh = user?['refresh'] as String?;
  access ??= decoded['access'] as String?;
  refresh ??= decoded['refresh'] as String?;
  if (access == null || access.isEmpty) {
    throw UsersApiException(res.statusCode, 'No access token in response');
  }
  setAccessToken(access);
  setRefreshToken(refresh);
}

/// POST /users/auth/forgot-password/
///
/// Returns the server [detail] message (e.g. reset link sent). Does not throw on
/// success status codes other than 200 if body is still usable — callers treat non-200 as errors.
Future<String> requestPasswordReset({required String email}) async {
  final res = await apiPost(
    '/users/auth/forgot-password/',
    body: <String, dynamic>{'email': email.trim()},
  );
  if (res.statusCode != 200) {
    throw UsersApiException(res.statusCode, res.body);
  }
  try {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    }
  } catch (_) {}
  return 'If that email exists, a reset link has been sent.';
}

/// Parses DRF / validation body for forgot-password errors.
String? parseForgotPasswordErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final detail = decoded['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is String) return first;
    }
    final email = decoded['email'];
    if (email is List && email.isNotEmpty && email.first is String) {
      return email.first as String;
    }
    final nonField = decoded['non_field_errors'];
    if (nonField is List && nonField.isNotEmpty && nonField.first is String) {
      return nonField.first as String;
    }
  } catch (_) {}
  return null;
}

/// POST /users/auth/password/change/ — requires Bearer access token.
///
/// Returns a short success message from [detail] when the server sends one.
Future<String> changePassword({
  required String oldPassword,
  required String newPassword,
}) async {
  final res = await apiPost(
    '/users/auth/password/change/',
    body: <String, dynamic>{
      'old_password': oldPassword,
      'new_password': newPassword,
    },
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw UsersApiException(res.statusCode, res.body);
  }
  final String body = res.body.trim();
  if (body.isEmpty) {
    return 'Password updated.';
  }
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    }
  } catch (_) {}
  return 'Password updated.';
}

/// Parses validation / DRF errors for password change.
String? parseChangePasswordErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final detail = decoded['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is String) return first;
    }
    final buf = StringBuffer();
    for (final String key in <String>[
      'old_password',
      'new_password',
      'new_password1',
      'new_password2',
      'password',
      'non_field_errors',
    ]) {
      final dynamic v = decoded[key];
      if (v is List && v.isNotEmpty) {
        for (final dynamic e in v) {
          if (e is String && e.trim().isNotEmpty) {
            if (buf.isNotEmpty) buf.write(' ');
            buf.write(e.trim());
          }
        }
      } else if (v is String && v.trim().isNotEmpty) {
        if (buf.isNotEmpty) buf.write(' ');
        buf.write(v.trim());
      }
    }
    if (buf.isNotEmpty) return buf.toString();
  } catch (_) {}
  return null;
}

/// POST /users/auth/register/customer/
Future<void> registerCustomer({
  required String email,
  required String name,
  required String password,
  required String phoneNo,
}) async {
  final res = await apiPost(
    '/users/auth/register/customer/',
    body: {
      'email': email,
      'name': name,
      'password': password,
      'phone_no': phoneNo,
    },
  );
  if (res.statusCode != 201) {
    throw UsersApiException(res.statusCode, res.body);
  }
}

/// Parses DRF-style body from [UsersApiException] for sign-up errors.
String? parseRegisterErrorBody(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final errors = decoded['errors'];
    if (errors is Map<String, dynamic>) {
      final List<String> lines = [];
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String) {
            lines.add(first);
          }
        } else if (value is String) {
          lines.add(value);
        }
      }
      if (lines.isNotEmpty) {
        return lines.join(' ');
      }
    }
    final detail = decoded['detail'];
    if (detail is String) return detail;
    final msg = decoded['message'] as String?;
    if (msg != null &&
        msg != 'User registration failed' &&
        msg.isNotEmpty) {
      return msg;
    }
  } catch (_) {}
  return null;
}

/// GET /users/customer/me/
Future<Map<String, dynamic>> fetchCustomerMe() async {
  final res = await apiGet('/users/customer/me/');
  if (res.statusCode != 200) {
    throw UsersApiException(res.statusCode, res.body);
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// Best-effort display name from [fetchCustomerMe] / PATCH response JSON.
String customerMeDisplayName(Map<String, dynamic> me) {
  String n = (me['name'] as String?)?.trim() ?? '';
  if (n.isEmpty) {
    n = (me['first_name'] as String?)?.trim() ?? '';
  }
  if (n.isEmpty) {
    final String email = (me['email'] as String?)?.trim() ?? '';
    if (email.contains('@')) {
      n = email.split('@').first;
    }
  }
  return n;
}

/// Phone value from customer `me` JSON (backend key may vary).
String customerMePhone(Map<String, dynamic> me) {
  for (final String key in <String>[
    'phone_no',
    'phone',
    'phone_number',
    'mobile',
  ]) {
    final dynamic v = me[key];
    if (v is String) {
      final String t = v.trim();
      if (t.isNotEmpty) return t;
    } else if (v != null) {
      final String t = '$v'.trim();
      if (t.isNotEmpty) return t;
    }
  }
  return '';
}

/// PATCH /users/customer/edit/ — update profile (Bearer required).
/// Body: `name`, `email`, `phone_no` (same as register / Postman "Edit Customer").
Future<Map<String, dynamic>> patchCustomerMe(Map<String, dynamic> fields) async {
  final res = await apiPatch(
    '/users/customer/edit/',
    body: fields,
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw UsersApiException(res.statusCode, res.body);
  }
  final String b = res.body.trim();
  if (b.isEmpty) {
    return fetchCustomerMe();
  }
  return jsonDecode(b) as Map<String, dynamic>;
}

String? parseCustomerMePatchErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final detail = decoded['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }
    if (detail is List && detail.isNotEmpty && detail.first is String) {
      return detail.first as String;
    }
    final buf = StringBuffer();
    for (final MapEntry<String, dynamic> e in decoded.entries) {
      if (e.key == 'detail') continue;
      final dynamic v = e.value;
      if (v is List) {
        for (final dynamic item in v) {
          if (item is String && item.trim().isNotEmpty) {
            if (buf.isNotEmpty) buf.write(' ');
            buf.write(item.trim());
          }
        }
      } else if (v is String && v.trim().isNotEmpty) {
        if (buf.isNotEmpty) buf.write(' ');
        buf.write(v.trim());
      }
    }
    if (buf.isNotEmpty) return buf.toString();
  } catch (_) {}
  return null;
}

class UsersApiException implements Exception {
  UsersApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'UsersApiException($statusCode): $body';
}

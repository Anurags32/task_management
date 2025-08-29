import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/odoo_config.dart';

/// Minimal Odoo web session client using /web/session endpoints.
/// - Handles login, current session check, and logout
/// - Keeps session via cookies stored in [cookieJar]
class OdooClient {
  OdooClient._();
  static final OdooClient instance = OdooClient._();

  final Map<String, String> _cookieJar = <String, String>{};

  Uri _uri(String path) => Uri.parse('${OdooConfig.baseUrl}$path');

  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    if (_cookieJar.isNotEmpty)
      'Cookie': _cookieJar.entries.map((e) => '${e.key}=${e.value}').join('; '),
  };

  void _storeCookies(http.Response res) {
    final rawSetCookies = res.headers['set-cookie'];
    if (rawSetCookies == null) return;
    // Can be multiple set-cookie separated by comma, split safely
    for (final cookiePart in rawSetCookies.split(',')) {
      final segments = cookiePart.split(';').first.trim().split('=');
      if (segments.length >= 2) {
        final k = segments[0].trim();
        final v = segments.sublist(1).join('=').trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          _cookieJar[k] = v;
        }
      }
    }
  }

  Future<bool> login({required String login, required String password}) async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'db': OdooConfig.database,
        'login': login,
        'password': password,
      },
    });

    final res = await http.post(
      _uri('/web/session/authenticate'),
      headers: _baseHeaders,
      body: body,
    );
    _storeCookies(res);

    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final result = data['result'];
    return result != null && result['uid'] != null;
  }

  Future<Map<String, dynamic>?> sessionInfo() async {
    final body = jsonEncode({'jsonrpc': '2.0', 'method': 'call', 'params': {}});
    final res = await http.post(
      _uri('/web/session/get_session_info'),
      headers: _baseHeaders,
      body: body,
    );
    _storeCookies(res);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['result'] as Map<String, dynamic>?);
  }

  Future<void> logout() async {
    final body = jsonEncode({'jsonrpc': '2.0', 'method': 'call', 'params': {}});
    final res = await http.post(
      _uri('/web/session/destroy'),
      headers: _baseHeaders,
      body: body,
    );
    _storeCookies(res);
  }

  /// Example: read tasks from project.task using /web/dataset/call_kw
  Future<List<dynamic>> searchRead({
    required String model,
    List<dynamic>? domain,
    List<String>? fields,
    int limit = 40,
  }) async {
    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': model,
        'method': 'search_read',
        'args': [domain ?? []],
        'kwargs': {'fields': fields ?? [], 'limit': limit},
      },
    };
    final res = await http.post(
      _uri('/web/dataset/call_kw'),
      headers: _baseHeaders,
      body: jsonEncode(payload),
    );
    _storeCookies(res);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['result'] == null) return [];
    return List<dynamic>.from(data['result'] as List);
  }

  /// Example: create project.task
  Future<int?> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': model,
        'method': 'create',
        'args': [values],
        'kwargs': {},
      },
    };
    final res = await http.post(
      _uri('/web/dataset/call_kw'),
      headers: _baseHeaders,
      body: jsonEncode(payload),
    );
    _storeCookies(res);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['result'] as int?;
  }
}

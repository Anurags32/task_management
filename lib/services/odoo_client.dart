import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/odoo_config.dart';

/// Odoo web session client with improved error handling and user management
class OdooClient {
  OdooClient._();
  static final OdooClient instance = OdooClient._();

  final Map<String, String> _cookieJar = <String, String>{};
  Map<String, dynamic>? _currentUser;

  Uri _uri(String path) => Uri.parse('${OdooConfig.baseUrl}$path');

  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_cookieJar.isNotEmpty)
      'Cookie': _cookieJar.entries.map((e) => '${e.key}=${e.value}').join('; '),
  };

  void _storeCookies(http.Response res) {
    final rawSetCookies = res.headers['set-cookie'];
    if (rawSetCookies == null) return;

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

  /// Login with better error handling
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'db': OdooConfig.database,
          'login': login,
          'password': password,
        },
      });

      final res = await http
          .post(
            _uri(OdooConfig.authenticateEndpoint),
            headers: _baseHeaders,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      _storeCookies(res);

      if (res.statusCode != 200) {
        return {
          'success': false,
          'error': 'HTTP Error: ${res.statusCode}',
          'details': res.body,
        };
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['error'] != null) {
        final error = data['error'] as Map<String, dynamic>;
        return {
          'success': false,
          'error':
              error['data']?['message'] ??
              error['message'] ??
              'Authentication failed',
          'details': error,
        };
      }

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null || result['uid'] == null) {
        return {
          'success': false,
          'error': 'Invalid response from server',
          'details': data,
        };
      }

      // Store user info
      _currentUser = {
        'uid': result['uid'],
        'user_context': result['user_context'],
        'db': result['db'],
        'login': login,
      };

      return {'success': true, 'user': _currentUser, 'uid': result['uid']};
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'details': e.toString(),
      };
    }
  }

  /// Get current user info
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Check if user is admin
  bool get isAdmin {
    if (_currentUser == null) return false;
    final login = _currentUser!['login']?.toString().toLowerCase();
    return login == 'admin';
  }

  /// Get current session info
  Future<Map<String, dynamic>> sessionInfo() async {
    try {
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {},
      });
      final res = await http
          .post(
            _uri(OdooConfig.sessionInfoEndpoint),
            headers: _baseHeaders,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      _storeCookies(res);
      if (res.statusCode != 200) {
        return {'success': false, 'error': 'HTTP Error: ${res.statusCode}'};
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['error'] != null) {
        return {'success': false, 'error': 'Session error'};
      }

      return {'success': true, 'data': data['result']};
    } catch (e) {
      return {'success': false, 'error': 'Session error: ${e.toString()}'};
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    try {
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {},
      });
      await http
          .post(
            _uri(OdooConfig.logoutEndpoint),
            headers: _baseHeaders,
            body: body,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // Ignore logout errors
    } finally {
      _cookieJar.clear();
      _currentUser = null;
    }
  }

  /// Ensure we have a valid session
  Future<bool> _ensureSession() async {
    if (_currentUser != null) {
      // Check if session is still valid
      try {
        final sessionResult = await sessionInfo();
        return sessionResult['success'] == true;
      } catch (e) {
        // Session expired, need to re-authenticate
        _currentUser = null;
        _cookieJar.clear();
      }
    }
    return false;
  }

  /// Search and read records
  Future<Map<String, dynamic>> searchRead({
    required String model,
    required List<String> fields,
    List<List<dynamic>>? domain,
    int? limit,
  }) async {
    try {
      // Ensure we have a valid session
      final hasSession = await _ensureSession();
      if (!hasSession) {
        return {
          'success': false,
          'error': 'No valid session. Please login first.',
        };
      }

      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': model,
          'method': 'search_read',
          'args': [domain ?? [], fields],
          'kwargs': {'limit': limit ?? 100},
        },
      };

      final res = await http
          .post(
            _uri(OdooConfig.callKwEndpoint),
            headers: _baseHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      _storeCookies(res);

      if (res.statusCode != 200) {
        return {'success': false, 'error': 'HTTP Error: ${res.statusCode}'};
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['error'] != null) {
        final error = data['error'] as Map<String, dynamic>;
        return {
          'success': false,
          'error':
              error['data']?['message'] ??
              error['message'] ??
              'Failed to search records',
        };
      }

      return {'success': true, 'data': data['result']};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Create record with better error handling
  Future<Map<String, dynamic>> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    try {
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

      final res = await http
          .post(
            _uri(OdooConfig.callKwEndpoint),
            headers: _baseHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      _storeCookies(res);

      if (res.statusCode != 200) {
        return {
          'success': false,
          'error': 'HTTP Error: ${res.statusCode}',
          'id': null,
        };
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['error'] != null) {
        final error = data['error'] as Map<String, dynamic>;
        return {
          'success': false,
          'error':
              error['data']?['message'] ??
              error['message'] ??
              'Failed to create record',
          'id': null,
        };
      }

      final result = data['result'] as int?;
      return {
        'success': true,
        'id': result,
        'message': 'Record created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'id': null,
      };
    }
  }

  /// Check if a model exists and is accessible
  Future<bool> modelExists(String modelName) async {
    try {
      print('OdooClient: Checking if model $modelName exists...');

      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'ir.model',
          'method': 'search_count',
          'args': [
            [
              ['model', '=', modelName],
            ],
          ],
          'kwargs': {},
        },
      };

      final res = await http
          .post(
            _uri(OdooConfig.callKwEndpoint),
            headers: _baseHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      _storeCookies(res);

      if (res.statusCode != 200) {
        print('OdooClient: HTTP error checking model: ${res.statusCode}');
        return false;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      print('OdooClient: Model check response: $data');

      if (data['error'] != null) {
        print('OdooClient: Error checking model: ${data['error']}');
        return false;
      }

      final count = data['result'] as int?;
      final exists = count != null && count > 0;
      print('OdooClient: Model $modelName exists: $exists (count: $count)');
      return exists;
    } catch (e) {
      print('OdooClient: Exception checking model: $e');
      return false;
    }
  }

  /// Update record
  Future<Map<String, dynamic>> update({
    required String model,
    required int recordId,
    required Map<String, dynamic> values,
  }) async {
    try {
      print('OdooClient: Updating $model with ID $recordId, values: $values');

      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': model,
          'method': 'write',
          'args': [
            [recordId],
            values,
          ],
          'kwargs': {},
        },
      };

      final res = await http
          .post(
            _uri(OdooConfig.callKwEndpoint),
            headers: _baseHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      _storeCookies(res);

      print('OdooClient: HTTP response status: ${res.statusCode}');
      print('OdooClient: Response body: ${res.body}');

      if (res.statusCode != 200) {
        return {'success': false, 'error': 'HTTP Error: ${res.statusCode}'};
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['error'] != null) {
        final error = data['error'] as Map<String, dynamic>;
        final errorMessage =
            error['data']?['message'] ??
            error['message'] ??
            'Failed to update record';
        print('OdooClient: Server error: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }

      print('OdooClient: Update successful');
      return {'success': true, 'message': 'Record updated successfully'};
    } catch (e) {
      print('OdooClient: Exception during update: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Delete record
  Future<Map<String, dynamic>> delete({
    required String model,
    required int recordId,
  }) async {
    try {
      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': model,
          'method': 'unlink',
          'args': [
            [recordId],
          ],
          'kwargs': {},
        },
      };

      final res = await http
          .post(
            _uri(OdooConfig.callKwEndpoint),
            headers: _baseHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      _storeCookies(res);

      if (res.statusCode != 200) {
        return {'success': false, 'error': 'HTTP Error: ${res.statusCode}'};
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['error'] != null) {
        final error = data['error'] as Map<String, dynamic>;
        return {
          'success': false,
          'error':
              error['data']?['message'] ??
              error['message'] ??
              'Failed to delete record',
        };
      }

      return {'success': true, 'message': 'Record deleted successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}

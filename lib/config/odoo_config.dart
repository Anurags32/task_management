/// Odoo API configuration
class OdooConfig {
  /// Base URL of your Odoo instance (no trailing slash)
  static const String baseUrl = 'https://olm-task-management.odoo.com';

  /// Database name of your Odoo instance
  /// This is the actual database name from the Odoo instance
  static const String database = 'olm-task-management-main-23252707';

  /// API endpoints
  static const String authenticateEndpoint = '/web/session/authenticate';
  static const String sessionInfoEndpoint = '/web/session/get_session_info';
  static const String logoutEndpoint = '/web/session/destroy';
  static const String callKwEndpoint = '/web/dataset/call_kw';
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SessionExpiredException implements Exception {
  @override
  String toString() => 'Sesión expirada';
}

class ApiService {
  // ⚠️ IMPORTANTE: Si usas un dispositivo físico, cambia 127.0.0.1 por la IP local de tu PC (ej. 192.168.1.100)
  // Si usas el emulador de Android, usa 10.0.2.2
    static const String baseUrl = "https://humberto.alwaysdata.net/api";
  static const String localCameraStream = 'local://device-camera';

  static bool isLocalCamera(String? streamUrl) =>
      (streamUrl ?? '').startsWith('local://');

  /// Se registra desde main.dart para cerrar sesión y volver al login.
  static Future<void> Function()? onUnauthorized;

  static bool _redirectingToLogin = false;
  static DateTime? _lastValidatedAt;

  // ── Token ─────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Never> _expireSession() async {
    _lastValidatedAt = null;
    if (!_redirectingToLogin) {
      _redirectingToLogin = true;
      try {
        await onUnauthorized?.call();
      } finally {
        Future<void>.delayed(const Duration(seconds: 2), () {
          _redirectingToLogin = false;
        });
      }
    }
    throw SessionExpiredException();
  }

  static Future<http.Response> _authed(
    String method,
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      await _expireSession();
    }

    final uri = Uri.parse('$baseUrl$path');
    final headers = _authHeaders(token);
    final encodedBody = body == null ? null : jsonEncode(body);

    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers).timeout(timeout);
        break;
      case 'POST':
        response = await http
            .post(uri, headers: headers, body: encodedBody)
            .timeout(timeout);
        break;
      case 'PUT':
        response = await http
            .put(uri, headers: headers, body: encodedBody)
            .timeout(timeout);
        break;
      case 'PATCH':
        response = await http
            .patch(uri, headers: headers, body: encodedBody)
            .timeout(timeout);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers).timeout(timeout);
        break;
      default:
        throw Exception('Método HTTP no soportado');
    }

    if (response.statusCode == 401) {
      await _expireSession();
    }
    return response;
  }

  /// Comprueba el token contra el servidor. Un fallo de red no cierra la sesión.
  static Future<bool> validateSession({bool force = false}) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    if (!force &&
        _lastValidatedAt != null &&
        DateTime.now().difference(_lastValidatedAt!) <
            const Duration(minutes: 5)) {
      return true;
    }

    try {
      final response = await _authed('GET', '/user');
      if (response.statusCode == 200) {
        _lastValidatedAt = DateTime.now();
        return true;
      }
      return false;
    } on SessionExpiredException {
      return false;
    } catch (_) {
      return true;
    }
  }

  // ── Manejo de errores centralizado ────────────────────────────
  static Exception _handleError(http.Response response, String defaultMsg) {
    try {
      final body = jsonDecode(response.body);
      final msg = body['message'] ?? body['error'] ?? defaultMsg;
      return Exception(msg);
    } catch (_) {
      return Exception(defaultMsg);
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await _authed('GET', '/dashboard');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al cargar dashboard');
  }

  // ── Alertas ───────────────────────────────────────────────────
  static Future<List<dynamic>> getAlerts() async {
    final response = await _authed('GET', '/alerts');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al cargar alertas');
  }

  static Future<Map<String, dynamic>> sendAlert({
    required String type,
    required String priority,
    String? location,
    String? description,
    int? deviceId,
    String? status,
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{
      'type':        type,
      'priority':    priority,
      'location':    location ?? '',
      'description': description ?? '',
    };
    if (deviceId != null)  payload['device_id'] = deviceId;
    if (status != null)    payload['status']    = status;
    if (latitude != null)  payload['latitude']  = latitude;
    if (longitude != null) payload['longitude'] = longitude;

    final response = await _authed('POST', '/alerts', body: payload);
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw _handleError(response, 'Error al emitir alerta');
  }

  static Future<Map<String, dynamic>> updateAlertStatus(int id, String status) async {
    final response = await _authed(
      'PATCH',
      '/alerts/$id/status',
      body: {'status': status},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al actualizar estado de la alerta');
  }

  static Future<void> deleteAlert(int id) async {
    final response = await _authed('DELETE', '/alerts/$id');
    if (response.statusCode != 200) {
      throw _handleError(response, 'Error al eliminar alerta');
    }
  }

  // ── Dispositivos y Control PTZ ────────────────────────────────
  static Future<List<dynamic>> getDevices() async {
    final response = await _authed('GET', '/devices');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al cargar dispositivos');
  }

  static Future<Map<String, dynamic>> addDevice({
    required String title,
    String? subtitle,
    String status = 'Activo',
    String? imageUrl,
    String? streamUrl,
    String? ipAddress,
    int? port,
    bool isPtz = false,
    String deviceType = 'camera',
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{
      'title':       title,
      'subtitle':    subtitle ?? '',
      'status':      status,
      'imageUrl':    imageUrl ?? '',
      'stream_url':  streamUrl ?? '',
      'ip_address':  ipAddress ?? '',
      'is_ptz':      isPtz,
      'device_type': deviceType,
    };
    if (port != null)      payload['port']      = port;
    if (latitude != null)  payload['latitude']  = latitude;
    if (longitude != null) payload['longitude'] = longitude;

    final response = await _authed('POST', '/devices', body: payload);
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw _handleError(response, 'Error al agregar dispositivo');
  }

  static Future<Map<String, dynamic>> updateDevice(
    int id, {
    String? title,
    String? subtitle,
    String? status,
    String? streamUrl,
    String? ipAddress,
    int? port,
    bool? isPtz,
    String? deviceType,
  }) async {
    final body = <String, dynamic>{};
    if (title != null)      body['title']       = title;
    if (subtitle != null)   body['subtitle']    = subtitle;
    if (status != null)     body['status']      = status;
    if (streamUrl != null)  body['stream_url']  = streamUrl;
    if (ipAddress != null)  body['ip_address']  = ipAddress;
    if (port != null)       body['port']        = port;
    if (isPtz != null)      body['is_ptz']      = isPtz;
    if (deviceType != null) body['device_type'] = deviceType;

    final response = await _authed('PUT', '/devices/$id', body: body);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al actualizar dispositivo');
  }

  static Future<Map<String, dynamic>> sendPTZCommand(
    int deviceId,
    String command, {
    int speed = 5,
  }) async {
    final response = await _authed(
      'POST',
      '/devices/$deviceId/ptz',
      body: {'command': command, 'speed': speed},
      timeout: const Duration(seconds: 8),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al enviar comando PTZ');
  }

  static Future<void> deleteDevice(int id) async {
    final response = await _authed('DELETE', '/devices/$id');
    if (response.statusCode != 200) {
      throw _handleError(response, 'Error al eliminar dispositivo');
    }
  }

  // ── Reportes ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getReports() async {
    final response = await _authed('GET', '/reports');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al cargar reportes');
  }

  // ── Mapa ──────────────────────────────────────────────────────
  static Future<List<dynamic>> getMapNodes() async {
    final response = await _authed('GET', '/map/nodes');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al cargar nodos del mapa');
  }

  // ── Mensajes ──────────────────────────────────────────────────
  static Future<List<dynamic>> getMessages() async {
    final response = await _authed('GET', '/messages');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al cargar mensajes');
  }

  static Future<Map<String, dynamic>> sendMessage(String text) async {
    final response = await _authed('POST', '/messages', body: {'text': text});
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw _handleError(response, 'Error al enviar mensaje');
  }

  static Future<Map<String, dynamic>> getUser() async {
    final response = await _authed('GET', '/user');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al cargar usuario');
  }

  // ── Logout (server-side token revocation) ─────────────────────
  static Future<void> logout() async {
    final token = await getToken();
    if (token == null) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Si falla la red, igualmente limpiamos local
    }
  }

  // ── Perfil del usuario autenticado ───────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _authed('GET', '/profile');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al cargar perfil');
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatar,
    String? password,
    String? passwordConfirmation,
  }) async {
    final body = <String, dynamic>{};
    if (name != null)                 body['name']                  = name;
    if (phone != null)                body['phone']                 = phone;
    if (avatar != null)               body['avatar']                = avatar;
    if (password != null)             body['password']              = password;
    if (passwordConfirmation != null) body['password_confirmation'] = passwordConfirmation;

    final response = await _authed('PUT', '/profile', body: body);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al actualizar perfil');
  }

  // ── Gestión de usuarios (solo Admin) ─────────────────────────
  static Future<List<dynamic>> getUsers() async {
    final response = await _authed('GET', '/admin/users');
    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 403) throw Exception('Sin permisos de administrador');
    throw _handleError(response, 'Error al cargar usuarios');
  }

  static Future<Map<String, dynamic>> updateUserRole(int userId, String role) async {
    final response = await _authed(
      'PUT',
      '/admin/users/$userId/role',
      body: {'role': role},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al actualizar rol');
  }

  static Future<void> deleteUser(int userId) async {
    final response = await _authed('DELETE', '/admin/users/$userId');
    if (response.statusCode != 200) {
      throw _handleError(response, 'Error al eliminar usuario');
    }
  }
}

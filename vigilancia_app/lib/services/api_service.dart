import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚠️ IMPORTANTE: Si usas un dispositivo físico, cambia 127.0.0.1 por la IP local de tu PC (ej. 192.168.1.100)
  // Si usas el emulador de Android, usa 10.0.2.2
    static const String baseUrl = "https://humberto.alwaysdata.net/api";
  static const String localCameraStream = 'local://device-camera';

  static bool isLocalCamera(String? streamUrl) =>
      (streamUrl ?? '').startsWith('local://');

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
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 401) throw Exception('Sesión expirada');
    throw _handleError(response, 'Error al cargar dashboard');
  }

  // ── Alertas ───────────────────────────────────────────────────
  static Future<List<dynamic>> getAlerts() async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse('$baseUrl/alerts'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 401) throw Exception('Sesión expirada');
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
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

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

    final response = await http.post(
      Uri.parse('$baseUrl/alerts'),
      headers: _authHeaders(token),
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) return jsonDecode(response.body);
    throw _handleError(response, 'Error al emitir alerta');
  }

  static Future<Map<String, dynamic>> updateAlertStatus(int id, String status) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.patch(
      Uri.parse('$baseUrl/alerts/$id/status'),
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al actualizar estado de la alerta');
  }

  static Future<void> deleteAlert(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.delete(
      Uri.parse('$baseUrl/alerts/$id'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw _handleError(response, 'Error al eliminar alerta');
    }
  }

  // ── Dispositivos y Control PTZ ────────────────────────────────
  static Future<List<dynamic>> getDevices() async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse('$baseUrl/devices'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 401) throw Exception('Sesión expirada');
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
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

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

    final response = await http.post(
      Uri.parse('$baseUrl/devices'),
      headers: _authHeaders(token),
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 10));

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
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final body = <String, dynamic>{};
    if (title != null)      body['title']       = title;
    if (subtitle != null)   body['subtitle']    = subtitle;
    if (status != null)     body['status']      = status;
    if (streamUrl != null)  body['stream_url']  = streamUrl;
    if (ipAddress != null)  body['ip_address']  = ipAddress;
    if (port != null)       body['port']        = port;
    if (isPtz != null)      body['is_ptz']      = isPtz;
    if (deviceType != null) body['device_type'] = deviceType;

    final response = await http.put(
      Uri.parse('$baseUrl/devices/$id'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al actualizar dispositivo');
  }

  static Future<Map<String, dynamic>> sendPTZCommand(
    int deviceId,
    String command, {
    int speed = 5,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.post(
      Uri.parse('$baseUrl/devices/$deviceId/ptz'),
      headers: _authHeaders(token),
      body: jsonEncode({'command': command, 'speed': speed}),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al enviar comando PTZ');
  }

  static Future<void> deleteDevice(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.delete(
      Uri.parse('$baseUrl/devices/$id'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw _handleError(response, 'Error al eliminar dispositivo');
    }
  }

  // ── Reportes ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getReports() async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse('$baseUrl/reports'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 401) throw Exception('Sesión expirada');
    throw _handleError(response, 'Error al cargar reportes');
  }

  // ── Mapa ──────────────────────────────────────────────────────
  static Future<List<dynamic>> getMapNodes() async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse('$baseUrl/map/nodes'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al cargar nodos del mapa');
  }

  // ── Mensajes ──────────────────────────────────────────────────
  static Future<List<dynamic>> getMessages() async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse('$baseUrl/messages'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar mensajes');
  }

  static Future<Map<String, dynamic>> sendMessage(String text) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: _authHeaders(token),
      body: jsonEncode({'text': text}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Error al enviar mensaje');
  }

  // ── Logout (server-side token revocation) ─────────────────────
  static Future<void> logout() async {
    final token = await getToken();
    if (token == null) return; // sin sesión, no hay nada que revocar

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
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 401) throw Exception('Sesión expirada');
    throw _handleError(response, 'Error al cargar perfil');
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatar,
    String? password,
    String? passwordConfirmation,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final body = <String, dynamic>{};
    if (name != null)                 body['name']                  = name;
    if (phone != null)                body['phone']                 = phone;
    if (avatar != null)               body['avatar']                = avatar;
    if (password != null)             body['password']              = password;
    if (passwordConfirmation != null) body['password_confirmation'] = passwordConfirmation;

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al actualizar perfil');
  }

  // ── Gestión de usuarios (solo Admin) ─────────────────────────
  static Future<List<dynamic>> getUsers() async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 401) throw Exception('Sesión expirada');
    if (response.statusCode == 403) throw Exception('Sin permisos de administrador');
    throw _handleError(response, 'Error al cargar usuarios');
  }

  static Future<Map<String, dynamic>> updateUserRole(int userId, String role) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/role'),
      headers: _authHeaders(token),
      body: jsonEncode({'role': role}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al actualizar rol');
  }

  static Future<void> deleteUser(int userId) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: _authHeaders(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw _handleError(response, 'Error al eliminar usuario');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";

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
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.post(
      Uri.parse('$baseUrl/alerts'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'type':        type,
        'priority':    priority,
        'location':    location ?? '',
        'description': description ?? '',
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) return jsonDecode(response.body);
    throw _handleError(response, 'Error al emitir alerta');
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

  // ── Dispositivos ──────────────────────────────────────────────
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
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.post(
      Uri.parse('$baseUrl/devices'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'title':    title,
        'subtitle': subtitle ?? '',
        'status':   status,
        'imageUrl': imageUrl ?? '',
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) return jsonDecode(response.body);
    throw _handleError(response, 'Error al agregar dispositivo');
  }

  static Future<Map<String, dynamic>> updateDevice(
    int id, {
    String? title,
    String? subtitle,
    String? status,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final body = <String, dynamic>{};
    if (title != null)    body['title']    = title;
    if (subtitle != null) body['subtitle'] = subtitle;
    if (status != null)   body['status']   = status;

    final response = await http.put(
      Uri.parse('$baseUrl/devices/$id'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response, 'Error al actualizar dispositivo');
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
}

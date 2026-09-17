import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTA: estas pruebas usan MockClient del paquete http/testing.dart
//
// Agrega en pubspec.yaml (dev_dependencies):
//   flutter_test:
//     sdk: flutter
//   http: ^1.1.0          # ya lo tienes
//   mockito: ^5.4.0
//   build_runner: ^2.4.0
// ─────────────────────────────────────────────────────────────────────────────

// Versión del ApiService adaptada para inyección del cliente HTTP
// (copia temporal solo para pruebas — no modifica tu ApiService original)
class TestApiService {
final http.Client client;
final String baseUrl;

TestApiService({required this.client, this.baseUrl = 'http://127.0.0.1:8000/api'});

Map<String, String> authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
};

  // ── Dispositivos ──────────────────────────────────────────────
Future<List<dynamic>> getDevices(String token) async {
    final response = await client.get(
    Uri.parse('$baseUrl/devices'),
    headers: authHeaders(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 401) throw Exception('Sesión expirada');
    throw Exception('Error al cargar dispositivos');
}

Future<Map<String, dynamic>> addDevice(
    String token, {
    required String title,
    String? subtitle,
    String status = 'Activo',
}) async {
    final response = await client.post(
    Uri.parse('$baseUrl/devices'),
    headers: authHeaders(token),
    body: jsonEncode({'title': title, 'subtitle': subtitle ?? '', 'status': status}),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Error al agregar dispositivo');
}

Future<Map<String, dynamic>> updateDevice(
    String token,
    int id, {
    String? title,
    String? status,
}) async {
    final body = <String, dynamic>{};
    if (title != null)  body['title']  = title;
    if (status != null) body['status'] = status;

    final response = await client.put(
    Uri.parse('$baseUrl/devices/$id'),
    headers: authHeaders(token),
    body: jsonEncode(body),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al actualizar dispositivo');
}

Future<void> deleteDevice(String token, int id) async {
    final response = await client.delete(
    Uri.parse('$baseUrl/devices/$id'),
    headers: authHeaders(token),
    );
    if (response.statusCode != 200) throw Exception('Error al eliminar dispositivo');
}
}

// ─────────────────────────────────────────────────────────────────────────────
void main() {
const token = 'test-bearer-token-123';

  // ══════════════════════════════════════════════════════════════
  // GET /devices
  // ══════════════════════════════════════════════════════════════
group('getDevices()', () {
    test('retorna lista de dispositivos con status 200', () async {
    final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/devices'));
        expect(request.headers['Authorization'], equals('Bearer $token'));

        return http.Response(
        jsonEncode([
            {'id': 1, 'title': 'CAM-001', 'status': 'Activo'},
            {'id': 2, 'title': 'CAM-002', 'status': 'Inactivo'},
        ]),
        200,
        );
    });

    final service = TestApiService(client: mockClient);
    final devices = await service.getDevices(token);

    expect(devices.length, equals(2));
    expect(devices[0]['title'], equals('CAM-001'));
    expect(devices[1]['status'], equals('Inactivo'));
    });

    test('lanza excepción con status 401', () async {
    final mockClient = MockClient((_) async =>
        http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401));

    final service = TestApiService(client: mockClient);

    expect(
        () => service.getDevices(token),
        throwsA(predicate((e) => e.toString().contains('Sesión expirada'))),
    );
    });

    test('lanza excepción con status 500', () async {
    final mockClient = MockClient((_) async =>
        http.Response('Internal Server Error', 500));

    final service = TestApiService(client: mockClient);

    expect(
        () => service.getDevices(token),
        throwsA(isA<Exception>()),
    );
    });

    test('retorna lista vacía cuando no hay dispositivos', () async {
    final mockClient = MockClient((_) async =>
        http.Response(jsonEncode([]), 200));

    final service = TestApiService(client: mockClient);
    final devices = await service.getDevices(token);

    expect(devices, isEmpty);
    });
});

  // ══════════════════════════════════════════════════════════════
  // POST /devices
  // ══════════════════════════════════════════════════════════════
group('addDevice()', () {
    test('crea dispositivo y retorna datos con status 201', () async {
    final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));

        final body = jsonDecode(request.body);
        expect(body['title'], equals('CAM-Nueva'));
        expect(body['status'], equals('Activo'));

        return http.Response(
        jsonEncode({
            'message': 'Dispositivo registrado correctamente',
            'device': {
            'id': 10,
            'title': 'CAM-Nueva',
            'subtitle': 'Zona Norte',
            'status': 'Activo',
            },
        }),
        201,
        );
    });

    final service = TestApiService(client: mockClient);
    final result  = await service.addDevice(token, title: 'CAM-Nueva', subtitle: 'Zona Norte');

    expect(result['message'], contains('correctamente'));
    expect(result['device']['id'], equals(10));
    expect(result['device']['title'], equals('CAM-Nueva'));
    });

    test('lanza excepción con status 422 (validación)', () async {
    final mockClient = MockClient((_) async => http.Response(
            jsonEncode({
            'message': 'The title field is required.',
            'errors': {'title': ['The title field is required.']},
            }),
            422,
        ));

    final service = TestApiService(client: mockClient);

    expect(
        () => service.addDevice(token, title: ''),
        throwsA(isA<Exception>()),
    );
    });
});

  // ══════════════════════════════════════════════════════════════
  // PUT /devices/{id}
  // ══════════════════════════════════════════════════════════════
group('updateDevice()', () {
    test('actualiza dispositivo correctamente', () async {
    final mockClient = MockClient((request) async {
        expect(request.method, equals('PUT'));
        expect(request.url.path, equals('/api/devices/5'));

        final body = jsonDecode(request.body);
        expect(body['status'], equals('Mantenimiento'));

        return http.Response(
        jsonEncode({
            'message': 'Dispositivo actualizado correctamente',
            'device': {
            'id': 5,
            'title': 'CAM-005',
            'status': 'Mantenimiento',
            },
        }),
        200,
        );
    });

    final service = TestApiService(client: mockClient);
    final result  = await service.updateDevice(token, 5, status: 'Mantenimiento');

    expect(result['device']['status'], equals('Mantenimiento'));
    });

    test('lanza excepción si el dispositivo no existe (404)', () async {
    final mockClient = MockClient((_) async =>
        http.Response(jsonEncode({'message': 'Not Found'}), 404));

    final service = TestApiService(client: mockClient);

    expect(
        () => service.updateDevice(token, 9999, title: 'No existe'),
        throwsA(isA<Exception>()),
    );
    });
});

  // ══════════════════════════════════════════════════════════════
  // DELETE /devices/{id}
  // ══════════════════════════════════════════════════════════════
group('deleteDevice()', () {
    test('elimina dispositivo correctamente', () async {
    final mockClient = MockClient((request) async {
        expect(request.method, equals('DELETE'));
        expect(request.url.path, equals('/api/devices/3'));

        return http.Response(
        jsonEncode({'message': 'Dispositivo eliminado correctamente'}),
        200,
        );
    });

    final service = TestApiService(client: mockClient);

      // No lanza excepción → prueba pasa
    await expectLater(
        service.deleteDevice(token, 3),
        completes,
    );
    });

    test('lanza excepción si falla la eliminación', () async {
    final mockClient = MockClient((_) async =>
        http.Response(jsonEncode({'message': 'Not Found'}), 404));

    final service = TestApiService(client: mockClient);

    expect(
        () => service.deleteDevice(token, 9999),
        throwsA(isA<Exception>()),
    );
    });
});

  // ══════════════════════════════════════════════════════════════
  // FLUJO COMPLETO — crear → listar → actualizar → eliminar
  // ══════════════════════════════════════════════════════════════
group('Flujo completo de dispositivos', () {
    test('CRUD completo ejecuta correctamente en orden', () async {
    int dispositivoId = 0;

    final mockClient = MockClient((request) async {
        // POST → crear
        if (request.method == 'POST') {
        dispositivoId = 42;
        return http.Response(
            jsonEncode({
            'message': 'Dispositivo registrado correctamente',
            'device': {'id': dispositivoId, 'title': 'CAM-Flujo', 'status': 'Activo'},
            }),
            201,
        );
        }

        // GET → listar
        if (request.method == 'GET' && !request.url.path.contains('/42')) {
        return http.Response(
            jsonEncode([
            {'id': dispositivoId, 'title': 'CAM-Flujo', 'status': 'Activo'},
            ]),
            200,
        );
        }

        // PUT → actualizar
        if (request.method == 'PUT') {
        return http.Response(
            jsonEncode({
            'message': 'Dispositivo actualizado correctamente',
            'device': {'id': dispositivoId, 'title': 'CAM-Flujo', 'status': 'Inactivo'},
            }),
            200,
        );
        }

        // DELETE → eliminar
        if (request.method == 'DELETE') {
        return http.Response(
            jsonEncode({'message': 'Dispositivo eliminado correctamente'}),
            200,
        );
        }

        return http.Response('Not found', 404);
    });

    final service = TestApiService(client: mockClient);

      // 1. Crear
    final creado = await service.addDevice(token, title: 'CAM-Flujo');
    expect(creado['device']['id'], equals(42));

      // 2. Listar
    final lista = await service.getDevices(token);
    expect(lista.any((d) => d['id'] == 42), isTrue);

      // 3. Actualizar
    final actualizado = await service.updateDevice(token, 42, status: 'Inactivo');
    expect(actualizado['device']['status'], equals('Inactivo'));

      // 4. Eliminar
    await expectLater(service.deleteDevice(token, 42), completes);
    });
});
}
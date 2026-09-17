<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Pruebas de integración — Módulo de Dispositivos
 *
 * Ejecutar con:
 *   php artisan test --filter=DeviceTest
 *   php artisan test --filter=DeviceTest::test_puede_listar_dispositivos
 */
class DeviceTest extends TestCase
{
    use RefreshDatabase;

    // ── Usuario autenticado para todas las pruebas ────────────────
    private function usuarioAutenticado(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        return [
            'user' => $user,
            'headers' => [
                'Authorization' => "Bearer $token",
                'Accept' => 'application/json',
            ],
        ];
    }

    // ════════════════════════════════════════════════════════════
    // AUTENTICACIÓN — acceso sin token debe ser rechazado
    // ════════════════════════════════════════════════════════════

    /** @test */
    public function test_sin_token_no_puede_listar_dispositivos(): void
    {
        $response = $this->getJson('/api/devices');

        $response->assertStatus(401);
    }

    /** @test */
    public function test_sin_token_no_puede_crear_dispositivo(): void
    {
        $response = $this->postJson('/api/devices', [
            'title' => 'CAM-001',
        ]);

        $response->assertStatus(401);
    }

    // ════════════════════════════════════════════════════════════
    // GET /api/devices — listar
    // ════════════════════════════════════════════════════════════

    /** @test */
    public function test_puede_listar_dispositivos(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        Device::factory()->count(3)->create();

        $response = $this->getJson('/api/devices', $headers);

        $response
            ->assertStatus(200)
            ->assertJsonCount(3)
            ->assertJsonStructure([
                '*' => ['id', 'title', 'status', 'created_at'],
            ]);
    }

    /** @test */
    public function test_lista_vacia_cuando_no_hay_dispositivos(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $response = $this->getJson('/api/devices', $headers);

        $response
            ->assertStatus(200)
            ->assertJsonCount(0)
            ->assertJson([]);
    }

    // ════════════════════════════════════════════════════════════
    // GET /api/devices/{id} — ver uno
    // ════════════════════════════════════════════════════════════

    /** @test */
    public function test_puede_ver_un_dispositivo(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $device = Device::factory()->create([
            'title' => 'Cámara Entrada Principal',
            'status' => 'Activo',
        ]);

        $response = $this->getJson("/api/devices/{$device->id}", $headers);

        $response
            ->assertStatus(200)
            ->assertJsonFragment([
                'id' => $device->id,
                'title' => 'Cámara Entrada Principal',
                'status' => 'Activo',
            ]);
    }

    /** @test */
    public function test_retorna_404_para_dispositivo_inexistente(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $response = $this->getJson('/api/devices/9999', $headers);

        $response->assertStatus(404);
    }

    // ════════════════════════════════════════════════════════════
    // POST /api/devices — crear
    // ════════════════════════════════════════════════════════════

    /** @test */
    public function test_puede_crear_dispositivo_con_datos_validos(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $payload = [
            'title' => 'CAM-Sector-B',
            'subtitle' => 'Pasillo Central Bloque B',
            'status' => 'Activo',
        ];

        $response = $this->postJson('/api/devices', $payload, $headers);

        $response
            ->assertStatus(201)
            ->assertJsonFragment([
                'title' => 'CAM-Sector-B',
                'status' => 'Activo',
            ])
            ->assertJsonStructure([
                'message',
                'device' => ['id', 'title', 'subtitle', 'status'],
            ]);

        $this->assertDatabaseHas('devices', ['title' => 'CAM-Sector-B']);
    }

    /** @test */
    public function test_status_por_defecto_es_activo(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $response = $this->postJson('/api/devices', [
            'title' => 'CAM-Sin-Status',
        ], $headers);

        $response
            ->assertStatus(201)
            ->assertJsonFragment(['status' => 'Activo']);

        $this->assertDatabaseHas('devices', [
            'title' => 'CAM-Sin-Status',
            'status' => 'Activo',
        ]);
    }

    /** @test */
    public function test_no_puede_crear_dispositivo_sin_titulo(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $response = $this->postJson('/api/devices', [
            'subtitle' => 'Sin título',
            'status' => 'Activo',
        ], $headers);

        $response
            ->assertStatus(422)
            ->assertJsonValidationErrors(['title']);
    }

    /** @test */
    public function test_no_acepta_status_invalido(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $response = $this->postJson('/api/devices', [
            'title' => 'CAM-Test',
            'status' => 'StatusInvalido',
        ], $headers);

        $response
            ->assertStatus(422)
            ->assertJsonValidationErrors(['status']);
    }

    /** @test */
    public function test_titulo_no_puede_superar_100_caracteres(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $response = $this->postJson('/api/devices', [
            'title' => str_repeat('A', 101),
        ], $headers);

        $response
            ->assertStatus(422)
            ->assertJsonValidationErrors(['title']);
    }

    // ════════════════════════════════════════════════════════════
    // PUT /api/devices/{id} — actualizar
    // ════════════════════════════════════════════════════════════

    /** @test */
    public function test_puede_actualizar_dispositivo(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $device = Device::factory()->create([
            'title' => 'CAM-Original',
            'status' => 'Activo',
        ]);

        $response = $this->putJson("/api/devices/{$device->id}", [
            'title' => 'CAM-Actualizada',
            'status' => 'Mantenimiento',
        ], $headers);

        $response
            ->assertStatus(200)
            ->assertJsonFragment([
                'title' => 'CAM-Actualizada',
                'status' => 'Mantenimiento',
            ]);

        $this->assertDatabaseHas('devices', [
            'id' => $device->id,
            'title' => 'CAM-Actualizada',
            'status' => 'Mantenimiento',
        ]);
    }

    /** @test */
    public function test_puede_actualizar_solo_el_status(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $device = Device::factory()->create(['status' => 'Activo']);

        $response = $this->putJson("/api/devices/{$device->id}", [
            'status' => 'Inactivo',
        ], $headers);

        $response
            ->assertStatus(200)
            ->assertJsonFragment(['status' => 'Inactivo']);

        $this->assertDatabaseHas('devices', [
            'id' => $device->id,
            'status' => 'Inactivo',
        ]);
    }

    /** @test */
    public function test_actualizar_dispositivo_inexistente_retorna_404(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $response = $this->putJson('/api/devices/9999', [
            'title' => 'No existe',
        ], $headers);

        $response->assertStatus(404);
    }

    // ════════════════════════════════════════════════════════════
    // DELETE /api/devices/{id} — eliminar
    // ════════════════════════════════════════════════════════════

    /** @test */
    public function test_puede_eliminar_dispositivo(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $device = Device::factory()->create();

        $response = $this->deleteJson("/api/devices/{$device->id}", [], $headers);

        $response
            ->assertStatus(200)
            ->assertJsonFragment(['message' => 'Dispositivo eliminado correctamente']);

        $this->assertDatabaseMissing('devices', ['id' => $device->id]);
    }

    /** @test */
    public function test_eliminar_dispositivo_inexistente_retorna_404(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        $response = $this->deleteJson('/api/devices/9999', [], $headers);

        $response->assertStatus(404);
    }

    // ════════════════════════════════════════════════════════════
    // FLUJO COMPLETO — crear → listar → actualizar → eliminar
    // ════════════════════════════════════════════════════════════

    /** @test */
    public function test_flujo_completo_crud_dispositivo(): void
    {
        ['headers' => $headers] = $this->usuarioAutenticado();

        // 1. Crear
        $crear = $this->postJson('/api/devices', [
            'title' => 'CAM-Flujo-Test',
            'subtitle' => 'Zona perimetral Norte',
            'status' => 'Activo',
        ], $headers);

        $crear->assertStatus(201);
        $id = $crear->json('device.id');
        $this->assertNotNull($id);

        // 2. Listar — debe aparecer
        $listar = $this->getJson('/api/devices', $headers);
        $listar->assertStatus(200);
        $this->assertTrue(
            collect($listar->json())->contains('id', $id),
            'El dispositivo creado no aparece en la lista'
        );

        // 3. Ver detalle
        $ver = $this->getJson("/api/devices/$id", $headers);
        $ver->assertStatus(200)
            ->assertJsonFragment(['title' => 'CAM-Flujo-Test']);

        // 4. Actualizar
        $actualizar = $this->putJson("/api/devices/$id", [
            'status' => 'Mantenimiento',
        ], $headers);
        $actualizar->assertStatus(200)
            ->assertJsonFragment(['status' => 'Mantenimiento']);

        // 5. Eliminar
        $eliminar = $this->deleteJson("/api/devices/$id", [], $headers);
        $eliminar->assertStatus(200);

        // 6. Confirmar que ya no existe
        $this->getJson("/api/devices/$id", $headers)->assertStatus(404);

        $this->assertDatabaseMissing('devices', ['id' => $id]);
    }
}

<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\User;
use App\Models\Alert;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CameraAndAlertTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_register_camera_with_stream_and_ptz(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/devices', [
            'title'       => 'Cámara Domo PTZ Norte',
            'subtitle'    => 'Sector Entrada Principal',
            'status'      => 'Activo',
            'stream_url'  => 'rtsp://192.168.1.100:554/live/ch0',
            'ip_address'  => '192.168.1.100',
            'port'        => 554,
            'is_ptz'      => true,
            'device_type' => 'camera',
            'latitude'    => 4.7110,
            'longitude'   => -74.0721,
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('device.title', 'Cámara Domo PTZ Norte');
        $response->assertJsonPath('device.is_ptz', true);
        $response->assertJsonPath('device.stream_url', 'rtsp://192.168.1.100:554/live/ch0');

        $this->assertDatabaseHas('devices', [
            'title'      => 'Cámara Domo PTZ Norte',
            'stream_url' => 'rtsp://192.168.1.100:554/live/ch0',
            'is_ptz'     => 1,
        ]);
    }

    public function test_can_send_ptz_command_to_camera(): void
    {
        $user = User::factory()->create();
        $camera = Device::create([
            'title'      => 'Cámara Patio',
            'status'     => 'Activo',
            'is_ptz'     => true,
            'stream_url' => 'rtsp://10.0.0.5:554/live',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson("/api/devices/{$camera->id}/ptz", [
            'command' => 'up',
            'speed'   => 8,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('command', 'up');
        $response->assertJsonPath('speed', 8);
    }

    public function test_can_emit_alert_linked_to_device_with_coordinates_and_lifecycle(): void
    {
        $user = User::factory()->create(['name' => 'Operador 1']);
        $responder = User::factory()->create(['name' => 'Supervisor Guardia']);
        $camera = Device::create([
            'title'  => 'Cámara Acceso Peatonal',
            'status' => 'Activo',
        ]);

        // 1. Emitir alerta
        $createResponse = $this->actingAs($user, 'sanctum')->postJson('/api/alerts', [
            'type'        => 'Seguridad',
            'priority'    => 'Crítica',
            'location'    => 'Torniquete 1',
            'description' => 'Intrusión detectada en perímetro',
            'device_id'   => $camera->id,
            'latitude'    => 4.7115,
            'longitude'   => -74.0725,
        ]);

        $createResponse->assertStatus(201);
        $createResponse->assertJsonPath('alert.status', 'Pendiente');
        $createResponse->assertJsonPath('alert.device_name', 'Cámara Acceso Peatonal');
        $createResponse->assertJsonPath('alert.device_id', $camera->id);
        $alertId = $createResponse->json('alert.id');

        // 2. Iniciar atención de alerta
        $attendResponse = $this->actingAs($responder, 'sanctum')->patchJson("/api/alerts/{$alertId}/status", [
            'status' => 'En atención',
        ]);
        $attendResponse->assertStatus(200);
        $attendResponse->assertJsonPath('alert.status', 'En atención');
        $attendResponse->assertJsonPath('alert.attended_by', $responder->id);

        // 3. Resolver alerta
        $resolveResponse = $this->actingAs($responder, 'sanctum')->patchJson("/api/alerts/{$alertId}/status", [
            'status' => 'Resuelta',
        ]);
        $resolveResponse->assertStatus(200);
        $resolveResponse->assertJsonPath('alert.status', 'Resuelta');
        $this->assertNotNull($resolveResponse->json('alert.resolved_at'));

        // 4. Verificar index de alertas
        $indexResponse = $this->actingAs($user, 'sanctum')->getJson('/api/alerts');
        $indexResponse->assertStatus(200);
        $this->assertEquals('Cámara Acceso Peatonal', $indexResponse->json('0.device_name'));
        $this->assertEquals('Resuelta', $indexResponse->json('0.status'));
        $this->assertEquals('Supervisor Guardia', $indexResponse->json('0.attended_by_name'));
    }
}

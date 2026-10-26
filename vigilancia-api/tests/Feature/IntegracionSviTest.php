<?php

namespace Tests\Feature;

use App\Models\Alert;
use App\Models\Device;
use App\Models\Recording;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * Pruebas de integración del S.V.I. (diapositiva "Pruebas de integración").
 * Cada prueba recorre petición HTTP → controlador → base de datos → respuesta,
 * con tokens reales de Sanctum (no se simula la autenticación).
 */
class IntegracionSviTest extends TestCase
{
    use RefreshDatabase;

    private function login(User $user, string $password = 'password'): string
    {
        $res = $this->postJson('/api/login', ['email' => $user->email, 'password' => $password]);
        $res->assertOk();
        return $res->json('token');
    }

    private function as(string $token): static
    {
        // Olvida el usuario de la petición anterior para que cada llamada
        // se autentique solo con su token, como lo hace la app.
        $this->app['auth']->forgetGuards();
        return $this->withHeader('Authorization', "Bearer {$token}");
    }

    /** CI-01 Registro de usuario */
    public function test_ci01_registro_de_usuario(): void
    {
        $res = $this->postJson('/api/register', [
            'name'         => 'Vecino Prueba',
            'email'        => 'vecino@svi.test',
            'password'     => 'secreto123',
            'accept_terms' => true,
        ]);

        $res->assertCreated()->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']]);
        $this->assertArrayNotHasKey('password', $res->json('user'));

        $user = User::where('email', 'vecino@svi.test')->firstOrFail();
        $this->assertNotSame('secreto123', $user->password);
        $this->assertTrue(Hash::check('secreto123', $user->password));
        $this->assertSame('viewer', $user->fresh()->role);
    }

    /** CI-02 Inicio de sesión y dashboard */
    public function test_ci02_login_y_dashboard(): void
    {
        $user = User::factory()->create(['role' => 'operator']);
        Device::create(['title' => 'Cam Parque', 'status' => 'Activo', 'user_id' => $user->id]);

        $token = $this->login($user);
        $this->assertDatabaseCount('personal_access_tokens', 1);
        $this->assertDatabaseHas('personal_access_tokens', ['tokenable_id' => $user->id]);

        $this->as($token)->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('total_devices', 1)
            ->assertJsonPath('active_devices', 1)
            ->assertJsonStructure(['total_alerts', 'critical_alerts', 'recent_alerts']);
    }

    /** CI-03 Crear alerta */
    public function test_ci03_crear_alerta(): void
    {
        $user = User::factory()->create(['role' => 'operator']);
        $cam = Device::create(['title' => 'Cam Plaza', 'status' => 'Activo', 'user_id' => $user->id]);
        $token = $this->login($user);

        $res = $this->as($token)->postJson('/api/alerts', [
            'type'        => 'Seguridad',
            'priority'    => 'Crítica',
            'location'    => 'Plaza principal',
            'description' => 'Persona sospechosa',
            'device_id'   => $cam->id,
            'latitude'    => 5.3114,
            'longitude'   => -73.8155,
        ]);
        $res->assertCreated()->assertJsonPath('alert.status', 'Pendiente');

        $this->assertDatabaseHas('alerts', [
            'user_id' => $user->id, 'device_id' => $cam->id, 'type' => 'Seguridad',
        ]);
        $this->as($token)->getJson('/api/alerts')
            ->assertOk()
            ->assertJsonPath('0.device_name', 'Cam Plaza');
    }

    /** CI-04 Atender y resolver alerta */
    public function test_ci04_atender_y_resolver_alerta(): void
    {
        $reporter = User::factory()->create(['role' => 'viewer']);
        $operator = User::factory()->create(['role' => 'operator']);
        $alert = Alert::create([
            'user_id' => $reporter->id, 'type' => 'Incendio', 'priority' => 'Media', 'status' => 'Pendiente',
        ]);
        $token = $this->login($operator);

        $this->as($token)->patchJson("/api/alerts/{$alert->id}/status", ['status' => 'En atención'])
            ->assertOk()->assertJsonPath('alert.attended_by', $operator->id);

        $this->as($token)->patchJson("/api/alerts/{$alert->id}/status", ['status' => 'Resuelta'])
            ->assertOk()->assertJsonPath('alert.status', 'Resuelta');

        $fresh = $alert->fresh();
        $this->assertSame('Resuelta', $fresh->status);
        $this->assertSame($operator->id, (int) $fresh->attended_by);
        $this->assertNotNull($fresh->resolved_at);
    }

    /** CI-05 Mapa de eventos */
    public function test_ci05_mapa_de_eventos(): void
    {
        $user = User::factory()->create(['role' => 'operator']);
        Device::create(['title' => 'Cam Norte', 'status' => 'Activo', 'user_id' => $user->id,
            'latitude' => 5.30, 'longitude' => -73.81]);
        Alert::create(['user_id' => $user->id, 'type' => 'Seguridad', 'priority' => 'Baja',
            'status' => 'Pendiente', 'latitude' => 5.31, 'longitude' => -73.82]);
        $token = $this->login($user);

        $nodes = collect($this->as($token)->getJson('/api/map/nodes')->assertOk()->json());

        $device = $nodes->firstWhere('type', 'device');
        $alert  = $nodes->firstWhere('type', 'alert');
        $this->assertEquals(5.30, $device['lat']);
        $this->assertEquals(-73.81, $device['lng']);
        $this->assertEquals(5.31, $alert['lat']);
        $this->assertEquals(-73.82, $alert['lng']);
    }

    /** CI-06 Chat entre usuarios */
    public function test_ci06_chat_entre_usuarios(): void
    {
        $a = User::factory()->create(['name' => 'Ana']);
        $b = User::factory()->create(['name' => 'Beto']);

        $this->as($this->login($a))->postJson('/api/messages', ['text' => 'Hola vecinos'])->assertCreated();
        $this->assertDatabaseHas('messages', ['user_id' => $a->id, 'text' => 'Hola vecinos']);

        $msgs = $this->as($this->login($b))->getJson('/api/messages')->assertOk()->json();
        $last = end($msgs);
        $this->assertSame('Hola vecinos', $last['text']);
        $this->assertSame('Ana', $last['user']['name']);
        $this->assertNotEmpty($last['local_time']); // hora de Bogotá calculada por la API
    }

    /** CI-07 Grabaciones (datos de prueba) */
    public function test_ci07_grabaciones(): void
    {
        Storage::fake('local');
        $owner = User::factory()->create(['role' => 'operator']);
        $other = User::factory()->create(['role' => 'viewer']);
        $cam = Device::create(['title' => 'Cam Patio', 'status' => 'Activo', 'user_id' => $owner->id]);
        $tOwner = $this->login($owner);

        // Subir un clip de prueba
        $clip = UploadedFile::fake()->create('clip.webm', 300, 'video/webm');
        $res = $this->as($tOwner)->post('/api/recordings', [
            'file' => $clip, 'device_id' => $cam->id, 'duration_seconds' => 12,
        ], ['Accept' => 'application/json'])->assertCreated();
        $id = $res->json('recording.id');
        $this->assertDatabaseHas('recordings', ['id' => $id, 'device_id' => $cam->id, 'user_id' => $owner->id]);
        Storage::disk('local')->assertExists(Recording::find($id)->file_path);

        // Listado por cámara
        $list = $this->as($tOwner)->getJson("/api/recordings?device_id={$cam->id}")->assertOk()->json();
        $this->assertCount(1, $list);
        $this->assertSame(12, $list[0]['duration_seconds']);

        // Reproducción: el enlace firmado entrega el video; sin firma, no
        $this->app['auth']->forgetGuards();
        $this->get($list[0]['url'])->assertOk()->assertHeader('Content-Type', 'video/webm');
        $this->get("/api/recordings/{$id}/file")->assertForbidden();

        // Otro usuario no la ve ni la borra
        $tOther = $this->login($other);
        $this->assertCount(0, $this->as($tOther)->getJson('/api/recordings')->json());
        $this->as($tOther)->deleteJson("/api/recordings/{$id}")->assertForbidden();

        // El dueño la elimina
        $this->as($tOwner)->deleteJson("/api/recordings/{$id}")->assertOk();
        $this->assertDatabaseMissing('recordings', ['id' => $id]);
    }

    /** CI-08 Cierre de sesión */
    public function test_ci08_cierre_de_sesion(): void
    {
        $user = User::factory()->create();
        $token = $this->login($user);

        $this->as($token)->postJson('/api/logout')->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);

        $this->as($token)->getJson('/api/user')->assertUnauthorized();
    }
}

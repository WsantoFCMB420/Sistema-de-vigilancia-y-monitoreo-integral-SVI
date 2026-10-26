<?php

namespace Tests\Feature;

use App\Models\Alert;
use App\Models\Device;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/**
 * Evaluación de seguridad del S.V.I. alineada con OWASP Top 10 (diapositiva
 * "Evaluación de seguridad"). Los controles de transporte y de configuración
 * en producción se revisan aparte sobre humberto.alwaysdata.net.
 */
class SeguridadSviTest extends TestCase
{
    use RefreshDatabase;

    private function login(User $user): string
    {
        return $this->postJson('/api/login', ['email' => $user->email, 'password' => 'password'])
            ->assertOk()->json('token');
    }

    private function as(string $token): static
    {
        $this->app['auth']->forgetGuards();
        return $this->withHeader('Authorization', "Bearer {$token}");
    }

    /** S-01 Autenticación: rutas protegidas sin token o con token falso */
    public function test_s01_rutas_protegidas_sin_token(): void
    {
        $routes = ['/api/user', '/api/profile', '/api/dashboard', '/api/devices', '/api/alerts',
                   '/api/messages', '/api/map/nodes', '/api/reports', '/api/admin/users'];

        foreach ($routes as $route) {
            $this->getJson($route)->assertUnauthorized()->assertJsonMissingPath('0');
        }
        $this->withHeader('Authorization', 'Bearer 1|token-falso')
            ->getJson('/api/devices')->assertUnauthorized();
    }

    /** S-02 Autorización por rol (admin, operator, viewer) */
    public function test_s02_autorizacion_por_rol(): void
    {
        $admin    = User::factory()->create(['role' => 'admin']);
        $operator = User::factory()->create(['role' => 'operator']);
        $viewer   = User::factory()->create(['role' => 'viewer']);
        $alert = Alert::create(['user_id' => $viewer->id, 'type' => 'Seguridad',
            'priority' => 'Baja', 'status' => 'Pendiente']);
        $camAdmin = Device::create(['title' => 'Cam1', 'status' => 'Activo', 'user_id' => $admin->id,
            'latitude' => 5.30, 'longitude' => -73.81]);

        $tAdmin = $this->login($admin);
        $tOper  = $this->login($operator);
        $tView  = $this->login($viewer);

        // Gestión de usuarios: solo admin
        $this->as($tAdmin)->getJson('/api/admin/users')->assertOk();
        $this->as($tOper)->getJson('/api/admin/users')->assertForbidden();
        $this->as($tView)->getJson('/api/admin/users')->assertForbidden();

        // Reportes: admin y operador
        $this->as($tOper)->getJson('/api/reports')->assertOk();
        $this->as($tView)->getJson('/api/reports')->assertForbidden();

        // Cambiar estado de alertas: admin y operador
        $this->as($tView)->patchJson("/api/alerts/{$alert->id}/status", ['status' => 'Resuelta'])->assertForbidden();
        $this->as($tOper)->patchJson("/api/alerts/{$alert->id}/status", ['status' => 'En atención'])->assertOk();

        // Eliminar alertas ajenas: el visitante no puede
        $ajena = Alert::create(['user_id' => $operator->id, 'type' => 'Técnico',
            'priority' => 'Media', 'status' => 'Pendiente']);
        $this->as($tView)->deleteJson("/api/alerts/{$ajena->id}")->assertForbidden();
        $this->assertDatabaseHas('alerts', ['id' => $ajena->id]);

        // Dispositivos ajenos: el visitante no los ve ni los abre
        $this->as($tView)->getJson("/api/devices/{$camAdmin->id}")->assertForbidden();
        $this->as($tView)->deleteJson("/api/devices/{$camAdmin->id}")->assertForbidden();
        $this->assertCount(0, $this->as($tView)->getJson('/api/devices')->json());
        $map = collect($this->as($tView)->getJson('/api/map/nodes')->json());
        $this->assertNull($map->firstWhere('type', 'device'));
        $this->as($tView)->getJson('/api/dashboard')->assertJsonPath('total_devices', 0);

        // Cambiar el propio rol o un rol ajeno sin ser admin
        $this->as($tOper)->putJson("/api/admin/users/{$viewer->id}/role", ['role' => 'admin'])->assertForbidden();
        $this->assertSame('viewer', $viewer->fresh()->role);
    }

    /** S-03 Validación de entradas */
    public function test_s03_validacion_de_entradas(): void
    {
        $user = User::factory()->create(['role' => 'operator']);
        $token = $this->login($user);

        // Campos vacíos
        $this->as($token)->postJson('/api/alerts', [])->assertUnprocessable();
        $this->as($token)->postJson('/api/devices', [])->assertUnprocessable();
        $this->as($token)->postJson('/api/messages', ['text' => ''])->assertUnprocessable();
        $this->postJson('/api/register', [])->assertUnprocessable();

        // Texto extenso (límite 500)
        $this->as($token)->postJson('/api/messages', ['text' => str_repeat('a', 501)])->assertUnprocessable();

        // Valores fuera de la lista permitida
        $this->as($token)->postJson('/api/alerts', ['type' => 'X', 'priority' => 'Altísima'])->assertUnprocessable();

        // Inyección SQL en el login: rechazo controlado, sin error 500
        $this->postJson('/api/login', ['email' => "x' OR '1'='1", 'password' => "' OR 1=1 --"])
            ->assertUnprocessable();
        $this->postJson('/api/login', ['email' => 'a@b.co', 'password' => "' OR 1=1 --"])
            ->assertUnauthorized();

        // SQL y HTML se guardan como texto plano, sin ejecutarse
        $sql  = "'; DROP TABLE users; --";
        $html = '<script>alert(1)</script>';
        $this->as($token)->postJson('/api/messages', ['text' => $sql])->assertCreated();
        $this->as($token)->postJson('/api/messages', ['text' => $html])->assertCreated();
        $this->assertTrue(Schema::hasTable('users'));
        $this->assertDatabaseHas('messages', ['text' => $sql]);
        $this->assertDatabaseHas('messages', ['text' => $html]);
    }

    /** S-04 Credenciales: contraseñas en hash y tokens revocables */
    public function test_s04_credenciales(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Usuario', 'email' => 'u@svi.test', 'password' => 'clave123', 'accept_terms' => true,
        ])->assertCreated();

        $stored = DB::table('users')->where('email', 'u@svi.test')->value('password');
        $this->assertStringStartsWith('$2y$', $stored); // bcrypt

        $user = User::where('email', 'u@svi.test')->first();
        $res = $this->postJson('/api/login', ['email' => 'u@svi.test', 'password' => 'clave123'])->assertOk();
        $this->assertArrayNotHasKey('password', $res->json('user'));

        // El token se guarda como hash SHA-256, nunca en texto plano
        [, $plain] = explode('|', $res->json('token'), 2);
        $row = DB::table('personal_access_tokens')->where('tokenable_id', $user->id)->latest('id')->first();
        $this->assertNotSame($plain, $row->token);
        $this->assertSame(hash('sha256', $plain), $row->token);

        // Las respuestas de perfil y usuarios no incluyen la contraseña
        $this->as($res->json('token'))->getJson('/api/profile')->assertOk()->assertJsonMissingPath('password');
    }

    /** S-05 Sesiones: el token deja de servir al cerrar sesión */
    public function test_s05_sesiones(): void
    {
        $user = User::factory()->create();
        $t1 = $this->login($user);
        $t2 = $this->login($user); // otra sesión (por ejemplo, el celular)

        $this->as($t1)->postJson('/api/logout')->assertOk();
        $this->as($t1)->getJson('/api/user')->assertUnauthorized();
        $this->as($t2)->getJson('/api/user')->assertOk(); // la otra sesión sigue activa
        $this->assertDatabaseCount('personal_access_tokens', 1);
    }

    /** S-07 Datos personales: solo los campos necesarios (Ley 1581 de 2012) */
    public function test_s07_datos_personales_minimos(): void
    {
        $columns = Schema::getColumnListing('users');
        $permitidas = ['id', 'name', 'email', 'role', 'phone', 'avatar', 'email_verified_at',
                       'password', 'remember_token', 'created_at', 'updated_at'];
        $this->assertEqualsCanonicalizing($permitidas, $columns);

        $admin = User::factory()->create(['role' => 'admin']);
        $users = $this->as($this->login($admin))->getJson('/api/admin/users')->assertOk()->json();
        foreach ($users as $u) {
            $this->assertArrayNotHasKey('password', $u);
            $this->assertArrayNotHasKey('remember_token', $u);
        }
    }

    /** S-08 Configuración: .env fuera del repositorio y errores sin detalles internos */
    public function test_s08_configuracion(): void
    {
        $gitignore = file_get_contents(base_path('.gitignore'));
        $this->assertMatchesRegularExpression('/^\.env$/m', $gitignore);

        config(['app.debug' => false]);
        $res = $this->getJson('/api/ruta-que-no-existe')->assertNotFound();
        $this->assertArrayNotHasKey('trace', $res->json());
        $this->assertArrayNotHasKey('file', $res->json());
    }
}

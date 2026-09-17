<?php

namespace Database\Seeders;

use App\Models\Alert;
use App\Models\User;
use Illuminate\Database\Seeder;

class AlertSeeder extends Seeder
{
    public function run(): void
    {
        $adminId    = User::where('email', 'admin@svi.com')->value('id') ?? 1;
        $operatorId = User::where('email', 'operador1@svi.com')->value('id') ?? 2;

        $alerts = [
            ['type' => 'Intrusión',        'priority' => 'Crítica',  'location' => 'Sector A - Entrada Principal',  'description' => 'Persona no autorizada detectada'],
            ['type' => 'Movimiento',        'priority' => 'Alta',     'location' => 'Sector B - Almacén Norte',      'description' => 'Movimiento detectado fuera de horario'],
            ['type' => 'Vehículo robado',   'priority' => 'Crítica',  'location' => 'Avenida 5 con Calle 10',        'description' => 'Placa detectada en lista negra'],
            ['type' => 'Comportamiento',    'priority' => 'Media',    'location' => 'Parque Central',                'description' => 'Comportamiento sospechoso reportado'],
            ['type' => 'Incendio',          'priority' => 'Crítica',  'location' => 'Sector C - Zona Industrial',    'description' => 'Humo detectado por sensor térmico'],
            ['type' => 'Intrusión',         'priority' => 'Alta',     'location' => 'Perímetro Sur',                 'description' => 'Cerca cortada detectada'],
            ['type' => 'Movimiento',        'priority' => 'Baja',     'location' => 'Pasillo 3',                     'description' => 'Movimiento de animal detectado'],
            ['type' => 'Acceso denegado',   'priority' => 'Media',    'location' => 'Entrada Servidor Room',         'description' => 'Múltiples intentos de acceso fallidos'],
            ['type' => 'Sabotaje',          'priority' => 'Crítica',  'location' => 'Cámara CAM-07',                 'description' => 'Cámara bloqueada manualmente'],
            ['type' => 'Comportamiento',    'priority' => 'Alta',     'location' => 'Entrada Principal',             'description' => 'Aglomeración de personas detectada'],
            ['type' => 'Movimiento',        'priority' => 'Baja',     'location' => 'Zona de Carga',                 'description' => 'Actividad inusual detectada'],
            ['type' => 'Vehículo robado',   'priority' => 'Media',    'location' => 'Parqueadero Norte',             'description' => 'Vehículo sin autorización'],
            ['type' => 'Intrusión',         'priority' => 'Alta',     'location' => 'Sector D - Oficinas',           'description' => 'Detector de movimiento activado'],
            ['type' => 'Acceso denegado',   'priority' => 'Baja',     'location' => 'Puerta Lateral',                'description' => 'Credencial expirada detectada'],
            ['type' => 'Incendio',          'priority' => 'Crítica',  'location' => 'Bodega 2',                      'description' => 'Alarma de incendio activada'],
        ];

        foreach ($alerts as $i => $alert) {
            Alert::create(array_merge($alert, [
                'user_id'    => $i % 3 === 0 ? $adminId : $operatorId,
                'created_at' => now()->subHours(rand(1, 168)),
                'updated_at' => now()->subHours(rand(0, 10)),
            ]));
        }

        $this->command->info('✅ Alertas de prueba creadas correctamente');
    }
}

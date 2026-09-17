<?php

namespace Database\Seeders;

use App\Models\Device;
use Illuminate\Database\Seeder;

class DeviceSeeder extends Seeder
{
    public function run(): void
    {
        $devices = [
            ['title' => 'CAM-01 Entrada Principal',  'subtitle' => 'Edificio Norte - Planta Baja',    'status' => 'Activo',        'latitude' =>  4.6097, 'longitude' => -74.0817, 'imageUrl' => 'https://images.unsplash.com/photo-1593642532400-2682810df593?w=400'],
            ['title' => 'CAM-02 Parking B2',          'subtitle' => 'Sótano - Acceso Sur',             'status' => 'Inactivo',      'latitude' =>  4.6100, 'longitude' => -74.0820, 'imageUrl' => 'https://images.unsplash.com/photo-1502920917128-1aa500764b6b?w=400'],
            ['title' => 'CAM-03 Zona Coworking',      'subtitle' => 'Edificio Central - Ala Este',     'status' => 'Activo',        'latitude' =>  4.6090, 'longitude' => -74.0810, 'imageUrl' => 'https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=400'],
            ['title' => 'CAM-04 Almacén Norte',       'subtitle' => 'Bodega 1 - Acceso Oriente',      'status' => 'Activo',        'latitude' =>  4.6110, 'longitude' => -74.0830, 'imageUrl' => 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400'],
            ['title' => 'CAM-05 Perímetro Sur',       'subtitle' => 'Valla Sur - Poste 12',            'status' => 'Activo',        'latitude' =>  4.6080, 'longitude' => -74.0840, 'imageUrl' => 'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=400'],
            ['title' => 'CAM-06 Recepción',           'subtitle' => 'Lobby Principal - Piso 1',        'status' => 'Activo',        'latitude' =>  4.6095, 'longitude' => -74.0815, 'imageUrl' => 'https://images.unsplash.com/photo-1504868584819-f8e8b4b6d7e3?w=400'],
            ['title' => 'CAM-07 Sala Servidores',     'subtitle' => 'Data Center - Piso 3',            'status' => 'Inactivo',      'latitude' =>  4.6102, 'longitude' => -74.0822, 'imageUrl' => 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400'],
            ['title' => 'CAM-08 Zona Industrial',     'subtitle' => 'Planta de Producción - Área C',  'status' => 'Activo',        'latitude' =>  4.6115, 'longitude' => -74.0835, 'imageUrl' => 'https://images.unsplash.com/photo-1565043589221-1a6fd9ae45c7?w=400'],
            ['title' => 'CAM-09 Parqueadero Norte',   'subtitle' => 'Acceso Vehicular Norte',          'status' => 'Activo',        'latitude' =>  4.6120, 'longitude' => -74.0825, 'imageUrl' => 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=400'],
            ['title' => 'CAM-10 Pasillo Principal',   'subtitle' => 'Corredor Central - Piso 2',       'status' => 'Mantenimiento', 'latitude' =>  4.6098, 'longitude' => -74.0812, 'imageUrl' => 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400'],
        ];

        foreach ($devices as $device) {
            Device::updateOrCreate(
                ['title' => $device['title']],
                $device
            );
        }

        $this->command->info('✅ Dispositivos/cámaras de prueba creados correctamente');
    }
}
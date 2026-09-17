<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Device;

class DeviceSeeder extends Seeder
{
    public function run(): void
    {
        Device::create([
            'title'    => 'Entrada Principal',
            'subtitle' => 'Edificio Norte - Planta Baja',
            'status'   => 'Activo',
            'imageUrl' => 'https://images.unsplash.com/photo-1593642532400-2682810df593',
        ]);

        Device::create([
            'title'    => 'Parking B2',
            'subtitle' => 'Sótano - Acceso Sur',
            'status'   => 'Inactivo',
            'imageUrl' => 'https://images.unsplash.com/photo-1502920917128-1aa500764b6b',
        ]);

        Device::create([
            'title'    => 'Zona Coworking',
            'subtitle' => 'Edificio Central - Ala Este',
            'status'   => 'Activo',
            'imageUrl' => 'https://images.unsplash.com/photo-1529333166437-7750a6dd5a70',
        ]);
    }
}
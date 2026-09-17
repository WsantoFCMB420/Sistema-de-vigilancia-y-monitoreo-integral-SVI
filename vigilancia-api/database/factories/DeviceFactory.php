<?php

namespace Database\Factories;

use App\Models\Device;
use Illuminate\Database\Eloquent\Factories\Factory;

class DeviceFactory extends Factory
{
    protected $model = Device::class;

    public function definition(): array
    {
        return [
            'title'    => 'CAM-' . strtoupper($this->faker->bothify('??-###')),
            'subtitle' => $this->faker->randomElement([
                'Zona perimetral Norte',
                'Pasillo Central Bloque B',
                'Entrada Principal',
                'Parqueadero Nivel 1',
                'Acceso Administrativo',
            ]),
            'status'   => $this->faker->randomElement(['Activo', 'Inactivo', 'Mantenimiento']),
            'imageUrl' => null,
        ];
    }

    // Estados predefinidos para usar en pruebas
    public function activo(): static
    {
        return $this->state(['status' => 'Activo']);
    }

    public function inactivo(): static
    {
        return $this->state(['status' => 'Inactivo']);
    }

    public function enMantenimiento(): static
    {
        return $this->state(['status' => 'Mantenimiento']);
    }
}
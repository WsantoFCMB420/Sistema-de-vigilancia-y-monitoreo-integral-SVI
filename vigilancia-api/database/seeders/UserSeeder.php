<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // ── Admin principal ───────────────────────────────────────
        User::updateOrCreate(
            ['email' => 'admin@svi.com'],
            [
                'name'     => 'Administrador SVI',
                'email'    => 'admin@svi.com',
                'password' => Hash::make('admin123'),
                'role'     => 'admin',
                'phone'    => '+57 300 000 0001',
            ]
        );

        // ── Operadores ────────────────────────────────────────────
        User::updateOrCreate(
            ['email' => 'operador1@svi.com'],
            [
                'name'     => 'Carlos Méndez',
                'email'    => 'operador1@svi.com',
                'password' => Hash::make('oper123'),
                'role'     => 'operator',
                'phone'    => '+57 300 000 0002',
            ]
        );

        User::updateOrCreate(
            ['email' => 'operador2@svi.com'],
            [
                'name'     => 'Laura Sánchez',
                'email'    => 'operador2@svi.com',
                'password' => Hash::make('oper123'),
                'role'     => 'operator',
                'phone'    => '+57 300 000 0003',
            ]
        );

        // ── Viewers ───────────────────────────────────────────────
        User::updateOrCreate(
            ['email' => 'viewer@svi.com'],
            [
                'name'     => 'Juan García',
                'email'    => 'viewer@svi.com',
                'password' => Hash::make('view123'),
                'role'     => 'viewer',
                'phone'    => '+57 300 000 0004',
            ]
        );

        $this->command->info('✅ Usuarios creados correctamente');
    }
}

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * La migración 2026_09_17_190000 asignó los dispositivos sin dueño al
 * PRIMER usuario de la tabla, que no siempre es el administrador.
 * Aquí los dispositivos que sigan sin dueño pasan al primer administrador.
 *
 * Si una cámara del admin quedó asignada a otro usuario, corrígela a mano
 * (ver README, sección "Dueños de dispositivos").
 */
return new class extends Migration
{
    public function up(): void
    {
        $admin = DB::table('users')->where('role', 'admin')->orderBy('id')->first();
        if ($admin) {
            DB::table('devices')->whereNull('user_id')->update(['user_id' => $admin->id]);
        }
    }

    public function down(): void
    {
        // Sin reversión: no se puede saber qué dispositivos no tenían dueño.
    }
};

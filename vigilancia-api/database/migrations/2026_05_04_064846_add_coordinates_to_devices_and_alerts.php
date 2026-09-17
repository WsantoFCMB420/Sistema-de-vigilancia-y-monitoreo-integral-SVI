<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
public function up(): void
{
    Schema::table('devices', function (Blueprint $table) {
        if (!Schema::hasColumn('devices', 'latitude')) {
            $table->double('latitude')->nullable();
        }
        if (!Schema::hasColumn('devices', 'longitude')) {
            $table->double('longitude')->nullable();
        }
    });
    Schema::table('alerts', function (Blueprint $table) {
        if (!Schema::hasColumn('alerts', 'latitude')) {
            $table->double('latitude')->nullable();
        }
        if (!Schema::hasColumn('alerts', 'longitude')) {
            $table->double('longitude')->nullable();
        }
    });
}

public function down(): void
{
    Schema::table('devices', function (Blueprint $table) {
        $table->dropColumn(['latitude', 'longitude']);
    });
    Schema::table('alerts', function (Blueprint $table) {
        $table->dropColumn(['latitude', 'longitude']);
    });
}
};

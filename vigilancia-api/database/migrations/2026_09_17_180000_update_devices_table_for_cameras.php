<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('devices', function (Blueprint $table) {
            if (!Schema::hasColumn('devices', 'stream_url')) {
                $table->string('stream_url')->nullable()->after('imageUrl');
            }
            if (!Schema::hasColumn('devices', 'ip_address')) {
                $table->string('ip_address')->nullable()->after('stream_url');
            }
            if (!Schema::hasColumn('devices', 'port')) {
                $table->integer('port')->nullable()->after('ip_address');
            }
            if (!Schema::hasColumn('devices', 'is_ptz')) {
                $table->boolean('is_ptz')->default(false)->after('port');
            }
            if (!Schema::hasColumn('devices', 'device_type')) {
                $table->string('device_type')->default('camera')->after('is_ptz');
            }
        });
    }

    public function down(): void
    {
        Schema::table('devices', function (Blueprint $table) {
            $table->dropColumn(['stream_url', 'ip_address', 'port', 'is_ptz', 'device_type']);
        });
    }
};

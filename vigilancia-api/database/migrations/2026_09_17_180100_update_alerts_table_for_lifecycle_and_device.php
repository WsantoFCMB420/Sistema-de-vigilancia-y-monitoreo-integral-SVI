<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('alerts', function (Blueprint $table) {
            if (!Schema::hasColumn('alerts', 'device_id')) {
                $table->foreignId('device_id')->nullable()->after('user_id')->constrained('devices')->nullOnDelete();
            }
            if (!Schema::hasColumn('alerts', 'status')) {
                $table->string('status')->default('Pendiente')->after('description');
            }
            if (!Schema::hasColumn('alerts', 'attended_by')) {
                $table->foreignId('attended_by')->nullable()->after('status')->constrained('users')->nullOnDelete();
            }
            if (!Schema::hasColumn('alerts', 'resolved_at')) {
                $table->timestamp('resolved_at')->nullable()->after('attended_by');
            }
        });
    }

    public function down(): void
    {
        Schema::table('alerts', function (Blueprint $table) {
            $table->dropForeign(['device_id']);
            $table->dropForeign(['attended_by']);
            $table->dropColumn(['device_id', 'status', 'attended_by', 'resolved_at']);
        });
    }
};

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Device extends Model
{
    public function up()
{
    Schema::create('devices', function (Blueprint $table) {
        $table->id();
        $table->string('title');
        $table->string('subtitle');
        $table->string('status');
        $table->string('imageUrl');
        $table->timestamps();
    });
}
}

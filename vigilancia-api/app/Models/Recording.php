<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Recording extends Model
{
    protected $fillable = [
        'user_id',
        'device_id',
        'file_path',
        'mime_type',
        'size_bytes',
        'duration_seconds',
    ];

    protected $casts = [
        'size_bytes'       => 'integer',
        'duration_seconds' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function device()
    {
        return $this->belongsTo(Device::class);
    }
}

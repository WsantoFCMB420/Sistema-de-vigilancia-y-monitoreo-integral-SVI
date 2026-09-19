<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Device extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'subtitle',
        'status',
        'imageUrl',
        'stream_url',
        'ip_address',
        'port',
        'is_ptz',
        'device_type',
        'latitude',
        'longitude',
    ];

    protected $casts = [
        'is_ptz' => 'boolean',
        'port' => 'integer',
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    public function alerts()
    {
        return $this->hasMany(Alert::class);
    }
}

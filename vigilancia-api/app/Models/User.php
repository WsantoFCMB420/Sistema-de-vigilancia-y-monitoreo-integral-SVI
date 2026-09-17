<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'phone',
        'avatar',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
        ];
    }

    // ── Helpers de rol ────────────────────────────────────────────
    public function isAdmin(): bool    { return $this->role === 'admin'; }
    public function isOperator(): bool { return $this->role === 'operator'; }
    public function isViewer(): bool   { return $this->role === 'viewer'; }

    // ── Relaciones ────────────────────────────────────────────────
    public function alerts()
    {
        return $this->hasMany(Alert::class);
    }

    public function messages()
    {
        return $this->hasMany(Message::class);
    }
}

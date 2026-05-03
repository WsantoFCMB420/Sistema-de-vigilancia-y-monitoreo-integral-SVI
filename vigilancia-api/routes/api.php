<?php

use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DeviceController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::get('/devices', [DeviceController::class, 'index']);
Route::get('/dashboard', function () {
    return response()->json([
        'total_devices' => 3,
        'active_devices' => 2,
        'inactive_devices' => 1
    ]);
});

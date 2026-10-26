<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\DeviceController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\MapController;
use App\Http\Controllers\AlertController;
use App\Http\Controllers\MessageController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\RecordingController;

// ── Rutas públicas ────────────────────────────────────────────────
Route::post('/register',         [AuthController::class, 'register']);
Route::post('/login',            [AuthController::class, 'login']);
Route::post('/forgot-password',  [AuthController::class, 'forgotPassword']);

// Archivo de una grabación: se abre con un enlace firmado que vence en 30 min
// (el reproductor de video no puede enviar el token en la cabecera).
Route::get('/recordings/{id}/file', [RecordingController::class, 'file'])
    ->middleware('signed:relative')
    ->name('recordings.file');

// ── Rutas protegidas ──────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // Sesión
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        return $request->user()->only('id', 'name', 'email', 'role');
    });

    // Perfil (todos los usuarios autenticados)
    Route::get('/profile',  [UserController::class, 'profile']);
    Route::put('/profile',  [UserController::class, 'updateProfile']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Dispositivos — CRUD completo y control PTZ
    Route::get('/devices',            [DeviceController::class, 'index']);
    Route::post('/devices',           [DeviceController::class, 'store']);
    Route::get('/devices/{id}',       [DeviceController::class, 'show']);
    Route::put('/devices/{id}',       [DeviceController::class, 'update']);
    Route::delete('/devices/{id}',    [DeviceController::class, 'destroy']);
    Route::post('/devices/{id}/ptz',  [DeviceController::class, 'ptz']);

    // Alertas y ciclo de vida
    Route::get('/alerts',             [AlertController::class, 'index']);
    Route::post('/alerts',            [AlertController::class, 'store']);
    Route::put('/alerts/{id}',        [AlertController::class, 'update']);
    Route::patch('/alerts/{id}/status', [AlertController::class, 'updateStatus']);
    Route::delete('/alerts/{id}',     [AlertController::class, 'destroy']);

    // Reportes (el rol visitante no tiene acceso)
    Route::get('/reports', [ReportController::class, 'index'])->middleware('role:admin,operator');

    // Grabaciones
    Route::get('/recordings',          [RecordingController::class, 'index']);
    Route::post('/recordings',         [RecordingController::class, 'store']);
    Route::delete('/recordings/{id}',  [RecordingController::class, 'destroy']);

    // Mapa
    Route::get('/map/nodes', [MapController::class, 'nodes']);

    // Mensajes
    Route::get('/messages',  [MessageController::class, 'index']);
    Route::post('/messages', [MessageController::class, 'store']);

    // ── Rutas solo para Admins ─────────────────────────────────
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/users',              [UserController::class, 'index']);
        Route::put('/users/{id}/role',    [UserController::class, 'updateRole']);
        Route::delete('/users/{id}',      [UserController::class, 'destroy']);
    });
});
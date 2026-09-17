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

// ── Rutas públicas ────────────────────────────────────────────────
Route::post('/register',         [AuthController::class, 'register']);
Route::post('/login',            [AuthController::class, 'login']);
Route::post('/forgot-password',  [AuthController::class, 'forgotPassword']);

// ── Rutas protegidas ──────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // Sesión
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        return $request->user()->only('id', 'name', 'email');
    });

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Dispositivos — CRUD completo
    Route::get('/devices',          [DeviceController::class, 'index']);
    Route::post('/devices',         [DeviceController::class, 'store']);
    Route::get('/devices/{id}',     [DeviceController::class, 'show']);
    Route::put('/devices/{id}',     [DeviceController::class, 'update']);
    Route::delete('/devices/{id}',  [DeviceController::class, 'destroy']);

    // Alertas
    Route::get('/alerts',           [AlertController::class, 'index']);
    Route::post('/alerts',          [AlertController::class, 'store']);
    Route::put('/alerts/{id}',      [AlertController::class, 'update']);
    Route::delete('/alerts/{id}',   [AlertController::class, 'destroy']);

    // Reportes
    Route::get('/reports',          [ReportController::class, 'index']);

    // Mapa
    Route::get('/map/nodes',        [MapController::class, 'nodes']);

    // Mensajes
    Route::get('/messages',         [MessageController::class, 'index']);
    Route::post('/messages',        [MessageController::class, 'store']);
});
<?php

namespace App\Http\Controllers;

use App\Models\Device;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    // ── GET /devices ───────────────────────────────────────────────
    public function index()
    {
        return response()->json(Device::latest()->get());
    }

    // ── GET /devices/{id} ─────────────────────────────────────────
    public function show($id)
    {
        $device = Device::findOrFail($id);
        return response()->json($device);
    }

    // ── POST /devices ─────────────────────────────────────────────
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title'    => 'required|string|max:100',
            'subtitle' => 'nullable|string|max:200',
            'status'   => 'nullable|in:Activo,Inactivo,Mantenimiento',
            'imageUrl' => 'nullable|string|max:500',
        ]);

        $validated['status'] = $validated['status'] ?? 'Activo';

        $device = Device::create($validated);

        return response()->json([
            'message' => 'Dispositivo registrado correctamente',
            'device'  => $device,
        ], 201);
    }

    // ── PUT /devices/{id} ─────────────────────────────────────────
    public function update(Request $request, $id)
    {
        $device = Device::findOrFail($id);

        $validated = $request->validate([
            'title'    => 'sometimes|required|string|max:100',
            'subtitle' => 'nullable|string|max:200',
            'status'   => 'nullable|in:Activo,Inactivo,Mantenimiento',
            'imageUrl' => 'nullable|string|max:500',
        ]);

        $device->update($validated);

        return response()->json([
            'message' => 'Dispositivo actualizado correctamente',
            'device'  => $device,
        ]);
    }

    // ── DELETE /devices/{id} ──────────────────────────────────────
    public function destroy($id)
    {
        $device = Device::findOrFail($id);
        $device->delete();

        return response()->json([
            'message' => 'Dispositivo eliminado correctamente',
        ]);
    }
}

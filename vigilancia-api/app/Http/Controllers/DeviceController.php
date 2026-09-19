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
            'title'       => 'required|string|max:100',
            'subtitle'    => 'required|string|max:200',
            'status'      => 'nullable|in:Activo,Inactivo,Mantenimiento',
            'imageUrl'    => 'nullable|string|max:500',
            'stream_url'  => 'nullable|string|max:500',
            'ip_address'  => 'nullable|string|max:100',
            'port'        => 'nullable|integer|between:1,65535',
            'is_ptz'      => 'nullable|boolean',
            'device_type' => 'required|in:camera,sensor,alarm,access',
            'latitude'    => 'nullable|numeric',
            'longitude'   => 'nullable|numeric',
        ], [
            'title.required'       => 'El nombre del dispositivo es obligatorio.',
            'subtitle.required'    => 'La ubicación o descripción es obligatoria.',
            'device_type.required' => 'Selecciona el tipo de dispositivo.',
            'device_type.in'       => 'Tipo de dispositivo no válido.',
        ]);

        $cameraError = $this->validateCameraSource($validated);
        if ($cameraError !== null) {
            return $cameraError;
        }

        $validated['status'] = $validated['status'] ?? 'Activo';
        $validated['is_ptz'] = (bool) ($validated['is_ptz'] ?? false);

        $device = Device::create($validated);

        return response()->json([
            'message' => 'Dispositivo registrado correctamente',
            'device'  => $device,
        ], 201);
    }

    private function validateCameraSource(array $validated)
    {
        if (($validated['device_type'] ?? '') !== 'camera') {
            return null;
        }

        $stream = trim((string) ($validated['stream_url'] ?? ''));
        if ($stream === '') {
            return response()->json([
                'message' => 'Una cámara necesita una fuente de video (cámara de este dispositivo o URL de stream).',
                'errors'  => [
                    'stream_url' => ['La fuente de video es obligatoria para una cámara.'],
                ],
            ], 422);
        }

        $isLocal = str_starts_with($stream, 'local://');
        if ($isLocal) {
            return null;
        }

        if (!preg_match('/^(rtsp|rtsps|http|https):\\/\\//i', $stream)) {
            return response()->json([
                'message' => 'La URL del stream debe comenzar por rtsp://, http:// o https://.',
                'errors'  => [
                    'stream_url' => ['URL de stream no válida.'],
                ],
            ], 422);
        }

        if (trim((string) ($validated['ip_address'] ?? '')) === '') {
            return response()->json([
                'message' => 'La dirección IP es obligatoria para una cámara de red.',
                'errors'  => [
                    'ip_address' => ['Ingresa la IP o host de la cámara.'],
                ],
            ], 422);
        }

        return null;
    }

    // ── PUT /devices/{id} ─────────────────────────────────────────
    public function update(Request $request, $id)
    {
        $device = Device::findOrFail($id);

        $validated = $request->validate([
            'title'       => 'sometimes|required|string|max:100',
            'subtitle'    => 'nullable|string|max:200',
            'status'      => 'nullable|in:Activo,Inactivo,Mantenimiento',
            'imageUrl'    => 'nullable|string|max:500',
            'stream_url'  => 'nullable|string|max:500',
            'ip_address'  => 'nullable|string|max:100',
            'port'        => 'nullable|integer|between:1,65535',
            'is_ptz'      => 'nullable|boolean',
            'device_type' => 'nullable|string|max:50',
            'latitude'    => 'nullable|numeric',
            'longitude'   => 'nullable|numeric',
        ]);

        $device->update($validated);

        return response()->json([
            'message' => 'Dispositivo actualizado correctamente',
            'device'  => $device,
        ]);
    }

    // ── POST /devices/{id}/ptz ────────────────────────────────────
    public function ptz(Request $request, $id)
    {
        $device = Device::findOrFail($id);

        $validated = $request->validate([
            'command' => 'required|string|in:up,down,left,right,zoom_in,zoom_out,stop',
            'speed'   => 'nullable|integer|between:1,10',
        ]);

        $command = $validated['command'];
        $speed = $validated['speed'] ?? 5;

        \Log::info("Comando PTZ ejecutado en dispositivo #{$device->id} ({$device->title}): {$command} a velocidad {$speed}");

        return response()->json([
            'message'   => "Comando PTZ '{$command}' ejecutado correctamente",
            'device_id' => $device->id,
            'command'   => $command,
            'speed'     => $speed,
            'timestamp' => now()->toIso8601String(),
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

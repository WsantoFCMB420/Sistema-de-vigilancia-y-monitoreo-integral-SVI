<?php

namespace App\Http\Controllers;

use App\Models\Alert;
use Illuminate\Http\Request;

class AlertController extends Controller
{
    // ── GET /alerts ────────────────────────────────────────────────
    public function index()
    {
        $alerts = Alert::with(['user:id,name', 'device:id,title', 'attendedUser:id,name'])
            ->latest()
            ->get()
            ->map(function ($a) {
                return [
                    'id'               => $a->id,
                    'type'             => $a->type,
                    'priority'         => $a->priority,
                    'location'         => $a->location,
                    'description'      => $a->description,
                    'status'           => $a->status ?? 'Pendiente',
                    'device_id'        => $a->device_id,
                    'device_name'      => optional($a->device)->title,
                    'latitude'         => $a->latitude,
                    'longitude'        => $a->longitude,
                    'user_name'        => optional($a->user)->name ?? 'Sistema',
                    'attended_by'      => $a->attended_by,
                    'attended_by_name' => optional($a->attendedUser)->name,
                    'resolved_at'      => optional($a->resolved_at)?->toIso8601String(),
                    'created_at'       => $a->created_at->diffForHumans(),
                    'raw_date'         => $a->created_at->toISOString(),
                ];
            });

        return response()->json($alerts);
    }

    // ── POST /alerts ───────────────────────────────────────────────
    public function store(Request $request)
    {
        $request->validate([
            'type'        => 'required|string|max:50',
            'priority'    => 'required|string|in:Baja,Media,Crítica',
            'location'    => 'nullable|string|max:200',
            'description' => 'nullable|string|max:500',
            'device_id'   => 'nullable|exists:devices,id',
            'status'      => 'nullable|string|in:Pendiente,En atención,Resuelta,Falsa Alarma',
            'latitude'    => 'nullable|numeric',
            'longitude'   => 'nullable|numeric',
        ]);

        $alert = $request->user()->alerts()->create([
            'type'        => $request->type,
            'priority'    => $request->priority,
            'location'    => $request->location ?? '',
            'description' => $request->description ?? '',
            'device_id'   => $request->device_id,
            'status'      => $request->status ?? 'Pendiente',
            'latitude'    => $request->latitude,
            'longitude'   => $request->longitude,
        ]);

        $alert->load(['user:id,name', 'device:id,title']);

        return response()->json([
            'message' => 'Alerta emitida correctamente',
            'alert'   => [
                'id'               => $alert->id,
                'type'             => $alert->type,
                'priority'         => $alert->priority,
                'location'         => $alert->location,
                'description'      => $alert->description,
                'status'           => $alert->status,
                'device_id'        => $alert->device_id,
                'device_name'      => optional($alert->device)->title,
                'latitude'         => $alert->latitude,
                'longitude'        => $alert->longitude,
                'user_name'        => $request->user()->name,
                'created_at'       => $alert->created_at->diffForHumans(),
                'raw_date'         => $alert->created_at->toISOString(),
            ],
        ], 201);
    }

    // ── PUT /alerts/{id} ──────────────────────────────────────────
    public function update(Request $request, $id)
    {
        $alert = Alert::findOrFail($id);

        $request->validate([
            'type'        => 'sometimes|required|string|max:50',
            'priority'    => 'sometimes|required|in:Baja,Media,Crítica',
            'location'    => 'nullable|string|max:200',
            'description' => 'nullable|string|max:500',
            'device_id'   => 'nullable|exists:devices,id',
            'status'      => 'nullable|in:Pendiente,En atención,Resuelta,Falsa Alarma',
            'latitude'    => 'nullable|numeric',
            'longitude'   => 'nullable|numeric',
        ]);

        $data = $request->only(['type', 'priority', 'location', 'description', 'device_id', 'status', 'latitude', 'longitude']);
        if ($request->has('status')) {
            if ($request->status === 'Resuelta' || $request->status === 'Falsa Alarma') {
                $data['resolved_at'] = now();
            }
            if ($request->status === 'En atención' && !$alert->attended_by) {
                $data['attended_by'] = $request->user()->id;
            }
        }

        $alert->update($data);

        $alert->load(['user:id,name', 'device:id,title', 'attendedUser:id,name']);

        return response()->json([
            'message' => 'Alerta actualizada',
            'alert'   => [
                'id'               => $alert->id,
                'type'             => $alert->type,
                'priority'         => $alert->priority,
                'location'         => $alert->location,
                'description'      => $alert->description,
                'status'           => $alert->status,
                'device_id'        => $alert->device_id,
                'device_name'      => optional($alert->device)->title,
                'latitude'         => $alert->latitude,
                'longitude'        => $alert->longitude,
                'user_name'        => optional($alert->user)->name ?? 'Sistema',
                'attended_by'      => $alert->attended_by,
                'attended_by_name' => optional($alert->attendedUser)->name,
                'resolved_at'      => optional($alert->resolved_at)?->toIso8601String(),
            ],
        ]);
    }

    // ── PATCH /alerts/{id}/status ──────────────────────────────────
    public function updateStatus(Request $request, $id)
    {
        $alert = Alert::findOrFail($id);

        $validated = $request->validate([
            'status' => 'required|string|in:Pendiente,En atención,Resuelta,Falsa Alarma',
        ]);

        $status = $validated['status'];
        $alert->status = $status;
        $alert->attended_by = $request->user()->id;

        if (in_array($status, ['Resuelta', 'Falsa Alarma'])) {
            $alert->resolved_at = now();
        }

        $alert->save();
        $alert->load(['user:id,name', 'device:id,title', 'attendedUser:id,name']);

        return response()->json([
            'message' => "Estado de alerta actualizado a '{$status}'",
            'alert'   => [
                'id'               => $alert->id,
                'type'             => $alert->type,
                'priority'         => $alert->priority,
                'location'         => $alert->location,
                'description'      => $alert->description,
                'status'           => $alert->status,
                'device_id'        => $alert->device_id,
                'device_name'      => optional($alert->device)->title,
                'latitude'         => $alert->latitude,
                'longitude'        => $alert->longitude,
                'user_name'        => optional($alert->user)->name ?? 'Sistema',
                'attended_by'      => $alert->attended_by,
                'attended_by_name' => optional($alert->attendedUser)->name,
                'resolved_at'      => optional($alert->resolved_at)?->toIso8601String(),
            ],
        ]);
    }

    // ── DELETE /alerts/{id} ───────────────────────────────────────
    public function destroy($id)
    {
        $alert = Alert::findOrFail($id);
        $alert->delete();

        return response()->json(['message' => 'Alerta eliminada']);
    }
}

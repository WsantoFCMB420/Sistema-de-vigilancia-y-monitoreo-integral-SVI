<?php

namespace App\Http\Controllers;

use App\Models\Alert;
use Illuminate\Http\Request;

class AlertController extends Controller
{
    // ── GET /alerts ────────────────────────────────────────────────
    public function index()
    {
        $alerts = Alert::with('user:id,name')
            ->latest()
            ->get()
            ->map(function ($a) {
                return [
                    'id'          => $a->id,
                    'type'        => $a->type,
                    'priority'    => $a->priority,
                    'location'    => $a->location,
                    'description' => $a->description,
                    'user_name'   => optional($a->user)->name ?? 'Sistema',
                    'created_at'  => $a->created_at->diffForHumans(),
                    'raw_date'    => $a->created_at->toISOString(),
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
        ]);

        $alert = $request->user()->alerts()->create([
            'type'        => $request->type,
            'priority'    => $request->priority,
            'location'    => $request->location ?? '',
            'description' => $request->description ?? '',
        ]);

        return response()->json([
            'message' => 'Alerta emitida correctamente',
            'alert'   => [
                'id'          => $alert->id,
                'type'        => $alert->type,
                'priority'    => $alert->priority,
                'location'    => $alert->location,
                'description' => $alert->description,
                'user_name'   => $request->user()->name,
                'created_at'  => $alert->created_at->diffForHumans(),
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
        ]);

        $alert->update($request->only(['type', 'priority', 'location', 'description']));

        return response()->json([
            'message' => 'Alerta actualizada',
            'alert'   => $alert->load('user:id,name'),
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

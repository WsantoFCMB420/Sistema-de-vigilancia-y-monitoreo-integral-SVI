<?php

namespace App\Http\Controllers;

use App\Models\Alert;
use App\Models\Device;

class ReportController extends Controller
{
    public function index()
    {
        // ── Contadores generales ─────────────────────────────────
        $totalDevices    = Device::count();
        $activeDevices   = Device::where('status', 'Activo')->count();
        $totalAlerts     = Alert::count();
        $criticalAlerts  = Alert::where('priority', 'Crítica')->count();

        // ── Incidentes por tipo ───────────────────────────────────
        $byType = Alert::selectRaw('type, COUNT(*) as total')
            ->groupBy('type')
            ->get()
            ->mapWithKeys(fn($r) => [$r->type => (int) $r->total]);

        // ── Incidentes por prioridad ──────────────────────────────
        $byPriority = Alert::selectRaw('priority, COUNT(*) as total')
            ->groupBy('priority')
            ->get()
            ->mapWithKeys(fn($r) => [$r->priority => (int) $r->total]);

        // ── Incidentes últimos 7 días (uno por día) ───────────────
        $last7Days = [];
        for ($i = 6; $i >= 0; $i--) {
            $date  = now()->subDays($i);
            $count = Alert::whereDate('created_at', $date->toDateString())->count();
            $last7Days[] = [
                'label' => strtoupper(mb_substr($date->locale('es')->dayName, 0, 3)),
                'count' => $count,
                'date'  => $date->toDateString(),
            ];
        }

        // ── Dispositivos por estado ───────────────────────────────
        $devicesByStatus = Device::selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->get()
            ->mapWithKeys(fn($r) => [$r->status => (int) $r->total]);

        // ── Tiempo promedio de respuesta simulado ─────────────────
        // (En producción vendría de un campo resolved_at en alerts)
        $avgResponseMinutes = $totalAlerts > 0 ? 2.4 : 0;

        // ── Alertas recientes ─────────────────────────────────────
        $recentAlerts = Alert::with('user:id,name')
            ->latest()
            ->limit(10)
            ->get()
            ->map(fn($a) => [
                'id'         => $a->id,
                'type'       => $a->type,
                'priority'   => $a->priority,
                'location'   => $a->location,
                'user_name'  => optional($a->user)->name ?? 'Sistema',
                'created_at' => $a->created_at->diffForHumans(),
            ]);

        return response()->json([
            'summary' => [
                'total_incidents'       => $totalAlerts,
                'critical_incidents'    => $criticalAlerts,
                'total_devices'         => $totalDevices,
                'active_devices'        => $activeDevices,
                'avg_response_minutes'  => $avgResponseMinutes,
                'ai_accuracy_pct'       => 99.2,
            ],
            'by_type'          => $byType,
            'by_priority'      => $byPriority,
            'last_7_days'      => $last7Days,
            'devices_by_status'=> $devicesByStatus,
            'recent_alerts'    => $recentAlerts,
        ]);
    }
}

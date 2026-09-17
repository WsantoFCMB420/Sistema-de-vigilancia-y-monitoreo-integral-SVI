<?php

namespace App\Http\Controllers;

use App\Models\Alert;
use App\Models\Device;

class DashboardController extends Controller
{
    public function index()
    {
        $totalDevices    = Device::count();
        $activeDevices   = Device::where('status', 'Activo')->count();
        $inactiveDevices = $totalDevices - $activeDevices;

        $totalAlerts    = Alert::count();
        $criticalAlerts = Alert::where('priority', 'Crítica')->count();

        // Últimas 5 alertas
        $recentAlerts = Alert::with('user:id,name')
            ->latest()
            ->limit(5)
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
                ];
            });

        return response()->json([
            'total_devices'    => $totalDevices,
            'active_devices'   => $activeDevices,
            'inactive_devices' => $inactiveDevices,
            'total_alerts'     => $totalAlerts,
            'critical_alerts'  => $criticalAlerts,
            'recent_alerts'    => $recentAlerts,
        ]);
    }
}
<?php

namespace App\Http\Controllers;

use App\Models\Alert;
use App\Models\Device;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $deviceQuery = Device::query();
        if ($user->role !== 'admin') {
            $deviceQuery->where('user_id', $user->id);
        }

        $totalDevices    = (clone $deviceQuery)->count();
        $activeDevices   = (clone $deviceQuery)->where('status', 'Activo')->count();
        $inactiveDevices = $totalDevices - $activeDevices;

        $totalAlerts    = Alert::whereIn('status', ['Pendiente', 'En atención'])->count();
        $criticalAlerts = Alert::where('priority', 'Crítica')->whereIn('status', ['Pendiente', 'En atención'])->count();

        // Últimas 5 alertas activas
        $recentAlerts = Alert::with('user:id,name')
            ->whereIn('status', ['Pendiente', 'En atención'])
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
                    'status'      => $a->status ?? 'Pendiente',
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

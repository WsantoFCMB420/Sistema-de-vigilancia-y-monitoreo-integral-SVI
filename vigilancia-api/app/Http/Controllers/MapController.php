<?php

namespace App\Http\Controllers;

use App\Models\Device;
use App\Models\Alert;
use Illuminate\Http\Request;

class MapController extends Controller
{
    public function nodes(Request $request)
    {
        $user = $request->user();

        // Dispositivos: el admin ve todos, los demás solo los que registraron.
        $deviceQuery = Device::select(
                'id', 'user_id', 'title', 'subtitle', 'latitude', 'longitude',
                'status', 'stream_url', 'ip_address', 'is_ptz', 'device_type'
            )
            ->whereNotNull('latitude')
            ->whereNotNull('longitude');

        if ($user->role !== 'admin') {
            $deviceQuery->where('user_id', $user->id);
        }

        $devices = $deviceQuery->get()->map(fn($d) => [
            'id'          => $d->id,
            'label'       => $d->title,
            'type'        => 'device',
            'device_type' => $d->device_type ?? 'camera',
            'description' => $d->subtitle ?? '',
            'lat'         => $d->latitude,
            'lng'         => $d->longitude,
            'status'      => $d->status ?? 'Activo',
            'isAlert'     => false,
            'stream_url'  => $d->stream_url ?? '',
            'ip_address'  => $d->ip_address ?? '',
            'is_ptz'      => (bool) $d->is_ptz,
        ]);

        // Alertas: activas, o cerradas durante la última hora.
        $oneHourAgo = now()->subHour();

        $alerts = Alert::with(['device:id,title,latitude,longitude', 'user:id,name'])
            ->where(function ($query) use ($oneHourAgo) {
                $query->whereIn('status', ['Pendiente', 'En atención'])
                      ->orWhere(function ($q) use ($oneHourAgo) {
                          $q->whereIn('status', ['Resuelta', 'Falsa Alarma'])
                            ->where(function ($sub) use ($oneHourAgo) {
                                $sub->where('resolved_at', '>=', $oneHourAgo)
                                    ->orWhere('updated_at', '>=', $oneHourAgo);
                            });
                      });
            })
            ->latest()
            ->get()
            ->map(function ($a) {
                $lat = $a->latitude ?? optional($a->device)->latitude;
                $lng = $a->longitude ?? optional($a->device)->longitude;
                return [
                    'id'          => $a->id,
                    'label'       => $a->type,
                    'type'        => 'alert',
                    'lat'         => $lat,
                    'lng'         => $lng,
                    'status'      => $a->status ?? 'Pendiente',
                    'priority'    => $a->priority ?? 'Media',
                    'description' => $a->description ?? '',
                    'location'    => $a->location ?? '',
                    'device_name' => optional($a->device)->title,
                    'user_name'   => optional($a->user)->name ?? 'Sistema',
                    'is_mine'     => (int) $a->user_id === (int) request()->user()->id,
                    'created_at'  => optional($a->created_at)
                        ?->copy()->setTimezone('America/Bogota')->format('d/m/Y h:i a'),
                    'isAlert'     => true,
                ];
            })
            ->filter(fn($item) => !is_null($item['lat']) && !is_null($item['lng']))
            ->values();

        return response()->json($devices->concat($alerts)->values());
    }
}

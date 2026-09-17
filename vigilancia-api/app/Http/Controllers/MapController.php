<?php

namespace App\Http\Controllers;

use App\Models\Device;
use App\Models\Alert;

class MapController extends Controller
{
    public function nodes()
    {
        $devices = Device::select('id', 'title', 'latitude', 'longitude', 'status')
            ->whereNotNull('latitude')
            ->get()
            ->map(fn($d) => [
                'id'      => $d->id,
                'label'   => $d->title,
                'type'    => 'device',
                'lat'     => $d->latitude,
                'lng'     => $d->longitude,
                'isAlert' => $d->status !== 'Activo',
            ]);

        $alerts = Alert::select('id', 'type', 'latitude', 'longitude')
            ->whereNotNull('latitude')
            ->get()
            ->map(fn($a) => [
                'id'      => $a->id,
                'label'   => $a->type,
                'type'    => 'alert',
                'lat'     => $a->latitude,
                'lng'     => $a->longitude,
                'isAlert' => true,
            ]);

        return response()->json($devices->concat($alerts));
    }
}

<?php

namespace App\Http\Controllers;

use App\Models\Message;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    /** Zona horaria de presentación: Bogotá, Colombia (UTC-5, sin horario de verano). */
    private const TZ = 'America/Bogota';

    public function index()
    {
        return Message::with('user:id,name,role')
            ->latest()
            ->take(50)
            ->get()
            ->reverse()
            ->values()
            ->map(fn(Message $m) => $this->present($m));
    }

    public function store(Request $request)
    {
        $request->validate(['text' => 'required|string|max:500']);

        $message = $request->user()->messages()->create([
            'text' => $request->text,
        ]);

        return response()->json([
            'message' => 'Mensaje enviado',
            'data'    => $this->present($message->load('user:id,name,role')),
        ], 201);
    }

    /**
     * Las fechas se guardan en UTC. Aquí se envían ya convertidas a la hora
     * de Bogotá para que web y móvil muestren lo mismo sin depender de la
     * zona horaria del navegador o del celular.
     */
    private function present(Message $m): array
    {
        $local = $m->created_at?->copy()->setTimezone(self::TZ);

        return [
            'id'         => $m->id,
            'user_id'    => $m->user_id,
            'text'       => $m->text,
            'user'       => $m->user ? [
                'id'   => $m->user->id,
                'name' => $m->user->name,
                'role' => $m->user->role,
            ] : null,
            'created_at' => $m->created_at?->toIso8601ZuluString(),
            'local_date' => $local?->format('Y-m-d'),
            'local_time' => $local?->format('H:i'),
        ];
    }
}

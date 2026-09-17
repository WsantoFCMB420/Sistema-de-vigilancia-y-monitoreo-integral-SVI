<?php

namespace App\Http\Controllers;

use App\Models\Message;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function index()
    {
        return Message::with('user:id,name')
            ->latest()
            ->take(50)
            ->get()
            ->reverse()
            ->values();
    }

    public function store(Request $request)
    {
        $request->validate(['text' => 'required|string|max:500']);

        $message = $request->user()->messages()->create([
            'text' => $request->text,
        ]);

        return response()->json([
            'message'   => 'Mensaje enviado',
            'data'      => $message->load('user:id,name'),
        ], 201);
    }
}

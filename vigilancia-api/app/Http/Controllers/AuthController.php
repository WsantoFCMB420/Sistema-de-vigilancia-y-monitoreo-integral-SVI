<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // ── POST /register ────────────────────────────────────────────
    public function register(Request $request)
    {
        $request->validate([
            'name'         => 'required|string|max:100',
            'email'        => 'required|email|unique:users',
            'password'     => 'required|min:6',
            'accept_terms' => 'required|accepted',
        ]);

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Usuario registrado correctamente',
            'token'   => $token,
            'user'    => $user->only('id', 'name', 'email', 'role'),
        ], 201);
    }

    // ── POST /login ───────────────────────────────────────────────
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['error' => 'Credenciales incorrectas'], 401);
        }

        // No revocar sesiones de otros dispositivos: si se borran todos los
        // tokens, la app móvil queda en el dashboard con un token muerto.
        $user->tokens()
            ->where(function ($query) {
                $query->where('last_used_at', '<', now()->subDays(30))
                    ->orWhere(function ($stale) {
                        $stale->whereNull('last_used_at')
                            ->where('created_at', '<', now()->subDays(30));
                    });
            })
            ->delete();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login exitoso',
            'token'   => $token,
            'user'    => $user->only('id', 'name', 'email', 'role'),
        ]);
    }

    // ── POST /logout ──────────────────────────────────────────────
    public function logout(Request $request)
    {
        // Revocar solo el token actual
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Sesión cerrada correctamente']);
    }

    // ── POST /forgot-password ─────────────────────────────────────
    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        // Respuesta genérica por seguridad (no revelar si el correo existe)
        if (!$user) {
            return response()->json([
                'message' => 'Si el correo está registrado, recibirás un enlace de recuperación.',
            ]);
        }

        // TODO: En producción, enviar email con enlace firmado
        return response()->json([
            'message' => 'Se ha enviado un enlace de recuperación a tu correo.',
        ]);
    }
}
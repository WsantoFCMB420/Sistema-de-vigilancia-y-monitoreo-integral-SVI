<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    // ── GET /users (solo admin) ───────────────────────────────────
    public function index()
    {
        $users = User::select('id', 'name', 'email', 'role', 'phone', 'avatar', 'created_at')
            ->latest()
            ->get()
            ->map(fn($u) => [
                'id'         => $u->id,
                'name'       => $u->name,
                'email'      => $u->email,
                'role'       => $u->role,
                'phone'      => $u->phone,
                'avatar'     => $u->avatar,
                'created_at' => $u->created_at->diffForHumans(),
            ]);

        return response()->json($users);
    }

    // ── PUT /users/{id}/role (solo admin) ─────────────────────────
    public function updateRole(Request $request, int $id)
    {
        $request->validate([
            'role' => ['required', Rule::in(['admin', 'operator', 'viewer'])],
        ]);

        $user = User::findOrFail($id);

        // Evitar que el admin se degrade a sí mismo
        if ($user->id === $request->user()->id) {
            return response()->json(['error' => 'No puedes cambiar tu propio rol'], 422);
        }

        $user->update(['role' => $request->role]);

        return response()->json([
            'message' => 'Rol actualizado correctamente',
            'user'    => $user->only('id', 'name', 'email', 'role'),
        ]);
    }

    // ── DELETE /users/{id} (solo admin) ──────────────────────────
    public function destroy(Request $request, int $id)
    {
        $user = User::findOrFail($id);

        if ($user->id === $request->user()->id) {
            return response()->json(['error' => 'No puedes eliminar tu propia cuenta'], 422);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json(['message' => 'Usuario eliminado correctamente']);
    }

    // ── GET /profile ──────────────────────────────────────────────
    public function profile(Request $request)
    {
        $user = $request->user();
        return response()->json([
            'id'     => $user->id,
            'name'   => $user->name,
            'email'  => $user->email,
            'role'   => $user->role,
            'phone'  => $user->phone,
            'avatar' => $user->avatar,
        ]);
    }

    // ── PUT /profile ──────────────────────────────────────────────
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'name'     => 'sometimes|string|max:100',
            'phone'    => 'sometimes|nullable|string|max:20',
            'avatar'   => 'sometimes|nullable|string|max:500',
            'password' => 'sometimes|min:6|confirmed',
        ]);

        $data = $request->only(['name', 'phone', 'avatar']);

        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $user->update($data);

        return response()->json([
            'message' => 'Perfil actualizado correctamente',
            'user'    => $user->only('id', 'name', 'email', 'role', 'phone', 'avatar'),
        ]);
    }
}

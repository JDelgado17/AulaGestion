<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string', 'min:8'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::where('email', mb_strtolower($credentials['email']))->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            return $this->error('El correo o la contraseña son incorrectos.', 401);
        }

        if (! $user->is_active) {
            return $this->error('Tu cuenta está deshabilitada. Contacta al administrador.', 403);
        }

        $user->tokens()->where('name', $credentials['device_name'] ?? 'flutter-app')->delete();
        $token = $user->createToken(
            $credentials['device_name'] ?? 'flutter-app',
            ["role:{$user->role}"],
            now()->addHours(12),
        )->plainTextToken;

        return $this->success([
            'token' => $token,
            'token_type' => 'Bearer',
            'expires_at' => now()->addHours(12)->toIso8601String(),
            'user' => $user,
        ], 'Bienvenido a AulaGestión.');
    }

    public function me(Request $request)
    {
        return $this->success($request->user());
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->success(null, 'Sesión cerrada correctamente.');
    }
}

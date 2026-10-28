<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $users = User::query()
            ->when($request->filled('search'), fn ($query) => $query->where(fn ($inner) => $inner
                ->where('name', 'like', '%'.$request->string('search').'%')
                ->orWhere('email', 'like', '%'.$request->string('search').'%')))
            ->when($request->filled('role'), fn ($query) => $query->where('role', $request->string('role')))
            ->orderBy('name')
            ->paginate(20);

        return $this->success($users);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:160', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'role' => ['required', Rule::in(['admin', 'professor', 'inventory'])],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $data['email'] = mb_strtolower($data['email']);
        $user = User::create($data);

        return $this->success($user, 'Usuario creado correctamente.', 201);
    }

    public function show(User $user)
    {
        return $this->success($user);
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:120'],
            'email' => ['sometimes', 'required', 'email', 'max:160', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
            'role' => ['sometimes', 'required', Rule::in(['admin', 'professor', 'inventory'])],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if (isset($data['email'])) {
            $data['email'] = mb_strtolower($data['email']);
        }
        if (empty($data['password'])) {
            unset($data['password']);
        }

        $user->update($data);

        if (! $user->is_active) {
            $user->tokens()->delete();
        }

        return $this->success($user->fresh(), 'Usuario actualizado correctamente.');
    }

    public function destroy(Request $request, User $user)
    {
        if ($request->user()->is($user)) {
            return $this->error('No puedes deshabilitar tu propia cuenta.', 422);
        }

        $user->update(['is_active' => false]);
        $user->tokens()->delete();

        return $this->success($user, 'Usuario deshabilitado correctamente.');
    }
}

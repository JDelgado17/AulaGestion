<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_active_user_can_login_and_receives_role(): void
    {
        User::create([
            'name' => 'Profesora Prueba',
            'email' => 'profe@demo.edu.co',
            'password' => 'ClaveSegura1*',
            'role' => 'professor',
            'is_active' => true,
        ]);

        $this->postJson('/api/auth/login', [
            'email' => 'profe@demo.edu.co',
            'password' => 'ClaveSegura1*',
            'device_name' => 'phpunit',
        ])->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.role', 'professor')
            ->assertJsonStructure(['data' => ['token', 'user']]);
    }

    public function test_disabled_user_cannot_login(): void
    {
        User::create([
            'name' => 'Usuario Inactivo',
            'email' => 'inactivo@demo.edu.co',
            'password' => 'ClaveSegura1*',
            'role' => 'professor',
            'is_active' => false,
        ]);

        $this->postJson('/api/auth/login', [
            'email' => 'inactivo@demo.edu.co',
            'password' => 'ClaveSegura1*',
        ])->assertForbidden();
    }
}


<?php

namespace Database\Seeders;

use App\Models\AppNotification;
use App\Models\Classroom;
use App\Models\ClassroomSchedule;
use App\Models\InventoryItem;
use App\Models\Reservation;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::create([
            'name' => 'Administrador Demo',
            'email' => 'admin@demo.edu.co',
            'password' => Hash::make('Demo2026*'),
            'role' => 'admin',
            'is_active' => true,
        ]);

        $professor = User::create([
            'name' => 'Profesor Demo',
            'email' => 'profesor@demo.edu.co',
            'password' => Hash::make('Demo2026*'),
            'role' => 'professor',
            'is_active' => true,
        ]);

        $inventoryUser = User::create([
            'name' => 'Encargado de Inventario',
            'email' => 'inventario@demo.edu.co',
            'password' => Hash::make('Demo2026*'),
            'role' => 'inventory',
            'is_active' => true,
        ]);

        $rooms = collect([
            ['code' => 'A-101', 'name' => 'Aula Interactiva', 'location' => 'Bloque A · Piso 1', 'capacity' => 30, 'type' => 'Clase interactiva', 'description' => 'Espacio flexible para clases y talleres.', 'status' => 'available'],
            ['code' => 'A-204', 'name' => 'Aula Multimedia', 'location' => 'Bloque A · Piso 2', 'capacity' => 35, 'type' => 'Multimedia', 'description' => 'Aula con recursos audiovisuales.', 'status' => 'available'],
            ['code' => 'B-301', 'name' => 'Sala de Informática', 'location' => 'Bloque B · Piso 3', 'capacity' => 25, 'type' => 'Informática', 'description' => 'Sala para actividades con computadores.', 'status' => 'available'],
            ['code' => 'C-102', 'name' => 'Aula Lúdica', 'location' => 'Bloque C · Piso 1', 'capacity' => 40, 'type' => 'Actividad lúdica', 'description' => 'Mobiliario móvil y amplio espacio.', 'status' => 'available'],
            ['code' => 'LAB-01', 'name' => 'Laboratorio de Ciencias', 'location' => 'Bloque B · Piso 1', 'capacity' => 24, 'type' => 'Laboratorio', 'description' => 'Mesones y elementos básicos de laboratorio.', 'status' => 'maintenance'],
        ])->map(fn (array $room) => Classroom::create([...$room, 'is_active' => true]));

        $inventory = [
            'A-101' => [['Videobeam', 'Tecnología', 1], ['Televisor', 'Tecnología', 1], ['Tablero acrílico', 'Mobiliario', 1], ['Parlantes', 'Tecnología', 2]],
            'A-204' => [['Videobeam', 'Tecnología', 1], ['Tablero acrílico', 'Mobiliario', 1], ['Parlantes', 'Tecnología', 2]],
            'B-301' => [['Computador', 'Tecnología', 25], ['Videobeam', 'Tecnología', 1], ['Aire acondicionado', 'Infraestructura', 1]],
            'C-102' => [['Televisor', 'Tecnología', 1], ['Tablero móvil', 'Mobiliario', 2], ['Parlantes', 'Tecnología', 1]],
            'LAB-01' => [['Microscopio', 'Laboratorio', 10], ['Videobeam', 'Tecnología', 1], ['Kit de seguridad', 'Seguridad', 6]],
        ];

        foreach ($rooms as $room) {
            foreach ($inventory[$room->code] as [$name, $category, $quantity]) {
                InventoryItem::create([
                    'classroom_id' => $room->id,
                    'name' => $name,
                    'category' => $category,
                    'quantity' => $quantity,
                    'available_quantity' => $room->status === 'maintenance' ? 0 : $quantity,
                    'status' => $room->status === 'maintenance' ? 'maintenance' : 'available',
                    'description' => 'Elemento registrado en el inventario inicial.',
                ]);
            }

            foreach (range(1, 6) as $weekday) {
                ClassroomSchedule::create([
                    'classroom_id' => $room->id,
                    'weekday' => $weekday,
                    'start_time' => '07:00',
                    'end_time' => '19:00',
                    'is_active' => true,
                ]);
            }
        }

        $nextWeekday = Carbon::now()->next(Carbon::MONDAY)->setTime(8, 0);
        $reservation = Reservation::create([
            'user_id' => $professor->id,
            'classroom_id' => $rooms->firstWhere('code', 'A-204')->id,
            'starts_at' => $nextWeekday,
            'ends_at' => $nextWeekday->copy()->addHours(2),
            'attendees' => 28,
            'activity_type' => 'Clase',
            'required_resources' => ['Videobeam'],
            'optional_resources' => ['Parlantes'],
            'purpose' => 'Clase demostrativa de ciencias sociales',
            'status' => 'confirmed',
        ]);

        AppNotification::create([
            'user_id' => $professor->id,
            'title' => 'Reserva confirmada',
            'message' => "Tu reserva {$reservation->id} en A-204 está confirmada.",
            'type' => 'reservation_confirmed',
            'metadata' => ['reservation_id' => $reservation->id],
        ]);

        AppNotification::create([
            'user_id' => $inventoryUser->id,
            'title' => 'Inventario por revisar',
            'message' => 'El laboratorio LAB-01 se encuentra en mantenimiento.',
            'type' => 'inventory_alert',
            'metadata' => ['classroom_code' => 'LAB-01'],
        ]);

        AppNotification::create([
            'user_id' => $admin->id,
            'title' => 'Sistema configurado',
            'message' => 'Los datos iniciales de AulaGestión fueron creados correctamente.',
            'type' => 'system',
        ]);
    }
}

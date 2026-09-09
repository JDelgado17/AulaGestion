<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Classroom;
use App\Services\AuditService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ClassroomController extends Controller
{
    public function __construct(private readonly AuditService $audit) {}

    public function index(Request $request)
    {
        $rooms = Classroom::query()
            ->withCount(['inventoryItems', 'reservations' => fn ($query) => $query->where('status', 'confirmed')])
            ->when($request->filled('search'), fn ($query) => $query->where(fn ($inner) => $inner
                ->where('code', 'like', '%'.$request->string('search').'%')
                ->orWhere('name', 'like', '%'.$request->string('search').'%')
                ->orWhere('location', 'like', '%'.$request->string('search').'%')))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->when($request->boolean('active_only'), fn ($query) => $query->where('is_active', true))
            ->orderBy('code')
            ->paginate(30);

        return $this->success($rooms);
    }

    public function store(Request $request)
    {
        $classroom = Classroom::create($this->validated($request));
        $this->audit->record($request, 'classroom.created', $classroom, null, $classroom->toArray());

        return $this->success($classroom, 'Aula registrada correctamente.', 201);
    }

    public function show(Classroom $classroom)
    {
        return $this->success($classroom->load([
            'inventoryItems' => fn ($query) => $query->orderBy('name'),
            'schedules' => fn ($query) => $query->orderBy('weekday')->orderBy('start_time'),
        ]));
    }

    public function update(Request $request, Classroom $classroom)
    {
        $before = $classroom->toArray();
        $classroom->update($this->validated($request, $classroom));
        $this->audit->record($request, 'classroom.updated', $classroom, $before, $classroom->fresh()->toArray());

        return $this->success($classroom->fresh(), 'Aula actualizada correctamente.');
    }

    public function destroy(Request $request, Classroom $classroom)
    {
        $before = $classroom->toArray();
        $classroom->update(['is_active' => false]);
        $this->audit->record($request, 'classroom.disabled', $classroom, $before, $classroom->fresh()->toArray());

        return $this->success($classroom, 'Aula deshabilitada sin eliminar su historial.');
    }

    private function validated(Request $request, ?Classroom $classroom = null): array
    {
        return $request->validate([
            'code' => ['required', 'string', 'max:30', Rule::unique('classrooms', 'code')->ignore($classroom?->id)],
            'name' => ['required', 'string', 'max:120'],
            'location' => ['required', 'string', 'max:160'],
            'capacity' => ['required', 'integer', 'min:1', 'max:1000'],
            'type' => ['required', 'string', 'max:60'],
            'description' => ['nullable', 'string', 'max:1000'],
            'status' => ['required', Rule::in(['available', 'maintenance', 'out_of_service'])],
            'is_active' => ['sometimes', 'boolean'],
        ]);
    }
}


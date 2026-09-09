<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Classroom;
use App\Models\InventoryEvent;
use App\Models\InventoryItem;
use App\Services\AuditService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class InventoryController extends Controller
{
    public function __construct(private readonly AuditService $audit) {}

    public function index(Request $request)
    {
        $items = InventoryItem::query()
            ->with('classroom:id,code,name,location')
            ->when($request->filled('classroom_id'), fn ($query) => $query->where('classroom_id', $request->integer('classroom_id')))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->when($request->filled('search'), fn ($query) => $query->where('name', 'like', '%'.$request->string('search').'%'))
            ->orderBy('classroom_id')
            ->orderBy('name')
            ->paginate(30);

        return $this->success($items);
    }

    public function store(Request $request)
    {
        $data = $this->validatedItem($request);
        $item = InventoryItem::create($data);
        $this->audit->record($request, 'inventory.created', $item, null, $item->toArray());

        return $this->success($item->load('classroom:id,code,name'), 'Elemento registrado correctamente.', 201);
    }

    public function show(InventoryItem $inventoryItem)
    {
        return $this->success($inventoryItem->load(['classroom', 'events.user:id,name']));
    }

    public function update(Request $request, InventoryItem $inventoryItem)
    {
        $before = $inventoryItem->toArray();
        $inventoryItem->update($this->validatedItem($request, $inventoryItem));
        $this->audit->record($request, 'inventory.updated', $inventoryItem, $before, $inventoryItem->fresh()->toArray());

        return $this->success($inventoryItem->fresh()->load('classroom:id,code,name'), 'Inventario actualizado correctamente.');
    }

    public function events(Request $request)
    {
        $events = InventoryEvent::with(['item:id,name', 'classroom:id,code,name', 'user:id,name'])
            ->when($request->filled('classroom_id'), fn ($query) => $query->where('classroom_id', $request->integer('classroom_id')))
            ->latest('occurred_at')
            ->paginate(30);

        return $this->success($events);
    }

    public function storeEvent(Request $request, InventoryItem $inventoryItem)
    {
        $data = $request->validate([
            'type' => ['required', Rule::in(['damage', 'missing', 'transfer', 'maintenance', 'recovery', 'adjustment'])],
            'description' => ['required', 'string', 'max:1000'],
            'quantity_delta' => ['nullable', 'integer', 'between:-10000,10000'],
            'new_status' => ['nullable', Rule::in(['available', 'loaned', 'maintenance', 'damaged', 'out_of_service'])],
            'occurred_at' => ['nullable', 'date'],
        ]);

        [$event, $updatedItem] = DB::transaction(function () use ($request, $inventoryItem, $data) {
            $item = InventoryItem::lockForUpdate()->findOrFail($inventoryItem->id);
            $before = $item->toArray();
            $delta = (int) ($data['quantity_delta'] ?? 0);
            $newAvailable = max(0, min($item->quantity, $item->available_quantity + $delta));
            $item->update([
                'available_quantity' => $newAvailable,
                'status' => $data['new_status'] ?? $item->status,
            ]);

            $event = InventoryEvent::create([
                'inventory_item_id' => $item->id,
                'classroom_id' => $item->classroom_id,
                'user_id' => $request->user()->id,
                'type' => $data['type'],
                'quantity_delta' => $data['quantity_delta'] ?? null,
                'description' => $data['description'],
                'occurred_at' => $data['occurred_at'] ?? now(),
            ]);

            $this->audit->record($request, 'inventory.event_created', $item, $before, $item->fresh()->toArray());

            return [$event, $item->fresh()];
        });

        return $this->success([
            'event' => $event->load('user:id,name'),
            'item' => $updatedItem,
        ], 'Novedad registrada y estado actualizado.', 201);
    }

    private function validatedItem(Request $request, ?InventoryItem $item = null): array
    {
        $data = $request->validate([
            'classroom_id' => ['required', 'exists:classrooms,id'],
            'name' => [
                'required', 'string', 'max:120',
                Rule::unique('inventory_items', 'name')
                    ->where(fn ($query) => $query->where('classroom_id', $request->integer('classroom_id')))
                    ->ignore($item?->id),
            ],
            'category' => ['required', 'string', 'max:60'],
            'quantity' => ['required', 'integer', 'min:0', 'max:10000'],
            'available_quantity' => ['required', 'integer', 'min:0', 'lte:quantity'],
            'status' => ['required', Rule::in(['available', 'loaned', 'maintenance', 'damaged', 'out_of_service'])],
            'description' => ['nullable', 'string', 'max:1000'],
        ]);

        Classroom::whereKey($data['classroom_id'])->where('is_active', true)->firstOrFail();

        return $data;
    }
}

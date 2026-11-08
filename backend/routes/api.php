<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ClassroomController;
use App\Http\Controllers\Api\InventoryController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\RecommendationController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ReservationController;
use App\Http\Controllers\Api\ScheduleController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::get('/health', fn () => response()->json([
    'success' => true,
    'message' => 'AulaGestión API disponible.',
    'data' => ['version' => '1.2.1', 'timestamp' => now()->toIso8601String()],
]));

Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/dashboard', [ReportController::class, 'dashboard']);

    Route::get('/classrooms', [ClassroomController::class, 'index']);
    Route::get('/classrooms/{classroom}', [ClassroomController::class, 'show']);

    Route::get('/inventory', [InventoryController::class, 'index']);
    Route::get('/inventory/{inventoryItem}', [InventoryController::class, 'show']);

    Route::get('/reservations', [ReservationController::class, 'index']);
    Route::get('/reservations/{reservation}', [ReservationController::class, 'show']);

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/alerts', [NotificationController::class, 'alerts']);
    Route::patch('/notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markRead']);

    Route::middleware('role:professor,admin')->group(function () {
        Route::post('/recommendations/search', [RecommendationController::class, 'search']);
        Route::post('/reservations', [ReservationController::class, 'store']);
        Route::patch('/reservations/{reservation}/cancel', [ReservationController::class, 'cancel']);
    });

    Route::middleware('role:inventory,admin')->group(function () {
        Route::post('/inventory', [InventoryController::class, 'store']);
        Route::put('/inventory/{inventoryItem}', [InventoryController::class, 'update']);
        Route::get('/inventory-events', [InventoryController::class, 'events']);
        Route::post('/inventory/{inventoryItem}/events', [InventoryController::class, 'storeEvent']);
        Route::get('/reports/summary', [ReportController::class, 'summary']);
    });

    Route::middleware('role:admin')->group(function () {
        Route::apiResource('users', UserController::class);
        Route::post('/classrooms', [ClassroomController::class, 'store']);
        Route::put('/classrooms/{classroom}', [ClassroomController::class, 'update']);
        Route::delete('/classrooms/{classroom}', [ClassroomController::class, 'destroy']);

        Route::get('/schedules', [ScheduleController::class, 'index']);
        Route::post('/schedules', [ScheduleController::class, 'store']);
        Route::put('/schedules/{schedule}', [ScheduleController::class, 'update']);
        Route::delete('/schedules/{schedule}', [ScheduleController::class, 'destroy']);
        Route::get('/blocks', [ScheduleController::class, 'blocks']);
        Route::post('/blocks', [ScheduleController::class, 'storeBlock']);
        Route::delete('/blocks/{block}', [ScheduleController::class, 'destroyBlock']);
    });
});

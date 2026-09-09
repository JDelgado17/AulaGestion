<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('classrooms', function (Blueprint $table) {
            $table->id();
            $table->string('code', 30)->unique();
            $table->string('name');
            $table->string('location');
            $table->unsignedInteger('capacity');
            $table->string('type', 60);
            $table->text('description')->nullable();
            $table->enum('status', ['available', 'maintenance', 'out_of_service'])->default('available')->index();
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();
        });

        Schema::create('inventory_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('classroom_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('category', 60);
            $table->unsignedInteger('quantity')->default(1);
            $table->unsignedInteger('available_quantity')->default(1);
            $table->enum('status', ['available', 'loaned', 'maintenance', 'damaged', 'out_of_service'])->default('available')->index();
            $table->text('description')->nullable();
            $table->timestamps();
            $table->unique(['classroom_id', 'name']);
        });

        Schema::create('classroom_schedules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('classroom_id')->nullable()->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('weekday');
            $table->time('start_time');
            $table->time('end_time');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->index(['classroom_id', 'weekday']);
        });

        Schema::create('classroom_blocks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('classroom_id')->constrained()->cascadeOnDelete();
            $table->dateTime('starts_at')->index();
            $table->dateTime('ends_at')->index();
            $table->string('reason');
            $table->foreignId('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
        });

        Schema::create('reservations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->foreignId('classroom_id')->constrained()->restrictOnDelete();
            $table->dateTime('starts_at')->index();
            $table->dateTime('ends_at')->index();
            $table->unsignedInteger('attendees');
            $table->string('activity_type', 80);
            $table->json('required_resources')->nullable();
            $table->json('optional_resources')->nullable();
            $table->string('purpose');
            $table->enum('status', ['confirmed', 'cancelled', 'completed', 'rejected'])->default('confirmed')->index();
            $table->text('cancellation_reason')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();
            $table->index(['classroom_id', 'starts_at', 'ends_at', 'status'], 'reservation_overlap_lookup');
        });

        Schema::create('inventory_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('inventory_item_id')->constrained()->cascadeOnDelete();
            $table->foreignId('classroom_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->enum('type', ['damage', 'missing', 'transfer', 'maintenance', 'recovery', 'adjustment']);
            $table->integer('quantity_delta')->nullable();
            $table->text('description');
            $table->dateTime('occurred_at');
            $table->timestamps();
        });

        Schema::create('app_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('message');
            $table->string('type', 50)->default('info');
            $table->timestamp('read_at')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
        });

        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('action', 80);
            $table->string('auditable_type');
            $table->unsignedBigInteger('auditable_id')->nullable();
            $table->json('before_data')->nullable();
            $table->json('after_data')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['auditable_type', 'auditable_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('app_notifications');
        Schema::dropIfExists('inventory_events');
        Schema::dropIfExists('reservations');
        Schema::dropIfExists('classroom_blocks');
        Schema::dropIfExists('classroom_schedules');
        Schema::dropIfExists('inventory_items');
        Schema::dropIfExists('classrooms');
    }
};

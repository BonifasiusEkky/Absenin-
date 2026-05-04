<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    // Some operations on Postgres behave better outside transaction
    public $withinTransaction = false;

    public function up(): void
    {
        // Destructive but clean for dev: drop and recreate attendances with correct schema
        Schema::dropIfExists('attendances');
        Schema::create('attendances', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->unsignedBigInteger('user_id');
            $table->date('date');
            $table->time('check_in')->nullable();
            $table->time('check_out')->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->decimal('distance_m', 8, 2)->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->index('user_id');
            $table->index(['user_id', 'date']);
        });
    }

    public function down(): void
    {
        // Recreate original (uuid user_id) definition
        Schema::dropIfExists('attendances');
        Schema::create('attendances', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->date('date');
            $table->time('check_in')->nullable();
            $table->time('check_out')->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->decimal('distance_m', 8, 2)->nullable();
            $table->timestamps();

            $table->index('user_id');
            $table->index(['user_id', 'date']);
        });
    }
};

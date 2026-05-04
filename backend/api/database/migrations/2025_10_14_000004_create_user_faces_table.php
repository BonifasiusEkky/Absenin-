<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('user_faces', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            // Store the storage path or URL to the face image captured for verification
            $table->text('image_path');
            // Optional content hash (e.g., sha256) for deduplication
            $table->string('image_hash', 128)->nullable();
            // Optionally store DeepFace embedding as JSON (array of floats)
            $table->json('embedding')->nullable();
            $table->string('embedding_model', 64)->default('VGG-Face');
            $table->smallInteger('embedding_dim')->nullable();
            // Mark a primary face per user (used as reference in verify)
            $table->boolean('is_primary')->default(false);
            // Arbitrary metadata (capture method, device info, gps, etc.)
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['user_id']);
        });

        // Ensure only one primary face per user (PostgreSQL partial unique index)
        DB::statement('CREATE UNIQUE INDEX user_faces_one_primary_per_user ON user_faces (user_id) WHERE is_primary = true');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop partial index first (PostgreSQL)
        DB::statement('DROP INDEX IF EXISTS user_faces_one_primary_per_user');
        Schema::dropIfExists('user_faces');
    }
};

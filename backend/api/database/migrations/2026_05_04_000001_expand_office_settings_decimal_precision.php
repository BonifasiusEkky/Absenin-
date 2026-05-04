<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('office_settings', function (Blueprint $table) {
            // Expand decimal precision to support 8 decimal places (e.g., 112.69277025)
            $table->decimal('office_latitude', 11, 8)->change();
            $table->decimal('office_longitude', 11, 8)->change();
        });
    }

    public function down(): void
    {
        Schema::table('office_settings', function (Blueprint $table) {
            // Revert back to original precision
            $table->decimal('office_latitude', 10, 7)->change();
            $table->decimal('office_longitude', 10, 7)->change();
        });
    }
};

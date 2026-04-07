<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role', 32)->default('employee')->after('password');
            $table->boolean('is_active')->default(true)->after('role');
            $table->string('work_mode', 8)->default('wfo')->after('is_active'); // wfo|wfh
            $table->string('job_title')->nullable()->after('work_mode');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['role', 'is_active', 'work_mode', 'job_title']);
        });
    }
};

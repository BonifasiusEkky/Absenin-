<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->decimal('check_in_latitude', 10, 7)->nullable()->after('check_in');
            $table->decimal('check_in_longitude', 10, 7)->nullable()->after('check_in_latitude');
            $table->decimal('check_in_distance_m', 8, 2)->nullable()->after('check_in_longitude');

            $table->decimal('check_out_latitude', 10, 7)->nullable()->after('check_out');
            $table->decimal('check_out_longitude', 10, 7)->nullable()->after('check_out_latitude');
            $table->decimal('check_out_distance_m', 8, 2)->nullable()->after('check_out_longitude');

            $table->string('work_mode', 8)->nullable()->after('activity_note'); // wfo|wfh snapshot
            $table->string('location_status_in', 16)->nullable()->after('work_mode'); // inside|outside|logged
            $table->string('location_status_out', 16)->nullable()->after('location_status_in');

            $table->text('check_in_photo_path')->nullable()->after('location_status_out');
            $table->text('check_out_photo_path')->nullable()->after('check_in_photo_path');

            $table->boolean('check_in_verified')->nullable()->after('check_out_photo_path');
            $table->boolean('check_out_verified')->nullable()->after('check_in_verified');

            $table->decimal('check_in_face_distance', 10, 6)->nullable()->after('check_out_verified');
            $table->decimal('check_out_face_distance', 10, 6)->nullable()->after('check_in_face_distance');
            $table->decimal('check_in_face_confidence', 6, 2)->nullable()->after('check_out_face_distance');
            $table->decimal('check_out_face_confidence', 6, 2)->nullable()->after('check_in_face_confidence');
            $table->decimal('check_in_face_threshold', 10, 6)->nullable()->after('check_out_face_confidence');
            $table->decimal('check_out_face_threshold', 10, 6)->nullable()->after('check_in_face_threshold');
        });
    }

    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropColumn([
                'check_in_latitude',
                'check_in_longitude',
                'check_in_distance_m',
                'check_out_latitude',
                'check_out_longitude',
                'check_out_distance_m',
                'work_mode',
                'location_status_in',
                'location_status_out',
                'check_in_photo_path',
                'check_out_photo_path',
                'check_in_verified',
                'check_out_verified',
                'check_in_face_distance',
                'check_out_face_distance',
                'check_in_face_confidence',
                'check_out_face_confidence',
                'check_in_face_threshold',
                'check_out_face_threshold',
            ]);
        });
    }
};

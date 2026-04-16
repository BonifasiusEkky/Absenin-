<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Attendance extends Model
{
    protected $table = 'attendances';
    protected $fillable = [
        'id',
        'user_id',
        'date',
        'status',
        'check_in',
        'check_out',
        // Legacy combined fields
        'latitude',
        'longitude',
        'distance_m',
        // Daily report
        'activity_note',
        // New split location fields
        'check_in_latitude',
        'check_in_longitude',
        'check_in_distance_m',
        'check_out_latitude',
        'check_out_longitude',
        'check_out_distance_m',
        // Work mode snapshot & location validation status
        'work_mode',
        'location_status_in',
        'location_status_out',
        // Proof fields
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
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

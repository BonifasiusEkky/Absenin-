<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OfficeSetting extends Model
{
    protected $table = 'office_settings';

    protected $fillable = [
        'office_latitude',
        'office_longitude',
        'radius_m',
        'updated_by',
    ];

    protected $casts = [
        'office_latitude' => 'float',
        'office_longitude' => 'float',
        'radius_m' => 'float',
    ];
}

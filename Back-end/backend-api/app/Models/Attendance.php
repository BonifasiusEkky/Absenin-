<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Attendance extends Model
{
    protected $table = 'attendances';
    protected $fillable = ['id','user_id','date','check_in','check_out','latitude','longitude','distance_m'];
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Assignment extends Model
{
    public $timestamps = false;
    protected $table = 'assignments';
    protected $fillable = ['id','user_id','title','description','image_url','created_at'];
}

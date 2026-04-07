<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Leave extends Model
{
    protected $table = 'leaves';
    protected $fillable = [
        'id',
        'user_id',
        'type',
        'start_date',
        'end_date',
        'reason',
        'status',
        'attachment_path',
        'decided_by',
        'decided_at',
        'decision_note',
    ];
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserFace extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'image_path',
        'image_hash',
        'embedding',
        'embedding_model',
        'embedding_dim',
        'is_primary',
        'metadata',
    ];

    protected $casts = [
        'embedding' => 'array',
        'metadata' => 'array',
        'is_primary' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

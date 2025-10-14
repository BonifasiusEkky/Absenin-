<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Assignment;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AssignmentController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->query('user_id');
        $q = Assignment::query();
        if ($userId) $q->where('user_id', $userId);
        return response()->json($q->orderByDesc('created_at')->limit(200)->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|string',
            'title' => 'required|string',
            'description' => 'nullable|string',
            'image_url' => 'nullable|string',
        ]);
        $data['id'] = (string) Str::uuid();
        $data['created_at'] = now();
        $a = Assignment::create($data);
        return response()->json($a, 201);
    }
}

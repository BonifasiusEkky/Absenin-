<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Assignment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AssignmentController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        return response()->json(
            Assignment::query()
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(200)
                ->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string',
            'description' => 'nullable|string',
            'image_url' => 'nullable|string',
            'image' => 'sometimes|file|mimes:jpg,jpeg,png|max:5120',
        ]);
        $user = $request->user();

        $imageUrl = $data['image_url'] ?? null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('public/assignment-images');
            $imageUrl = Storage::url($path); // /storage/assignment-images/...
        }

        $a = Assignment::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'image_url' => $imageUrl,
            'created_at' => now(),
        ]);
        return response()->json($a, 201);
    }
}

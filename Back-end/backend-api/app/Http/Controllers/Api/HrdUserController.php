<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class HrdUserController extends Controller
{
    /**
     * GET /api/hrd/users
     */
    public function index(Request $request)
    {
        return response()->json(User::query()->orderBy('id')->limit(500)->get([
            'id', 'name', 'email', 'role', 'is_active', 'work_mode', 'job_title', 'created_at', 'updated_at'
        ]));
    }

    /**
     * POST /api/hrd/users
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|string|min:8',
            'role' => 'required|in:employee,hrd',
            'is_active' => 'sometimes|boolean',
            'work_mode' => 'required|in:wfo,wfh',
            'job_title' => 'nullable|string|max:255',
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'role' => $data['role'],
            'is_active' => (bool) ($data['is_active'] ?? true),
            'work_mode' => $data['work_mode'],
            'job_title' => $data['job_title'] ?? null,
        ]);

        return response()->json(['ok' => true, 'user' => $user], 201);
    }

    /**
     * PATCH /api/hrd/users/{id}
     */
    public function update(Request $request, int $id)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|max:255|unique:users,email,' . $id,
            'password' => 'sometimes|string|min:8',
            'role' => 'sometimes|in:employee,hrd',
            'is_active' => 'sometimes|boolean',
            'work_mode' => 'sometimes|in:wfo,wfh',
            'job_title' => 'sometimes|nullable|string|max:255',
        ]);

        $user = User::findOrFail($id);

        if (array_key_exists('password', $data)) {
            $data['password'] = Hash::make($data['password']);
        }

        $user->fill($data);
        $user->save();

        return response()->json(['ok' => true, 'user' => $user]);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * POST /api/auth/login
     * Body: { email, password }
     */
    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        /** @var User|null $user */
        $user = User::where('email', $data['email'])->first();
        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        if ($user->is_active === false) {
            return response()->json(['message' => 'User is inactive'], 403);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'ok' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'work_mode' => $user->work_mode,
                'job_title' => $user->job_title,
                'is_active' => (bool) $user->is_active,
            ],
            'token' => $token,
        ]);
    }

    /**
     * POST /api/auth/logout (requires auth:sanctum)
     */
    public function logout(Request $request)
    {
        $user = $request->user();
        if ($user) {
            // Revoke all tokens for simplicity (avoids static analysis type issues on currentAccessToken())
            $user->tokens()->delete();
        }
        return response()->json(['ok' => true]);
    }
}

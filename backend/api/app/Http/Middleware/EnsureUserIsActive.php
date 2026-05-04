<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsActive
{
    /**
     * Reject requests from inactive users.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user && method_exists($user, 'getAttribute') && $user->getAttribute('is_active') === false) {
            return response()->json(['message' => 'User is inactive'], 403);
        }

        return $next($request);
    }
}

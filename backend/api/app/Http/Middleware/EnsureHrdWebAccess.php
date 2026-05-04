<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureHrdWebAccess
{
    /**
     * Ensure the current session user is an active HRD.
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (!Auth::check()) {
            return redirect()->route('hrd.login');
        }

        $user = $request->user();
        if (!$user) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();
            return redirect()->route('hrd.login');
        }

        if (($user->is_active ?? true) === false) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();
            return redirect()->route('hrd.login')->with('error', 'Akun nonaktif.');
        }

        if (($user->role ?? null) !== 'hrd') {
            abort(403, 'Forbidden');
        }

        return $next($request);
    }
}

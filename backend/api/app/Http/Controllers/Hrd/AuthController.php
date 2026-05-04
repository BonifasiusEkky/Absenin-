<?php

namespace App\Http\Controllers\Hrd;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    public function showLogin()
    {
        return view('hrd.auth.login');
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $ok = Auth::attempt([
            'email' => $data['email'],
            'password' => $data['password'],
            'role' => 'hrd',
            'is_active' => true,
        ]);

        if (!$ok) {
            return back()->withInput($request->only('email'))
                ->with('error', 'Email / password salah atau bukan HRD.');
        }

        $request->session()->regenerate();

        return redirect()->intended(route('hrd.dashboard'));
    }

    public function logout(Request $request)
    {
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('hrd.login');
    }
}

<?php

namespace App\Http\Controllers\Hrd;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UsersController extends Controller
{
    public function index(Request $request)
    {
        $q = User::query()->orderBy('id');

        if ($request->filled('q')) {
            $term = (string) $request->query('q');
            $q->where(function ($qq) use ($term) {
                $qq->where('name', 'ilike', '%' . $term . '%')
                    ->orWhere('email', 'ilike', '%' . $term . '%');
            });
        }

        if ($request->filled('role')) {
            $q->where('role', $request->query('role'));
        }

        if ($request->filled('active')) {
            $active = $request->query('active') === '1';
            $q->where('is_active', $active);
        }

        $users = $q->limit(500)->get();

        return view('hrd.users.index', [
            'users' => $users,
            'filters' => [
                'q' => $request->query('q', ''),
                'role' => $request->query('role', ''),
                'active' => $request->query('active', ''),
            ],
        ]);
    }

    public function create()
    {
        return view('hrd.users.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|string|min:8',
            'role' => 'required|in:employee,hrd',
            'work_mode' => 'required|in:wfo,wfh',
            'job_title' => 'nullable|string|max:255',
            'is_active' => 'sometimes|boolean',
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'role' => $data['role'],
            'work_mode' => $data['work_mode'],
            'job_title' => $data['job_title'] ?? null,
            'is_active' => (bool) ($data['is_active'] ?? false),
        ]);

        return redirect()->route('hrd.users.edit', $user->id)->with('success', 'User dibuat.');
    }

    public function edit(int $id)
    {
        $user = User::findOrFail($id);
        return view('hrd.users.edit', ['user' => $user]);
    }

    public function update(Request $request, int $id)
    {
        $user = User::findOrFail($id);

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email,' . $user->id,
            'password' => 'nullable|string|min:8',
            'role' => 'required|in:employee,hrd',
            'work_mode' => 'required|in:wfo,wfh',
            'job_title' => 'nullable|string|max:255',
            'is_active' => 'sometimes|boolean',
        ]);

        $user->name = $data['name'];
        $user->email = $data['email'];
        $user->role = $data['role'];
        $user->work_mode = $data['work_mode'];
        $user->job_title = $data['job_title'] ?? null;
        $user->is_active = (bool) ($data['is_active'] ?? false);

        if (!empty($data['password'])) {
            $user->password = Hash::make($data['password']);
        }

        $user->save();

        return back()->with('success', 'User diupdate.');
    }
}

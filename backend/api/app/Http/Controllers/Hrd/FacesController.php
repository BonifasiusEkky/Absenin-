<?php

namespace App\Http\Controllers\Hrd;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserFace;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class FacesController extends Controller
{
    public function create(Request $request)
    {
        $users = User::orderBy('name')->get(['id', 'name', 'email', 'role', 'is_active']);

        $selectedUserId = $request->query('user_id');
        $faces = null;
        if ($selectedUserId) {
            $faces = UserFace::where('user_id', (int) $selectedUserId)->orderByDesc('id')->get();
        }

        return view('hrd.faces.create', [
            'users' => $users,
            'faces' => $faces,
            'selectedUserId' => $selectedUserId,
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'image' => 'required|file|mimes:jpg,jpeg,png|max:5120',
            'is_primary' => 'sometimes|boolean',
        ]);

        $user = User::findOrFail($data['user_id']);

        $path = $request->file('image')->store('public/user-faces');
        $hash = hash_file('sha256', $request->file('image')->getRealPath());

        $faceApi = config('services.face_api.url');
        $resp = Http::asMultipart()
            ->timeout(120)
            ->post(rtrim((string) $faceApi, '/') . '/embed', [
                'file' => [
                    'name' => 'file',
                    'contents' => Storage::get($path),
                    'filename' => basename($path) . '.jpg',
                ],
                'model_name' => config('services.face_api.model', 'ArcFace'),
                'detector_backend' => config('services.face_api.detector_backend', 'retinaface'),
                'enforce_detection' => 'false',
                'align' => 'true',
            ]);

        if (!$resp->ok()) {
            Storage::delete($path);
            return back()->with('error', 'Face service error: ' . ($resp->json('detail') ?? $resp->body()));
        }

        $body = $resp->json();
        $embedding = $body['embedding'] ?? null;
        $embeddingDim = $body['embedding_dim'] ?? null;
        $embeddingModel = $body['model'] ?? config('services.face_api.model', 'ArcFace');

        if (!$embedding || !is_array($embedding)) {
            Storage::delete($path);
            throw ValidationException::withMessages([
                'image' => ['Gagal menghitung embedding dari foto.'],
            ]);
        }

        $isPrimary = (bool) $request->boolean('is_primary', false);
        if ($isPrimary) {
            UserFace::where('user_id', $user->id)->where('is_primary', true)->update(['is_primary' => false]);
        }

        UserFace::create([
            'user_id' => $user->id,
            'image_path' => $path,
            'image_hash' => $hash,
            'embedding' => $embedding,
            'embedding_model' => $embeddingModel,
            'embedding_dim' => $embeddingDim,
            'is_primary' => $isPrimary,
            'metadata' => [
                'disk' => config('filesystems.default'),
                'size' => Storage::size($path),
                'mime' => $request->file('image')->getMimeType(),
            ],
        ]);

        return redirect()->route('hrd.faces.create', ['user_id' => $user->id])
            ->with('success', 'Wajah berhasil didaftarkan.');
    }
}

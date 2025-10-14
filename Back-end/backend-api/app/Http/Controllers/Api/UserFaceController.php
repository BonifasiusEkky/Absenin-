<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserFace;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class UserFaceController extends Controller
{
    /**
     * Register a new face for a user.
     *
     * multipart/form-data fields:
     * - user_id: int
     * - image: file (jpg/jpeg/png)
     * - is_primary: boolean (optional, default false)
     * - model_name, detector_backend (optional)
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'image' => 'required|file|mimes:jpg,jpeg,png',
            'is_primary' => 'sometimes|boolean',
            'model_name' => 'sometimes|string',
            'detector_backend' => 'sometimes|string',
        ]);

        $user = User::findOrFail($data['user_id']);

        // Store image to configured disk (default: local). You can switch to s3 if needed.
        $path = $request->file('image')->store('public/user-faces');
        $hash = hash_file('sha256', $request->file('image')->getRealPath());

        // Call face-service to generate embedding for the saved image
        $faceApi = config('services.face_api.url');
        $resp = Http::asMultipart()
            ->timeout(120)
            ->post(rtrim($faceApi, '/') . '/embed', [
                'file' => [
                    'name' => 'file',
                    'contents' => Storage::get($path),
                    'filename' => basename($path) . '.jpg',
                ],
                'model_name' => $request->input('model_name', 'ArcFace'),
                'detector_backend' => $request->input('detector_backend', 'retinaface'),
                'enforce_detection' => 'false',
                'align' => 'true',
            ]);

        if (!$resp->ok()) {
            // cleanup stored file if embedding fails
            Storage::delete($path);
            return response()->json([
                'ok' => false,
                'error' => $resp->json('detail') ?? $resp->body(),
            ], $resp->status());
        }

        $body = $resp->json();
        $embedding = $body['embedding'] ?? null;
        $embeddingDim = $body['embedding_dim'] ?? null;
        $embeddingModel = $body['model'] ?? $request->input('model_name', 'ArcFace');

        if (!$embedding || !is_array($embedding)) {
            Storage::delete($path);
            throw ValidationException::withMessages([
                'image' => ['Failed to compute embedding for the provided image.'],
            ]);
        }

        // If setting as primary, unset previous primary
        $isPrimary = (bool) $request->boolean('is_primary', false);
        if ($isPrimary) {
            UserFace::where('user_id', $user->id)->where('is_primary', true)->update(['is_primary' => false]);
        }

        $face = UserFace::create([
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

        return response()->json([
            'ok' => true,
            'face' => $face,
        ], 201);
    }
}

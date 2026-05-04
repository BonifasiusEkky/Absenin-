<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserFace;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class FaceVerificationController extends Controller
{
    /**
     * Verify a new captured image against user's primary face using FastAPI.
     *
     * Request: multipart/form-data
     * - user_id: int
     * - image: file (new capture)
     * - optional: model_name, detector_backend, distance_metric, threshold
     */
    public function verify(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'image' => 'required|file|mimes:jpg,jpeg,png',
            'model_name' => 'sometimes|string',
            'detector_backend' => 'sometimes|string',
            'distance_metric' => 'sometimes|string',
            'threshold' => 'sometimes|numeric',
        ]);

        // Get user's primary face
        $user = User::findOrFail($data['user_id']);
        /** @var UserFace|null $primary */
        $primary = $user->faces()->where('is_primary', true)->first();
        if (!$primary) {
            throw ValidationException::withMessages([
                'user_id' => ['User does not have a primary face registered.'],
            ]);
        }

        // Retrieve reference image content
        // image_path may be a storage path (e.g., "public/faces/...") or absolute URL
        $refStream = null;
        $refName = basename($primary->image_path);
        if (preg_match('/^https?:\/\//i', $primary->image_path)) {
            $resp = Http::timeout(30)->get($primary->image_path);
            if (!$resp->ok()) {
                return response()->json(['ok' => false, 'error' => 'Failed to fetch reference image'], 400);
            }
            $refContent = $resp->body();
        } else {
            if (!Storage::exists($primary->image_path)) {
                return response()->json(['ok' => false, 'error' => 'Reference image not found in storage'], 404);
            }
            $refContent = Storage::get($primary->image_path);
        }

        // Prepare multipart to FastAPI
        $faceApi = config('services.face_api.url');
        $multipart = [
            'file1' => [
                'name' => 'file1',
                'contents' => $refContent,
                'filename' => $refName,
            ],
            'file2' => [
                'name' => 'file2',
                'contents' => file_get_contents($request->file('image')->getRealPath()),
                'filename' => $request->file('image')->getClientOriginalName(),
            ],
            'model_name' => $request->input('model_name', 'ArcFace'),
            'detector_backend' => $request->input('detector_backend', 'retinaface'),
            'distance_metric' => $request->input('distance_metric', 'cosine'),
            'enforce_detection' => 'false',
            'align' => 'true',
        ];

        if ($request->filled('threshold')) {
            $multipart['threshold'] = (string)$request->input('threshold');
        }

        $response = Http::asMultipart()->timeout(120)->post(rtrim($faceApi, '/') . '/verify', $multipart);

        if (!$response->ok()) {
            $json = $response->json();
            if (is_null($json)) {
                $json = [
                    'ok' => false,
                    'error' => $response->body(),
                ];
            }
            return response()->json($json, $response->status());
        }

        // Success: return parsed JSON to client (ensures proper Content-Type)
        return response()->json($response->json(), 200);
    }
}

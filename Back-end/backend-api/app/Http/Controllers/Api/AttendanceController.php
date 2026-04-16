<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\OfficeSetting;
use App\Models\UserFace;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AttendanceController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $q = Attendance::query();

        // HRD can view all (optionally filter by user_id)
        if ($user?->role === 'hrd') {
            if ($request->filled('user_id')) {
                $q->where('user_id', (int) $request->query('user_id'));
            }
        } else {
            $q->where('user_id', $user->id);
        }

        return response()->json($q->orderByDesc('date')->limit(200)->get());
    }

    public function checkIn(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'date' => 'sometimes|date',
            'time' => 'sometimes', // expected format HH:MM:SS
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'photo' => 'required|file|mimes:jpg,jpeg,png',
        ]);

        $date = $data['date'] ?? now()->toDateString();
        $time = $data['time'] ?? now()->format('H:i:s');

        [$distanceM, $status] = $this->computeLocationStatus($user->work_mode, (float) $data['latitude'], (float) $data['longitude']);
        if ($status === 'outside') {
            return response()->json(['message' => 'Diluar radius kantor'], 422);
        }

        [$photoPath, $face] = $this->storeAndVerifyFace($user->id, $request->file('photo'));

        $att = Attendance::firstOrNew(['user_id' => $user->id, 'date' => $date]);
        if (!$att->exists) {
            $att->id = (string) Str::uuid();
        }

        // Prevent double check-in
        if ($att->exists && !is_null($att->check_in)) {
            return response()->json(['message' => 'Sudah check-in untuk tanggal ini'], 409);
        }

        $att->status = 'present';
        $att->check_in = $time;
        $att->check_in_latitude = (float) $data['latitude'];
        $att->check_in_longitude = (float) $data['longitude'];
        $att->check_in_distance_m = $distanceM;
        $att->location_status_in = $status;
        $att->work_mode = $user->work_mode;

        $att->check_in_photo_path = $photoPath;
        $att->check_in_verified = (bool) ($face['verified'] ?? false);
        $att->check_in_face_distance = $face['distance'] ?? null;
        $att->check_in_face_confidence = $face['confidence'] ?? null;
        $att->check_in_face_threshold = $face['threshold'] ?? null;

        // Keep legacy fields in sync for backwards compatibility
        $att->latitude = (float) $data['latitude'];
        $att->longitude = (float) $data['longitude'];
        $att->distance_m = $distanceM;

        $att->save();
        return response()->json($att);
    }

    public function checkOut(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'date' => 'sometimes|date',
            'time' => 'sometimes', // expected format HH:MM:SS
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            // Daily report is mandatory on clock-out
            'activity' => 'required|string|min:3',
            'photo' => 'required|file|mimes:jpg,jpeg,png',
        ]);

        $date = $data['date'] ?? now()->toDateString();
        $time = $data['time'] ?? now()->format('H:i:s');

        [$distanceM, $status] = $this->computeLocationStatus($user->work_mode, (float) $data['latitude'], (float) $data['longitude']);
        if ($status === 'outside') {
            return response()->json(['message' => 'Diluar radius kantor'], 422);
        }

        $att = Attendance::where('user_id', $user->id)->where('date', $date)->first();
        if (!$att) {
            return response()->json(['message' => 'Attendance not found'], 404);
        }
        if (is_null($att->check_in)) {
            return response()->json(['message' => 'Harus check-in dulu'], 422);
        }
        if (!is_null($att->check_out)) {
            return response()->json(['message' => 'Sudah check-out untuk tanggal ini'], 409);
        }

        $att->status = 'present';

        [$photoPath, $face] = $this->storeAndVerifyFace($user->id, $request->file('photo'));

        $att->check_out = $time;
        $att->check_out_latitude = (float) $data['latitude'];
        $att->check_out_longitude = (float) $data['longitude'];
        $att->check_out_distance_m = $distanceM;
        $att->location_status_out = $status;
        $att->activity_note = $data['activity'];

        $att->check_out_photo_path = $photoPath;
        $att->check_out_verified = (bool) ($face['verified'] ?? false);
        $att->check_out_face_distance = $face['distance'] ?? null;
        $att->check_out_face_confidence = $face['confidence'] ?? null;
        $att->check_out_face_threshold = $face['threshold'] ?? null;

        $att->save();
        return response()->json($att);
    }

    /**
     * Stores the attendance photo and verifies it against the user's primary face.
     * Returns [stored_path, face_verify_response_json].
     */
    private function storeAndVerifyFace(int $userId, UploadedFile $photo): array
    {
        /** @var UserFace|null $primary */
        $primary = UserFace::query()->where('user_id', $userId)->where('is_primary', true)->first();
        if (!$primary) {
            throw ValidationException::withMessages([
                'photo' => ['Wajah belum terdaftar. Silakan hubungi HRD untuk melakukan registrasi wajah.'],
            ]);
        }

        $photoPath = $photo->store('public/attendance');

        try {
            $refName = basename($primary->image_path);
            if (preg_match('/^https?:\/\//i', $primary->image_path)) {
                $resp = Http::timeout(30)->get($primary->image_path);
                if (!$resp->ok()) {
                    throw ValidationException::withMessages([
                        'photo' => ['Gagal mengambil foto referensi untuk verifikasi wajah.'],
                    ]);
                }
                $refContent = $resp->body();
            } else {
                if (!Storage::exists($primary->image_path)) {
                    throw ValidationException::withMessages([
                        'photo' => ['Foto referensi untuk verifikasi wajah tidak ditemukan.'],
                    ]);
                }
                $refContent = Storage::get($primary->image_path);
            }

            $faceApi = config('services.face_api.url');
            $threshold = config('services.face_api.verify_threshold');

            $multipart = [
                'file1' => [
                    'name' => 'file1',
                    'contents' => $refContent,
                    'filename' => $refName,
                ],
                'file2' => [
                    'name' => 'file2',
                    'contents' => Storage::get($photoPath),
                    'filename' => $photo->getClientOriginalName(),
                ],
                'model_name' => config('services.face_api.model', 'ArcFace'),
                'detector_backend' => config('services.face_api.detector_backend', 'retinaface'),
                'distance_metric' => config('services.face_api.distance_metric', 'cosine'),
                'enforce_detection' => 'false',
                'align' => 'true',
            ];

            if (!is_null($threshold)) {
                $multipart['threshold'] = (string) $threshold;
            }

            $response = Http::asMultipart()->timeout(120)->post(rtrim($faceApi, '/') . '/verify', $multipart);
            if (!$response->ok()) {
                throw ValidationException::withMessages([
                    'photo' => ['Verifikasi wajah gagal: ' . ($response->json('detail') ?? $response->body())],
                ]);
            }

            $json = $response->json() ?? [];
            if (!(bool) ($json['verified'] ?? false)) {
                throw ValidationException::withMessages([
                    'photo' => ['Wajah tidak cocok. Silakan ulangi pengambilan foto.'],
                ]);
            }

            return [$photoPath, $json];
        } catch (ValidationException $e) {
            Storage::delete($photoPath);
            throw $e;
        } catch (\Throwable $e) {
            Storage::delete($photoPath);
            throw $e;
        }
    }

    /**
     * Returns [distance_m|null, status] where status is inside|outside|logged.
     */
    private function computeLocationStatus(string $workMode, float $lat, float $lng): array
    {
        $setting = OfficeSetting::query()->orderByDesc('id')->first();
        $officeLat = (float) ($setting?->office_latitude ?? env('OFFICE_LATITUDE', -7.938979));
        $officeLng = (float) ($setting?->office_longitude ?? env('OFFICE_LONGITUDE', 112.693397));
        $radiusM = (float) ($setting?->radius_m ?? env('OFFICE_RADIUS_M', 120));

        $distanceM = $this->haversineDistanceMeters($lat, $lng, $officeLat, $officeLng);

        if ($workMode === 'wfh') {
            return [round($distanceM, 2), 'logged'];
        }

        return [round($distanceM, 2), $distanceM <= $radiusM ? 'inside' : 'outside'];
    }

    private function haversineDistanceMeters(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000.0;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2)
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}

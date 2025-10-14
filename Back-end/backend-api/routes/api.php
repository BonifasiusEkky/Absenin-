<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Api\FaceVerificationController;
use App\Http\Controllers\Api\UserFaceController;
use App\Http\Controllers\Api\AssignmentController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\LeaveController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Public demo routes (add auth later)
Route::get('/assignments', [AssignmentController::class, 'index']);
Route::post('/assignments', [AssignmentController::class, 'store']);

Route::get('/attendances', [AttendanceController::class, 'index']);
Route::post('/attendances/check-in', [AttendanceController::class, 'checkIn']);
Route::post('/attendances/check-out', [AttendanceController::class, 'checkOut']);

Route::get('/leaves', [LeaveController::class, 'index']);
Route::post('/leaves', [LeaveController::class, 'store']);

// Health check for DB connectivity
Route::get('/health/db', function () {
    try {
        DB::select('select 1');
        return response()->json(['ok' => true]);
    } catch (\Throwable $e) {
        return response()->json(['ok' => false, 'error' => $e->getMessage()], 500);
    }
});

// Face verification: forwards to FastAPI service
Route::post('/face/verify', [FaceVerificationController::class, 'verify']);
Route::post('/user-faces', [UserFaceController::class, 'store']);

<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Api\FaceVerificationController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserFaceController;
use App\Http\Controllers\Api\AssignmentController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\LeaveController;
use App\Http\Controllers\Api\OfficeSettingController;
use App\Http\Controllers\Api\HrdUserController;
use App\Http\Controllers\Api\HrdLeaveController;
use App\Http\Controllers\Api\HolidayController;

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

// Auth
Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware(['auth:sanctum', 'active'])->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Current user profile
    Route::get('/me', function (Request $request) {
        return response()->json(['ok' => true, 'user' => $request->user()]);
    });

    // Office settings (used by mobile for geofencing)
    Route::get('/office-settings', [OfficeSettingController::class, 'show']);

    // Employee features
    Route::get('/assignments', [AssignmentController::class, 'index']);
    Route::post('/assignments', [AssignmentController::class, 'store']);

    Route::get('/attendances', [AttendanceController::class, 'index']);
    Route::post('/attendances/check-in', [AttendanceController::class, 'checkIn']);
    Route::post('/attendances/check-out', [AttendanceController::class, 'checkOut']);

    Route::get('/leaves', [LeaveController::class, 'index']);
    Route::post('/leaves', [LeaveController::class, 'store']);

    Route::get('/holidays', [HolidayController::class, 'index']);

    // Face verification (used by mobile). Enrollment is HRD-only.
    Route::post('/face/verify', [FaceVerificationController::class, 'verify']);
    Route::post('/user-faces', [UserFaceController::class, 'store'])->middleware('role:hrd');

    // HRD features
    Route::prefix('hrd')->middleware('role:hrd')->group(function () {
        Route::put('/office-settings', [OfficeSettingController::class, 'update']);

        Route::get('/users', [HrdUserController::class, 'index']);
        Route::post('/users', [HrdUserController::class, 'store']);
        Route::patch('/users/{id}', [HrdUserController::class, 'update']);

        Route::get('/leaves', [HrdLeaveController::class, 'index']);
        Route::patch('/leaves/{id}', [HrdLeaveController::class, 'decide']);
    });
});

// Health check for DB connectivity
Route::get('/health/db', function () {
    try {
        DB::select('select 1');
        return response()->json(['ok' => true]);
    } catch (\Throwable $e) {
        return response()->json(['ok' => false, 'error' => $e->getMessage()], 500);
    }
});

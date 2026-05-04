<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Hrd\AuthController as HrdAuthController;
use App\Http\Controllers\Hrd\DashboardController as HrdDashboardController;
use App\Http\Controllers\Hrd\UsersController as HrdUsersController;
use App\Http\Controllers\Hrd\LeavesController as HrdLeavesController;
use App\Http\Controllers\Hrd\OfficeSettingsController as HrdOfficeSettingsController;
use App\Http\Controllers\Hrd\FacesController as HrdFacesController;
use App\Http\Controllers\Hrd\AttendancesController as HrdAttendancesController;
use App\Http\Controllers\Hrd\HolidaysController as HrdHolidaysController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});

// HRD Admin (web)
Route::prefix('hrd')->name('hrd.')->group(function () {
    Route::get('/login', [HrdAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [HrdAuthController::class, 'login'])->name('login.submit');

    Route::middleware('hrd.web')->group(function () {
        Route::post('/logout', [HrdAuthController::class, 'logout'])->name('logout');

        Route::get('/', [HrdDashboardController::class, 'index'])->name('dashboard');

        // Users
        Route::get('/users', [HrdUsersController::class, 'index'])->name('users.index');
        Route::get('/users/create', [HrdUsersController::class, 'create'])->name('users.create');
        Route::post('/users', [HrdUsersController::class, 'store'])->name('users.store');
        Route::get('/users/{id}/edit', [HrdUsersController::class, 'edit'])->name('users.edit');
        Route::post('/users/{id}', [HrdUsersController::class, 'update'])->name('users.update');

        // Leaves
        Route::get('/leaves', [HrdLeavesController::class, 'index'])->name('leaves.index');
        Route::post('/leaves/{id}/decide', [HrdLeavesController::class, 'decide'])->name('leaves.decide');

        // Attendances
        Route::get('/attendances', [HrdAttendancesController::class, 'index'])->name('attendances.index');

        // Office settings
        Route::get('/office-settings', [HrdOfficeSettingsController::class, 'edit'])->name('office.edit');
        Route::post('/office-settings', [HrdOfficeSettingsController::class, 'update'])->name('office.update');

        // Face enrollment
        Route::get('/faces', [HrdFacesController::class, 'create'])->name('faces.create');
        Route::post('/faces', [HrdFacesController::class, 'store'])->name('faces.store');

        // Holidays
        Route::get('/holidays', [HrdHolidaysController::class, 'index'])->name('holidays.index');
        Route::post('/holidays', [HrdHolidaysController::class, 'store'])->name('holidays.store');
        Route::delete('/holidays/{id}', [HrdHolidaysController::class, 'destroy'])->name('holidays.destroy');
    });
});

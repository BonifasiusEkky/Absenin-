<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Auto-check for missing attendances (absent/bolos) from yesterday
        // This ensures that even if the server was off at 23:59, 
        // the logic runs the next time the server is active.
        try {
            if (!app()->runningInConsole() && !\Illuminate\Support\Facades\Cache::has('daily_absence_sync_' . date('Y-m-d'))) {
                \Illuminate\Support\Facades\Artisan::call('attendances:mark-absent');
                \Illuminate\Support\Facades\Cache::put('daily_absence_sync_' . date('Y-m-d'), true, now()->addDay());
            }
        } catch (\Exception $e) {
            // Silently fail to not break the app if DB isn't ready
        }
    }
}

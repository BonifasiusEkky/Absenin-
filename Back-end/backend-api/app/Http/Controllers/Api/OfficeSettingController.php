<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OfficeSetting;
use Illuminate\Http\Request;

class OfficeSettingController extends Controller
{
    /**
     * GET /api/office-settings
     * Returns office coordinate + radius.
     */
    public function show(Request $request)
    {
        $setting = OfficeSetting::query()->orderByDesc('id')->first();
        if (!$setting) {
            $setting = OfficeSetting::create([
                'office_latitude' => (float) env('OFFICE_LATITUDE', -7.938979),
                'office_longitude' => (float) env('OFFICE_LONGITUDE', 112.693397),
                'radius_m' => (float) env('OFFICE_RADIUS_M', 120),
                'updated_by' => $request->user()?->id,
            ]);
        }

        return response()->json([
            'ok' => true,
            'office_latitude' => (float) $setting->office_latitude,
            'office_longitude' => (float) $setting->office_longitude,
            'radius_m' => (float) $setting->radius_m,
            'updated_at' => $setting->updated_at,
        ]);
    }

    /**
     * PUT /api/hrd/office-settings
     */
    public function update(Request $request)
    {
        $data = $request->validate([
            'office_latitude' => 'required|numeric',
            'office_longitude' => 'required|numeric',
            'radius_m' => 'required|numeric|min:1',
        ]);

        $setting = OfficeSetting::query()->orderByDesc('id')->first();
        if (!$setting) {
            $setting = new OfficeSetting();
        }

        $setting->fill($data);
        $setting->updated_by = $request->user()?->id;
        $setting->save();

        return response()->json([
            'ok' => true,
            'office_latitude' => (float) $setting->office_latitude,
            'office_longitude' => (float) $setting->office_longitude,
            'radius_m' => (float) $setting->radius_m,
            'updated_at' => $setting->updated_at,
        ]);
    }
}

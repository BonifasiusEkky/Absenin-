<?php

namespace App\Http\Controllers\Hrd;

use App\Http\Controllers\Controller;
use App\Models\OfficeSetting;
use Illuminate\Http\Request;

class OfficeSettingsController extends Controller
{
    public function edit(Request $request)
    {
        $setting = OfficeSetting::query()->orderByDesc('id')->first();
        if (!$setting) {
            $setting = OfficeSetting::create([
                'office_latitude' => (float) env('OFFICE_LATITUDE', -7.9397675),
                'office_longitude' => (float) env('OFFICE_LONGITUDE', 112.69277025),
                'radius_m' => (float) env('OFFICE_RADIUS_M', 120),
                'updated_by' => $request->user()?->id,
            ]);
        }

        return view('hrd.office.edit', ['setting' => $setting]);
    }

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

        return back()->with('success', 'Office settings disimpan.');
    }
}

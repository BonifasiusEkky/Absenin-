<?php

namespace App\Http\Controllers\Hrd;

use App\Http\Controllers\Controller;
use App\Models\Holiday;
use Illuminate\Http\Request;
use Carbon\Carbon;

class HolidaysController extends Controller
{
    public function index()
    {
        $holidays = Holiday::orderBy('date', 'desc')->get();
        return view('hrd.holidays.index', compact('holidays'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'date' => 'required|date|unique:holidays,date',
            'name' => 'required|string|max:255',
            'is_mass_leave' => 'sometimes|boolean',
        ]);

        Holiday::create([
            'date' => $request->date,
            'name' => $request->name,
            'is_mass_leave' => $request->boolean('is_mass_leave'),
        ]);

        return redirect()->back()->with('success', 'Hari libur berhasil ditambahkan.');
    }

    public function destroy($id)
    {
        $holiday = Holiday::findOrFail($id);
        $holiday->delete();

        return redirect()->back()->with('success', 'Hari libur berhasil dihapus.');
    }
}

@extends('hrd.layout')

@section('title', 'Office Settings')

@section('content')
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="h4 mb-0">Office Settings</h1>
  </div>

  <div class="card">
    <div class="card-body">
      <form method="POST" action="{{ route('hrd.office.update') }}">
        @csrf

        <div class="row g-3">
          <div class="col-md-4">
            <label class="form-label">Office latitude</label>
            <input class="form-control" name="office_latitude" value="{{ old('office_latitude', $setting->office_latitude) }}" required>
          </div>
          <div class="col-md-4">
            <label class="form-label">Office longitude</label>
            <input class="form-control" name="office_longitude" value="{{ old('office_longitude', $setting->office_longitude) }}" required>
          </div>
          <div class="col-md-4">
            <label class="form-label">Radius (meters)</label>
            <input class="form-control" name="radius_m" value="{{ old('radius_m', $setting->radius_m) }}" required>
          </div>
        </div>

        <div class="mt-3">
          <button class="btn btn-primary" type="submit">Save</button>
        </div>

        <div class="text-muted small mt-3">
          Terakhir update: {{ $setting->updated_at }} (updated_by: {{ $setting->updated_by ?? '-' }})
        </div>
      </form>
    </div>
  </div>
@endsection

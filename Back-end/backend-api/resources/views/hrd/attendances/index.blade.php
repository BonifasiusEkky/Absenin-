@extends('hrd.layout')

@section('title', 'Attendances')

@section('content')
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="h4 mb-0">Attendances</h1>
  </div>

  <form class="card card-body mb-3" method="GET" action="{{ route('hrd.attendances.index') }}">
    <div class="row g-2 align-items-end">
      <div class="col-md-3">
        <label class="form-label">Date</label>
        <input class="form-control" type="date" name="date" value="{{ $filters['date'] }}">
      </div>
      <div class="col-md-7">
        <label class="form-label">User</label>
        <select class="form-select" name="user_id">
          <option value="" {{ $filters['user_id']==='' ? 'selected' : '' }}>All</option>
          @foreach ($users as $u)
            <option value="{{ $u->id }}" {{ (string)$filters['user_id']===(string)$u->id ? 'selected' : '' }}>
              #{{ $u->id }} — {{ $u->name }} ({{ $u->email }})
            </option>
          @endforeach
        </select>
      </div>
      <div class="col-md-2">
        <button class="btn btn-outline-primary w-100" type="submit">Filter</button>
      </div>
    </div>
  </form>

  <div class="card">
    <div class="table-responsive">
      <table class="table table-striped table-hover mb-0 align-middle">
        <thead>
          <tr>
            <th>ID</th>
            <th>Date</th>
            <th>User</th>
            <th>Check-in</th>
            <th>Check-out</th>
            <th>Work mode</th>
            <th>Loc in/out</th>
            <th>Verified</th>
          </tr>
        </thead>
        <tbody>
          @foreach ($attendances as $a)
            <tr>
              <td>{{ $a->id }}</td>
              <td>{{ $a->date }}</td>
              <td>
                <div class="fw-semibold">{{ $a->user?->name ?? ('#'.$a->user_id) }}</div>
                <div class="text-muted small">{{ $a->user?->email }}</div>
              </td>
              <td>
                <div>{{ $a->check_in ?? '-' }}</div>
                @if ($a->check_in_photo_path)
                  <a class="small" href="{{ \Illuminate\Support\Facades\Storage::url($a->check_in_photo_path) }}" target="_blank">photo</a>
                @endif
              </td>
              <td>
                <div>{{ $a->check_out ?? '-' }}</div>
                @if ($a->check_out_photo_path)
                  <a class="small" href="{{ \Illuminate\Support\Facades\Storage::url($a->check_out_photo_path) }}" target="_blank">photo</a>
                @endif
              </td>
              <td>{{ $a->work_mode ?? '-' }}</td>
              <td>
                <div class="small text-muted">in: {{ $a->location_status_in ?? '-' }}</div>
                <div class="small text-muted">out: {{ $a->location_status_out ?? '-' }}</div>
              </td>
              <td>
                <div class="small">in: {{ $a->check_in_verified ? 'yes' : 'no' }}</div>
                <div class="small">out: {{ $a->check_out_verified ? 'yes' : 'no' }}</div>
              </td>
            </tr>
          @endforeach
        </tbody>
      </table>
    </div>
  </div>

  <div class="text-muted small mt-2">Menampilkan max 500 presensi.</div>
@endsection

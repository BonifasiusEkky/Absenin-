@extends('hrd.layout')

@section('title', 'HRD Dashboard')

@section('content')
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="h4 mb-0">Dashboard</h1>
    <div class="text-muted small">Today: {{ $today }}</div>
  </div>

  <div class="row g-3 mb-4">
    <div class="col-md-4">
      <div class="card">
        <div class="card-body">
          <div class="text-muted">Employees</div>
          <div class="fs-4 fw-semibold">{{ $stats['employees_total'] }}</div>
          <div class="text-muted small">Active: {{ $stats['employees_active'] }}</div>
        </div>
      </div>
    </div>
    <div class="col-md-4">
      <div class="card">
        <div class="card-body">
          <div class="text-muted">Leaves pending</div>
          <div class="fs-4 fw-semibold">{{ $stats['leaves_pending'] }}</div>
        </div>
      </div>
    </div>
    <div class="col-md-4">
      <div class="card">
        <div class="card-body">
          <div class="text-muted">Attendances today</div>
          <div class="fs-4 fw-semibold">{{ $stats['attendances_today'] }}</div>
          <div class="text-muted small">Check-in: {{ $stats['checkin_today'] }} | Check-out: {{ $stats['checkout_today'] }}</div>
        </div>
      </div>
    </div>
  </div>

  <div class="card">
    <div class="card-body">
      <div class="d-flex justify-content-between align-items-center">
        <h2 class="h6 mb-0">Office settings</h2>
        <a class="btn btn-sm btn-outline-primary" href="{{ route('hrd.office.edit') }}">Edit</a>
      </div>
      <hr>
      @if ($office)
        <div class="row">
          <div class="col-md-4"><div class="text-muted small">Latitude</div><div class="fw-semibold">{{ $office->office_latitude }}</div></div>
          <div class="col-md-4"><div class="text-muted small">Longitude</div><div class="fw-semibold">{{ $office->office_longitude }}</div></div>
          <div class="col-md-4"><div class="text-muted small">Radius (m)</div><div class="fw-semibold">{{ $office->radius_m }}</div></div>
        </div>
      @else
        <div class="text-muted">Belum ada office settings.</div>
      @endif
    </div>
  </div>
@endsection

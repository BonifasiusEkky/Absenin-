@extends('hrd.layout')

@section('title', 'Leaves')

@section('content')
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="h4 mb-0">Leaves</h1>
  </div>

  <form class="card card-body mb-3" method="GET" action="{{ route('hrd.leaves.index') }}">
    <div class="row g-2 align-items-end">
      <div class="col-md-3">
        <label class="form-label">Status</label>
        <select class="form-select" name="status">
          <option value="" {{ $filters['status']==='' ? 'selected' : '' }}>All</option>
          <option value="pending" {{ $filters['status']==='pending' ? 'selected' : '' }}>pending</option>
          <option value="approved" {{ $filters['status']==='approved' ? 'selected' : '' }}>approved</option>
          <option value="rejected" {{ $filters['status']==='rejected' ? 'selected' : '' }}>rejected</option>
        </select>
      </div>
      <div class="col-md-6">
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
      <div class="col-md-3">
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
            <th>User</th>
            <th>Type</th>
            <th>Period</th>
            <th>Status</th>
            <th>Attachment</th>
            <th style="width: 340px;">Action</th>
          </tr>
        </thead>
        <tbody>
          @foreach ($leaves as $l)
            <tr>
              <td>{{ $l->id }}</td>
              <td>
                <div class="fw-semibold">{{ $l->user?->name ?? ('#'.$l->user_id) }}</div>
                <div class="text-muted small">{{ $l->user?->email }}</div>
              </td>
              <td>{{ $l->type }}</td>
              <td>{{ $l->start_date }} → {{ $l->end_date }}</td>
              <td>
                @php
                  $badge = 'secondary';
                  if ($l->status === 'pending') $badge = 'warning';
                  if ($l->status === 'approved') $badge = 'success';
                  if ($l->status === 'rejected') $badge = 'danger';
                @endphp
                <span class="badge text-bg-{{ $badge }}">{{ $l->status }}</span>
              </td>
              <td>
                @if ($l->attachment_path)
                  <a href="{{ \Illuminate\Support\Facades\Storage::url($l->attachment_path) }}" target="_blank">View</a>
                @else
                  <span class="text-muted">-</span>
                @endif
              </td>
              <td>
                @if ($l->status === 'pending')
                  <form class="d-flex gap-2" method="POST" action="{{ route('hrd.leaves.decide', $l->id) }}">
                    @csrf
                    <input type="text" class="form-control form-control-sm" name="decision_note" placeholder="catatan (optional)">
                    <button class="btn btn-sm btn-success" name="status" value="approved" type="submit">Approve</button>
                    <button class="btn btn-sm btn-danger" name="status" value="rejected" type="submit">Reject</button>
                  </form>
                @else
                  <div class="text-muted small">
                    decided_at: {{ $l->decided_at ?? '-' }}
                    @if ($l->decision_note)
                      <div>note: {{ $l->decision_note }}</div>
                    @endif
                  </div>
                @endif
              </td>
            </tr>
          @endforeach
        </tbody>
      </table>
    </div>
  </div>

  <div class="text-muted small mt-2">Menampilkan max 500 cuti.</div>
@endsection

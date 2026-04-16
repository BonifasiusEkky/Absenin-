@extends('hrd.layout')

@section('title', 'Enroll Face')

@section('content')
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="h4 mb-0">Enroll Face</h1>
  </div>

  <div class="row g-3">
    <div class="col-lg-6">
      <div class="card">
        <div class="card-body">
          <form method="GET" action="{{ route('hrd.faces.create') }}" class="mb-3">
            <label class="form-label">Select user</label>
            <div class="d-flex gap-2">
              <select class="form-select" name="user_id" required>
                <option value="">-- pilih user --</option>
                @foreach ($users as $u)
                  <option value="{{ $u->id }}" {{ (string)$selectedUserId === (string)$u->id ? 'selected' : '' }}>
                    #{{ $u->id }} — {{ $u->name }} ({{ $u->email }}) [{{ $u->role }}{{ $u->is_active ? '' : ', inactive' }}]
                  </option>
                @endforeach
              </select>
              <button class="btn btn-outline-primary" type="submit">Load</button>
            </div>
          </form>

          <form method="POST" action="{{ route('hrd.faces.store') }}" enctype="multipart/form-data">
            @csrf
            <input type="hidden" name="user_id" value="{{ $selectedUserId }}">

            <div class="mb-3">
              <label class="form-label">Photo (jpg/png, max 5MB)</label>
              <input class="form-control" type="file" name="image" accept="image/png,image/jpeg" required>
            </div>

            <div class="form-check mb-3">
              <input class="form-check-input" type="checkbox" name="is_primary" value="1" checked>
              <label class="form-check-label">Set as primary</label>
            </div>

            <button class="btn btn-primary" type="submit" {{ !$selectedUserId ? 'disabled' : '' }}>Enroll</button>
          </form>
        </div>
      </div>
    </div>

    <div class="col-lg-6">
      <div class="card">
        <div class="card-body">
          <h2 class="h6">Existing faces</h2>
          @if (!$selectedUserId)
            <div class="text-muted">Pilih user dulu.</div>
          @elseif (!$faces || $faces->isEmpty())
            <div class="text-muted">Belum ada face untuk user ini.</div>
          @else
            <div class="row g-2">
              @foreach ($faces as $f)
                <div class="col-6">
                  <div class="border rounded p-2 bg-white">
                    <div class="small text-muted">#{{ $f->id }} {{ $f->is_primary ? '(primary)' : '' }}</div>
                    <a href="{{ \Illuminate\Support\Facades\Storage::url($f->image_path) }}" target="_blank">
                      <img src="{{ \Illuminate\Support\Facades\Storage::url($f->image_path) }}" class="img-fluid rounded" alt="face">
                    </a>
                    <div class="small text-muted mt-1">model: {{ $f->embedding_model }}</div>
                  </div>
                </div>
              @endforeach
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>
@endsection

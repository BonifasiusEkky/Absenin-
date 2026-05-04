@extends('hrd.layout')

@section('title', 'Users')

@section('content')
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="h4 mb-0">Users</h1>
    <a class="btn btn-primary" href="{{ route('hrd.users.create') }}">Create User</a>
  </div>

  <form class="card card-body mb-3" method="GET" action="{{ route('hrd.users.index') }}">
    <div class="row g-2 align-items-end">
      <div class="col-md-5">
        <label class="form-label">Search</label>
        <input class="form-control" name="q" value="{{ $filters['q'] }}" placeholder="name / email">
      </div>
      <div class="col-md-3">
        <label class="form-label">Role</label>
        <select class="form-select" name="role">
          <option value="" {{ $filters['role']==='' ? 'selected' : '' }}>All</option>
          <option value="employee" {{ $filters['role']==='employee' ? 'selected' : '' }}>employee</option>
          <option value="hrd" {{ $filters['role']==='hrd' ? 'selected' : '' }}>hrd</option>
        </select>
      </div>
      <div class="col-md-2">
        <label class="form-label">Active</label>
        <select class="form-select" name="active">
          <option value="" {{ $filters['active']==='' ? 'selected' : '' }}>All</option>
          <option value="1" {{ $filters['active']==='1' ? 'selected' : '' }}>Active</option>
          <option value="0" {{ $filters['active']==='0' ? 'selected' : '' }}>Inactive</option>
        </select>
      </div>
      <div class="col-md-2">
        <button class="btn btn-outline-primary w-100" type="submit">Filter</button>
      </div>
    </div>
  </form>

  <div class="card">
    <div class="table-responsive">
      <table class="table table-striped table-hover mb-0">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Work mode</th>
            <th>Active</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          @foreach ($users as $u)
            <tr>
              <td>{{ $u->id }}</td>
              <td>{{ $u->name }}</td>
              <td>{{ $u->email }}</td>
              <td><span class="badge text-bg-secondary">{{ $u->role }}</span></td>
              <td>{{ $u->work_mode }}</td>
              <td>
                @if ($u->is_active)
                  <span class="badge text-bg-success">active</span>
                @else
                  <span class="badge text-bg-danger">inactive</span>
                @endif
              </td>
              <td class="text-end">
                <a class="btn btn-sm btn-outline-primary" href="{{ route('hrd.users.edit', $u->id) }}">Edit</a>
              </td>
            </tr>
          @endforeach
        </tbody>
      </table>
    </div>
  </div>

  <div class="text-muted small mt-2">Menampilkan max 500 user.</div>
@endsection

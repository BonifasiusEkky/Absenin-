@extends('hrd.layout')

@section('title', 'Create User')

@section('content')
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="h4 mb-0">Create User</h1>
    <a class="btn btn-outline-secondary" href="{{ route('hrd.users.index') }}">Back</a>
  </div>

  <div class="card">
    <div class="card-body">
      <form method="POST" action="{{ route('hrd.users.store') }}">
        @csrf
        <div class="row g-3">
          <div class="col-md-6">
            <label class="form-label">Name</label>
            <input class="form-control" name="name" value="{{ old('name') }}" required>
          </div>
          <div class="col-md-6">
            <label class="form-label">Email</label>
            <input class="form-control" type="email" name="email" value="{{ old('email') }}" required>
          </div>
          <div class="col-md-6">
            <label class="form-label">Password</label>
            <input class="form-control" type="password" name="password" required>
          </div>
          <div class="col-md-3">
            <label class="form-label">Role</label>
            <select class="form-select" name="role" required>
              <option value="employee" {{ old('role')==='employee' ? 'selected' : '' }}>employee</option>
              <option value="hrd" {{ old('role')==='hrd' ? 'selected' : '' }}>hrd</option>
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label">Work mode</label>
            <select class="form-select" name="work_mode" required>
              <option value="wfo" {{ old('work_mode','wfo')==='wfo' ? 'selected' : '' }}>wfo</option>
              <option value="wfh" {{ old('work_mode')==='wfh' ? 'selected' : '' }}>wfh</option>
            </select>
          </div>
          <div class="col-md-12">
            <label class="form-label">Job title</label>
            <input class="form-control" name="job_title" value="{{ old('job_title') }}">
          </div>
          <div class="col-md-12">
            <div class="form-check">
              <input class="form-check-input" type="checkbox" name="is_active" value="1" {{ old('is_active', '1') ? 'checked' : '' }}>
              <label class="form-check-label">Active</label>
            </div>
          </div>
        </div>

        <div class="mt-3">
          <button class="btn btn-primary" type="submit">Create</button>
        </div>
      </form>
    </div>
  </div>
@endsection

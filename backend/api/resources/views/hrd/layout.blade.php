<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>@yield('title', 'HRD Admin')</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
</head>
<body class="bg-light">

<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
  <div class="container-fluid">
    <a class="navbar-brand" href="{{ route('hrd.dashboard') }}">HRD Admin</a>

    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarHrd" aria-controls="navbarHrd" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbarHrd">
      <ul class="navbar-nav me-auto mb-2 mb-lg-0">
        <li class="nav-item"><a class="nav-link {{ request()->routeIs('hrd.dashboard') ? 'active' : '' }}" href="{{ route('hrd.dashboard') }}">Dashboard</a></li>
        <li class="nav-item"><a class="nav-link {{ request()->routeIs('hrd.users.*') ? 'active' : '' }}" href="{{ route('hrd.users.index') }}">Users</a></li>
        <li class="nav-item"><a class="nav-link {{ request()->routeIs('hrd.leaves.*') ? 'active' : '' }}" href="{{ route('hrd.leaves.index') }}">Leaves</a></li>
        <li class="nav-item"><a class="nav-link {{ request()->routeIs('hrd.attendances.*') ? 'active' : '' }}" href="{{ route('hrd.attendances.index') }}">Attendances</a></li>
        <li class="nav-item"><a class="nav-link {{ request()->routeIs('hrd.office.*') ? 'active' : '' }}" href="{{ route('hrd.office.edit') }}">Office</a></li>
        <li class="nav-item"><a class="nav-link {{ request()->routeIs('hrd.faces.*') ? 'active' : '' }}" href="{{ route('hrd.faces.create') }}">Faces</a></li>
        <li class="nav-item"><a class="nav-link {{ request()->routeIs('hrd.holidays.*') ? 'active' : '' }}" href="{{ route('hrd.holidays.index') }}">Holidays</a></li>
      </ul>

      <div class="d-flex align-items-center gap-3">
        <div class="text-white small">
          {{ auth()->user()->name ?? 'HRD' }}
        </div>
        <form method="POST" action="{{ route('hrd.logout') }}">
          @csrf
          <button class="btn btn-outline-light btn-sm" type="submit">Logout</button>
        </form>
      </div>
    </div>
  </div>
</nav>

<main class="container py-4">
  @if (session('success'))
    <div class="alert alert-success">{{ session('success') }}</div>
  @endif
  @if (session('error'))
    <div class="alert alert-danger">{{ session('error') }}</div>
  @endif
  @if ($errors->any())
    <div class="alert alert-danger">
      <div class="fw-semibold mb-2">Validasi gagal:</div>
      <ul class="mb-0">
        @foreach ($errors->all() as $err)
          <li>{{ $err }}</li>
        @endforeach
      </ul>
    </div>
  @endif

  @yield('content')
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</body>
</html>

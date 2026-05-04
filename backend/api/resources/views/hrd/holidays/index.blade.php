@extends('hrd.layout')

@section('title', 'Kalender Hari Libur')

@section('content')
<div class="row">
    <div class="col-md-4">
        <div class="card shadow-sm mb-4">
            <div class="card-header bg-white">
                <h5 class="mb-0">Tambah Hari Libur</h5>
            </div>
            <div class="card-body">
                <form action="{{ route('hrd.holidays.store') }}" method="POST">
                    @csrf
                    <div class="mb-3">
                        <label for="date" class="form-label">Tanggal</label>
                        <input type="date" name="date" id="date" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label for="name" class="form-label">Nama Libur</label>
                        <input type="text" name="name" id="name" class="form-control" placeholder="Contoh: Idul Fitri" required>
                    </div>
                    <div class="mb-3 form-check">
                        <input type="checkbox" name="is_mass_leave" id="is_mass_leave" class="form-check-input" value="1">
                        <label class="form-check-label" for="is_mass_leave">Cuti Bersama</label>
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Simpan</button>
                </form>
            </div>
        </div>
    </div>

    <div class="col-md-8">
        <div class="card shadow-sm">
            <div class="card-header bg-white d-flex justify-content-between align-items-center">
                <h5 class="mb-0">Daftar Hari Libur</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Tanggal</th>
                                <th>Nama</th>
                                <th>Jenis</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($holidays as $holiday)
                                <tr>
                                    <td>{{ $holiday->date->format('d M Y') }}</td>
                                    <td>{{ $holiday->name }}</td>
                                    <td>
                                        @if ($holiday->is_mass_leave)
                                            <span class="badge bg-warning text-dark">Cuti Bersama</span>
                                        @else
                                            <span class="badge bg-danger">Libur Nasional</span>
                                        @endif
                                    </td>
                                    <td>
                                        <form action="{{ route('hrd.holidays.destroy', $holiday->id) }}" method="POST" onsubmit="return confirm('Hapus hari libur ini?')">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="btn btn-sm btn-outline-danger">Hapus</button>
                                        </form>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="4" class="text-center py-4 text-muted">Belum ada hari libur yang diatur.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

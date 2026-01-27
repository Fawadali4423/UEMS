<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function stats()
    {
        return response()->json([
            'total_students' => \App\Models\User::count(),
            'total_events' => \App\Models\Event::count(),
            'certificates_generated' => \App\Models\GeneratedCertificate::count(),
        ]);
    }
}

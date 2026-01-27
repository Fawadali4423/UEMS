<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class StudentController extends Controller
{
    public function myCertificates(Request $request)
    {
        // Assuming the user is authenticated via Firebase middleware and their UID is available.
        // For now, we'll try to get user from request or auth.
        // NOTE: The route uses firebase.auth middleware.

        $user = $request->user();

        if (!$user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $certificates = \App\Models\GeneratedCertificate::where('student_id', $user->id)
            ->with('event')
            ->get();

        return response()->json($certificates);
    }
}

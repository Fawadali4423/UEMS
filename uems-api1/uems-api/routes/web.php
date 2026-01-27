<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Response;

Route::get('/', function () {
    return view('welcome');
});

// --- FALLBACK IMAGE SERVER (The Magic Fix) ---
// If the "storage" link is broken, this route will serve the image directly via PHP.
Route::get('/storage/certificates/{filename}', function ($filename) {
    $path = storage_path('app/public/certificates/' . $filename);

    if (!file_exists($path)) {
        abort(404, 'File not found on server storage.');
    }

    $file = \Illuminate\Support\Facades\File::get($path);
    $type = \Illuminate\Support\Facades\File::mimeType($path);

    $response = Response::make($file, 200);
    $response->header("Content-Type", $type);

    return $response;
});

// --- SYSTEM FIXER ---
Route::get('/fix-system', function () {
    // 1. Clear Caches (Fixes route issues)
    Artisan::call('optimize:clear');

    // 2. Fix Storage Link
    $target = storage_path('app/public');
    $link = public_path('storage');

    // Attempt to delete existing link first
    if (file_exists($link) || is_link($link)) {
        @unlink($link);
    }

    // Create fresh link
    try {
        symlink($target, $link);
        $linkStatus = "Link Fixed Successfully";
    } catch (\Exception $e) {
        // Try artisan if manual fails
        try {
            Artisan::call('storage:link');
            $linkStatus = "Link Fixed via Artisan";
        } catch (\Exception $e2) {
            $linkStatus = "Link Creation Failed (But Fallback Route should work!)";
        }
    }

    return "<h1>System Updated</h1>
            <p>Cache Cleared: YES</p>
            <p>Storage Link Status: $linkStatus</p>
            <p><b>Fallback Route Active: YES</b></p>
            <p>You can now open your app. The images should work.</p>";
});

<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CertificateController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\AdminController;

// 📤 Public Certificate Upload Route (No Authentication Required)
Route::post('/certificates/upload', [CertificateController::class, 'upload']);

Route::middleware('firebase.auth')->group(function () {


    // 🔐 Admin Routes
    Route::post('/admin/events/{id}/certificate-template', [CertificateController::class, 'uploadTemplate']);
    Route::get('/admin/events', [EventController::class, 'index']);
    Route::get('/admin/certificates/stats', [AdminController::class, 'stats']);

    // 📅 Event Management
    Route::post('/events', [EventController::class, 'store']);
    Route::delete('/events/{id}', [EventController::class, 'destroy']);
    Route::post('/events/check-conflicts', [EventController::class, 'checkConflicts']);

    // 👨‍🎓 Student Routes
    Route::get('/student/certificates', [StudentController::class, 'myCertificates']);
    Route::post('/student/events/{id}/generate-certificate', [CertificateController::class, 'generate']);
    // Compat route for frontend service
    Route::post('/certificates/generate', [CertificateController::class, 'generateFromPayload']);
});

// 🔍 Public Verification Route
Route::get('/certificates/verify/{id}', [CertificateController::class, 'verify']);

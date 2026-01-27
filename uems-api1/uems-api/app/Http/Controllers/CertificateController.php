<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class CertificateController extends Controller
{
    /**
     * Upload certificate image
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function upload(Request $request)
    {
        // Validate the incoming request
        $validated = $request->validate([
            'certificate' => 'required|image|mimes:jpeg,png,jpg,gif|max:5120', // Max 5MB
            'eventId' => 'required|string|max:255',
        ]);

        try {
            // Get the uploaded file
            $file = $request->file('certificate');
            $eventId = $request->input('eventId');

            // Generate unique filename using event ID and timestamp
            $timestamp = now()->format('YmdHis');
            $extension = $file->getClientOriginalExtension();
            $filename = "certificate_{$eventId}_{$timestamp}.{$extension}";

            // Store the file in storage/app/public/certificates/
            $path = $file->storeAs('certificates', $filename, 'public');

            // Handle Template Config
            $config = $request->input('templateConfig');
            if ($config) {
                // Save config as JSON file
                $configPath = 'certificates/' . pathinfo($filename, PATHINFO_FILENAME) . '.json';
                \Illuminate\Support\Facades\Storage::disk('public')->put($configPath, $config);

                // Update CertificateTemplate linkage
                \App\Models\CertificateTemplate::updateOrCreate(
                    ['event_id' => $eventId],
                    ['template_path' => $path]
                );
            }

            // Generate the publicly accessible URL
            $imageUrl = url('storage/' . $path);

            // Return JSON response
            return response()->json([
                'success' => true,
                'message' => 'Certificate uploaded successfully',
                'data' => [
                    'imageUrl' => $imageUrl,
                    'filename' => $filename,
                    'path' => $path,
                ]
            ], 201);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Upload failed: ' . $e->getMessage());
            \Illuminate\Support\Facades\Log::error($e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Failed to upload certificate',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Upload certificate template
     */
    public function uploadTemplate(Request $request, $id)
    {
        // ... (Keep existing if needed, but 'upload' now handles it) ...
        return response()->json(['message' => 'Use /upload endpoint']);
    }

    /**
     * Generate certificate for a student
     */
    public function generate(Request $request, $id)
    {
        // $id is event id
        $user = $request->user();
        if (!$user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $event = \App\Models\Event::findOrFail($id);

        // check if already generated
        $existing = \App\Models\GeneratedCertificate::where('event_id', $event->id)
            ->where('student_id', $user->id)
            ->first();

        /* 
        // Force regeneration for testing if needed, or uncomment check above
        if ($existing) {
             return response()->json(['success' => true, 'certificate' => $existing, 'message' => 'Already generated']);
        }
        */

        // Real PDF Generation using DomPDF
        $certUid = uniqid('CERT-');
        $filename = "certificate_{$certUid}.pdf";
        $path = "certificates/generated/{$filename}";

        $rollNumber = $request->input('rollNumber', $user->roll_number ?? '');

        // Check for Custom Template
        $template = \App\Models\CertificateTemplate::where('event_id', $event->id)->first();
        $templateImage = null;
        $templateConfig = null;

        if ($template) {
            $templateImage = storage_path('app/public/' . $template->template_path); // local path for DomPDF

            // Check for config JSON
            $configPath = str_replace(
                '.' . pathinfo($template->template_path, PATHINFO_EXTENSION),
                '.json',
                $template->template_path
            );

            if (\Illuminate\Support\Facades\Storage::disk('public')->exists($configPath)) {
                $jsonContent = \Illuminate\Support\Facades\Storage::disk('public')->get($configPath);
                $templateConfig = json_decode($jsonContent, true);
            }
        }

        // Render PDF view
        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('certificates.certificate', [
            'student' => $user,
            'event' => $event,
            'cert_uid' => $certUid,
            'rollNumber' => $rollNumber,
            'templateImage' => $templateImage, // Pass full path for DomPDF
            'templateConfig' => $templateConfig
        ]);

        // Customize paper size if template is typically landscape A4
        $pdf->setPaper('a4', 'landscape');

        // Save to storage (public disk)
        \Illuminate\Support\Facades\Storage::disk('public')->put($path, $pdf->output());

        $cert = \App\Models\GeneratedCertificate::create([
            'student_id' => $user->id,
            'event_id' => $event->id,
            'cert_uid' => $certUid,
            'certificate_path' => $path,
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'certificateId' => $cert->cert_uid,
                'pdfUrl' => url('storage/' . $path),
                'generatedAt' => $cert->created_at,
                'certificate' => $cert,
                'download_url' => url('storage/' . $path)
            ]
        ]);
    }
    /**
     * Verify certificate validity
     */
    public function verify($id)
    {
        // $id is the certificate UID (e.g. CERT-...)
        $cert = \App\Models\GeneratedCertificate::where('cert_uid', $id)->first();

        if ($cert) {
            $student = \App\Models\User::find($cert->student_id);
            $event = \App\Models\Event::find($cert->event_id);

            return response()->json([
                'success' => true,
                'valid' => true,
                'data' => [
                    'studentName' => $student ? $student->name : 'Unknown Student',
                    'eventName' => $event ? $event->title : 'Unknown Event',
                    'issueDate' => $cert->created_at->format('Y-m-d'),
                    'certificateUid' => $cert->cert_uid,
                    'downloadUrl' => url('storage/' . $cert->certificate_path)
                ]
            ]);
        }

        return response()->json([
            'success' => true,
            'valid' => false,
            'message' => 'Certificate not found'
        ]);
    }
    /**
     * Generate certificate (compat mode for Service)
     */
    public function generateFromPayload(Request $request)
    {
        $request->validate([
            'eventId' => 'required|string'
        ]);

        return $this->generate($request, $request->input('eventId'));
    }
}

<?php
// Test script for certificate upload endpoint

$url = 'http://localhost/uems-api/public/api/certificates/upload';
$imagePath = 'C:\Users\User\.gemini\antigravity\brain\5f0a50d0-40da-43a0-9392-ae0c2f551b03\test_certificate_1768654409641.png';

if (!file_exists($imagePath)) {
    die("Error: Image file not found at: $imagePath\n");
}

$cfile = new CURLFile($imagePath, 'image/png', 'test_certificate.png');

$data = [
    'certificate' => $cfile,
    'eventId' => 'test_event_123'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json'
]);

echo "Testing certificate upload endpoint...\n";
echo "URL: $url\n";
echo "Event ID: test_event_123\n\n";

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

if (curl_errno($ch)) {
    echo "cURL Error: " . curl_error($ch) . "\n";
} else {
    echo "HTTP Status Code: $httpCode\n";
    echo "Response:\n";
    echo json_encode(json_decode($response), JSON_PRETTY_PRINT) . "\n";
}

curl_close($ch);

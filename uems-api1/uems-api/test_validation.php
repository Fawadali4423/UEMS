<?php
// Test validation errors with proper headers

$url = 'http://localhost/uems-api/public/api/certificates/upload';

echo "=== Testing Validation Errors (with JSON Accept header) ===\n\n";

// Test 1: Missing certificate file
echo "Test 1: Missing certificate file\n";
echo "Request: Only eventId, no certificate\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, ['eventId' => 'test123']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Accept: application/json']);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "HTTP Status Code: $httpCode\n";
echo "Response:\n" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "\n\n";
curl_close($ch);

// Test 2: Missing eventId
echo "Test 2: Missing eventId\n";
echo "Request: Only certificate, no eventId\n";
$imagePath = 'C:\Users\User\.gemini\antigravity\brain\5f0a50d0-40da-43a0-9392-ae0c2f551b03\test_certificate_1768654409641.png';
$cfile = new CURLFile($imagePath, 'image/png', 'test.png');
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, ['certificate' => $cfile]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Accept: application/json']);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "HTTP Status Code: $httpCode\n";
echo "Response:\n" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "\n\n";
curl_close($ch);

echo "=== All validation tests completed ===\n";

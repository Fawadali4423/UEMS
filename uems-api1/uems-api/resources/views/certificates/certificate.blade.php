<!DOCTYPE html>
<html>

<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Certificate of Completion</title>
    <style>
        body {
            font-family: 'Helvetica', sans-serif;
            text-align: center;
            border: 10px solid #787878;
            padding: 50px;
            height: 90vh;
            /* Approximate A4 height */
        }

        .header {
            font-size: 50px;
            font-weight: bold;
            color: #333;
            margin-bottom: 20px;
        }

        .sub-header {
            font-size: 25px;
            color: #555;
            margin-bottom: 40px;
        }

        .student-name {
            font-size: 40px;
            font-weight: bold;
            color: #000;
            text-decoration: underline;
            margin-bottom: 20px;
        }

        .content {
            font-size: 20px;
            color: #666;
            margin-bottom: 30px;
            line-height: 1.5;
        }

        .event-name {
            font-weight: bold;
            color: #222;
        }

        .date {
            font-size: 18px;
            color: #777;
            margin-top: 40px;
        }

        .signature {
            margin-top: 60px;
            border-top: 2px solid #333;
            display: inline-block;
            width: 200px;
            padding-top: 10px;
        }

        .footer {
            margin-top: 50px;
            font-size: 12px;
            color: #999;
        }
    </style>
</head>

@if(isset($templateImage) && $templateImage)
    <style>
        body {
            /* Reset default styles for custom template */
            font-family: 'Helvetica', sans-serif;
            margin: 0;
            padding: 0;
            border: none;
            width: 100%;
            height: 100%;
        }

        .page-container {
            position: relative;
            width: 100%;
            height: 100vh;
            /* Viewport height for PDF */
        }

        .bg-image {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: -1;
        }

        .dynamic-text {
            position: absolute;
            transform: translate(-50%, -50%);
            /* Center the text around the point if desired, but user drags top-left. Let's stick to Top-Left for consistency with Editor? No, Editor Positioned uses top/left directly. */
            /* Actually, if user drags Top-Left of box to coordinate, then we should use Top-Left. */
            /* Flutter Editor: Positioned(left: x*w, top:y*h). So Top-Left anchor. */
            white-space: nowrap;
        }

        /* Override transform for specific logic if needed */
    </style>

    <body>
        <div class="page-container">
            <img src="{{ $templateImage }}" class="bg-image" />

            @if(isset($templateConfig))
                @if(isset($templateConfig['studentName']))
                    <div class="dynamic-text" style="
                                    left: {{ $templateConfig['studentName']['x'] * 100 }}%; 
                                    top: {{ $templateConfig['studentName']['y'] * 100 }}%; 
                                    font-size: {{ $templateConfig['studentName']['fontSize'] ?? 24 }}px;
                                    color: {{ $templateConfig['studentName']['color'] ?? '#000000' }};
                                    font-weight: bold;
                                ">
                        {{ $student->name }}
                    </div>
                @endif

                @if(isset($templateConfig['rollNumber']) && !empty($rollNumber))
                    <div class="dynamic-text" style="
                                    left: {{ $templateConfig['rollNumber']['x'] * 100 }}%; 
                                    top: {{ $templateConfig['rollNumber']['y'] * 100 }}%; 
                                    font-size: {{ $templateConfig['rollNumber']['fontSize'] ?? 18 }}px;
                                    color: {{ $templateConfig['rollNumber']['color'] ?? '#000000' }};
                                ">
                        {{ $rollNumber }}
                    </div>
                @endif
            @endif
        </div>

        <div style="position: absolute; bottom: 20px; right: 20px; font-size: 10px; color: #555;">
            Certificate ID: {{ $cert_uid }}
        </div>
    </body>
@else

    <body>
        <div class="header">Certificate of Completion</div>

        <div class="sub-header">This is to certify that</div>

        <div class="student-name">{{ $student->name }}</div>

        @if(!empty($rollNumber))
            <div style="font-size: 20px; color: #555; margin-top: -15px; margin-bottom: 20px;">({{ $rollNumber }})</div>
        @endif

        <div class="content">
            has successfully attended and completed the event <br>
            <span class="event-name">{{ $event->title }}</span>
        </div>

        <div class="date">Date: {{ \Carbon\Carbon::parse($event->date)->format('F d, Y') }}</div>

        <div class="signature">Organizer</div>

        <div class="footer">
            <b>Certificate ID:</b> {{ $cert_uid }}
        </div>
    </body>
@endif

</html>
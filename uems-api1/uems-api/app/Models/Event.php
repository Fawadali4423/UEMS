<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    protected $fillable = [
        'title',
        'date',
        'organizer',
        'description',
        'start_time',
        'end_time',
        'venue',
        'organizer_id',
        'organizer_name',
        'status',
        'event_type',
        'entry_fee',
        'poster_base64',
        'certificate_template_base64',
        'template_config',
        'participant_count'
    ];

    protected $casts = [
        'template_config' => 'array',
    ];

    public function template()
    {
        return $this->hasOne(CertificateTemplate::class);
    }

    public function attendance()
    {
        return $this->hasMany(EventAttendance::class);
    }

    public function generatedCertificates()
    {
        return $this->hasMany(GeneratedCertificate::class);
    }
}

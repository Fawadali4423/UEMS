<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GeneratedCertificate extends Model
{
    protected $fillable = ['student_id', 'event_id', 'cert_uid', 'certificate_path', 'downloads'];

    public function event()
    {
        return $this->belongsTo(Event::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }
}

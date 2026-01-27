<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CertificateTemplate extends Model
{
    protected $fillable = ['event_id', 'template_path'];

    public function event()
    {
        return $this->belongsTo(Event::class);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EventAttendance extends Model
{
    protected $table = 'event_attendance';
    protected $fillable = ['event_id', 'student_id', 'attended'];

    public function event()
    {
        return $this->belongsTo(Event::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'student_id');
    }
}

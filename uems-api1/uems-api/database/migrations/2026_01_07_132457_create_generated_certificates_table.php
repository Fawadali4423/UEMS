<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('generated_certificates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('event_id')->constrained()->onDelete('cascade');
            $table->string('cert_uid')->unique();
            $table->string('certificate_path');
            $table->integer('downloads')->default(0);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('generated_certificates');
    }
};

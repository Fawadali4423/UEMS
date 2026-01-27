<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('events', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->date('date');
            $table->string('start_time');
            $table->string('end_time');
            $table->string('venue');
            $table->string('organizer_id')->nullable();
            $table->string('organizer_name')->nullable();
            $table->string('organizer')->nullable(); // Keeping for backward compatibility if needed, though organizer_name is better
            $table->string('status')->default('pending');
            $table->string('event_type')->default('free');
            $table->decimal('entry_fee', 10, 2)->nullable();
            $table->longText('poster_base64')->nullable(); // Using longText for Base64 strings
            $table->longText('certificate_template_base64')->nullable();
            $table->text('template_config')->nullable(); // JSON Coordinates for dynamic text
            $table->integer('participant_count')->default(0);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('events');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('livraison_refus', function (Blueprint $table) {
            $table->id();
            $table->foreignId('livraison_id')->constrained()->cascadeOnDelete();
            $table->foreignId('transporteur_id')->constrained('users')->cascadeOnDelete();
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['livraison_id', 'transporteur_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('livraison_refus');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('livraisons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('commande_id')->constrained()->cascadeOnDelete();
            $table->foreignId('transporteur_id')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('statut', [
                'en_attente',
                'en_cours',
                'livree',
                'proposee',
                'annulee',
            ])->default('en_attente');
            $table->decimal('latitude_actuelle', 10, 7)->nullable();
            $table->decimal('longitude_actuelle', 10, 7)->nullable();
            $table->timestamp('date_livraison_prevue')->nullable();
            $table->timestamp('date_livraison_reelle')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('livraisons');
    }
};

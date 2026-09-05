<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('paiements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            // Type de paiement : commande (achat) ou abonnement premium
            $table->enum('type', ['commande', 'abonnement'])->default('commande');

            // Lié à une commande si type = commande (nullable sinon)
            $table->foreignId('commande_id')->nullable()->constrained('commandes')->nullOnDelete();

            $table->decimal('montant', 10, 2);
            $table->string('methode')->nullable(); // mobile money, carte, etc.
            $table->enum('statut', ['en_attente', 'reussi', 'echoue'])->default('en_attente');
            $table->string('reference_api')->nullable(); // référence retournée par l'API de paiement
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('paiements');
    }
};

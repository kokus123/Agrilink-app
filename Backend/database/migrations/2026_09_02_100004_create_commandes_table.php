<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('commandes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('acheteur_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('montant_total', 10, 2)->default(0);
            $table->enum('statut', [
                'en_attente',
                'confirmee',
                'en_livraison',
                'livree',
                'annulee',
            ])->default('en_attente');
            $table->timestamps();
        });

        // Table pivot commande <-> produit
        Schema::create('commande_produit', function (Blueprint $table) {
            $table->id();
            $table->foreignId('commande_id')->constrained()->cascadeOnDelete();
            $table->foreignId('produit_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('quantite');
            $table->decimal('prix_unitaire', 10, 2);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('commande_produit');
        Schema::dropIfExists('commandes');
    }
};

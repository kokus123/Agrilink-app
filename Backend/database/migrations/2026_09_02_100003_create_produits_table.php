<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('produits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('agriculteur_id')->constrained('users')->cascadeOnDelete();
            $table->string('nom');
            $table->text('description')->nullable();
            $table->string('categorie')->nullable();
            $table->decimal('prix', 10, 2);
            $table->unsignedInteger('quantite_disponible')->default(0);
            $table->string('image')->nullable();
            $table->enum('statut', ['disponible', 'rupture', 'archive'])->default('disponible');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('produits');
    }
};
